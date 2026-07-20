import Foundation

/// Thin, dependency-injectable client for OpenAI Responses and Models.
package struct OpenAIClient: Sendable {
  package let configuration: Configuration
  private let transport: any HTTPTransport

  private static let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return encoder
  }()

  private static let jsonDecoder = JSONDecoder()

  package init(configuration: Configuration, session: URLSession = .shared) {
    self.init(
      configuration: configuration,
      transport: URLSessionTransport(session: session)
    )
  }

  package init(configuration: Configuration, transport: any HTTPTransport) {
    self.configuration = configuration
    self.transport = transport
  }

  package func listModels(
    headers: [String: String] = [:]
  ) async throws -> [ModelDescriptor] {
    var request = URLRequest(url: configuration.baseURL.appending(path: "models"))
    request.httpMethod = "GET"
    applyHeaders(to: &request, extra: headers)

    let (data, response) = try await transport.data(for: request)
    try Self.check(response, body: data)
    return try Self.jsonDecoder.decode(ModelsListResponse.self, from: data).data
  }

  package func send(
    _ request: ResponseRequest,
    headers: [String: String] = [:]
  ) async throws -> ResponseObject {
    var body = request
    body.stream = false
    let (data, response) = try await transport.data(
      for: try urlRequest(for: body, headers: headers)
    )
    try Self.check(response, body: data)
    return try Self.jsonDecoder.decode(ResponseObject.self, from: data)
  }

  package func stream(
    _ request: ResponseRequest,
    headers: [String: String] = [:]
  ) -> AsyncThrowingStream<ResponseStreamEvent, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          var body = request
          body.stream = true
          let (bytes, response) = try await transport.bytes(
            for: urlRequest(for: body, headers: headers)
          )

          if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            var errorBody = Data()
            errorBody.reserveCapacity(1024)
            for try await byte in bytes {
              try Task.checkCancellation()
              errorBody.append(byte)
            }
            try Self.check(response, body: errorBody)
          }

          var sawEvent = false
          for try await event in SSEParser.events(from: bytes) {
            try Task.checkCancellation()
            sawEvent = true
            continuation.yield(event)
          }

          guard sawEvent else {
            throw APIError(
              kind: .api,
              message: "Stream ended without any decodable Responses API events."
            )
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  private func urlRequest(
    for body: ResponseRequest,
    headers: [String: String]
  ) throws -> URLRequest {
    var request = URLRequest(url: configuration.baseURL.appending(path: "responses"))
    request.httpMethod = "POST"
    applyHeaders(to: &request, extra: headers)
    request.httpBody = try Self.jsonEncoder.encode(body)
    return request
  }

  private func applyHeaders(to request: inout URLRequest, extra: [String: String]) {
    applyDefaultHeaders(to: &request)
    for (key, value) in HeaderSanitizer.sanitize(extra) {
      request.setValue(value, forHTTPHeaderField: key)
    }
    applyDefaultHeaders(to: &request)
  }

  private func applyDefaultHeaders(to request: inout URLRequest) {
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(Telemetry.userAgent, forHTTPHeaderField: "User-Agent")
    switch configuration.auth {
    case .apiKey(let key):
      request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    case .none:
      break
    }
    if let organizationID = configuration.organizationID {
      request.setValue(organizationID, forHTTPHeaderField: "OpenAI-Organization")
    }
    if let projectID = configuration.projectID {
      request.setValue(projectID, forHTTPHeaderField: "OpenAI-Project")
    }
  }

  package static func check(_ response: URLResponse, body: Data) throws {
    guard let http = response as? HTTPURLResponse, http.statusCode >= 400 else {
      return
    }
    throw APIError(statusCode: http.statusCode, body: body)
  }
}

enum Telemetry {
  static let userAgent = "OpenAIForFoundationModels/0.1.0 (Swift)"
}

import Foundation

@testable import OpenAIAPI

actor RecordingTransport: HTTPTransport {
  struct Reply: Sendable {
    var status: Int
    var body: Data

    init(status: Int = 200, body: String) {
      self.status = status
      self.body = Data(body.utf8)
    }
  }

  private let reply: Reply
  private(set) var requests: [URLRequest] = []

  init(_ reply: Reply) {
    self.reply = reply
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    requests.append(request)
    return (reply.body, response(for: request))
  }

  func bytes(
    for request: URLRequest
  ) async throws -> (AsyncThrowingStream<UInt8, Error>, URLResponse) {
    requests.append(request)
    let body = reply.body
    return (
      AsyncThrowingStream { continuation in
        for byte in body { continuation.yield(byte) }
        continuation.finish()
      },
      response(for: request)
    )
  }

  private func response(for request: URLRequest) -> HTTPURLResponse {
    HTTPURLResponse(
      url: request.url!,
      statusCode: reply.status,
      httpVersion: "HTTP/1.1",
      headerFields: nil
    )!
  }
}

func byteStream(_ text: String) -> AsyncThrowingStream<UInt8, Error> {
  let data = Data(text.utf8)
  return AsyncThrowingStream { continuation in
    for byte in data { continuation.yield(byte) }
    continuation.finish()
  }
}

import Foundation
import Testing

@testable import OpenAIAPI
@testable import OpenAIForFoundationModels

actor CatalogTransport: HTTPTransport {
  private(set) var requestCount = 0
  private let body = Data(
    """
    {
      "object": "list",
      "data": [
        {"id":"text-embedding-3-large","owned_by":"openai"},
        {"id":"gpt-4o-mini","owned_by":"openai"},
        {"id":"gpt-5-mini","owned_by":"openai"}
      ]
    }
    """.utf8
  )

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    requestCount += 1
    return (
      body,
      HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
    )
  }

  func bytes(
    for request: URLRequest
  ) async throws -> (AsyncThrowingStream<UInt8, Error>, URLResponse) {
    fatalError("Catalog tests do not stream.")
  }
}

struct CatalogTests {
  @Test("Refresh filters non-generative models, sorts IDs, and reuses its cache")
  func refreshesAndCaches() async throws {
    let transport = CatalogTransport()
    let client = OpenAIClient(
      configuration: .init(auth: .apiKey("sk-test")),
      transport: transport
    )
    let catalog = OpenAIModelCatalog(client: client, cacheTTL: 3_600)

    let first = try await catalog.refresh()
    let second = try await catalog.refresh()

    #expect(first.map(\.id) == ["gpt-4o-mini", "gpt-5-mini"])
    #expect(second == first)
    #expect(await transport.requestCount == 1)
    #expect(await catalog.models(for: .reasoning).map(\.id) == ["gpt-5-mini"])
  }

  @Test("Resolves seeded IDs and returns a conservative fallback on soft resolution")
  func resolvesModels() async throws {
    let client = OpenAIClient(configuration: .init(auth: .none))
    let catalog = OpenAIModelCatalog(client: client)
    await catalog.seed([OpenAIModel(id: "gpt-5-mini", isCatalogBacked: true)])

    let resolved = try await catalog.resolve(
      id: "gpt-5-mini",
      refreshIfNeeded: false
    )
    #expect(resolved.isCatalogBacked)

    let fallback = try await catalog.resolveIfPresent(
      id: "custom-deployment",
      refreshIfNeeded: false
    )
    #expect(fallback.id == "custom-deployment")
    #expect(fallback.isCatalogBacked == false)
  }
}

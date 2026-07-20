import Foundation

/// Normalized semantic event emitted by an OpenAI Responses API SSE stream.
package enum ResponseStreamEvent: Sendable, Hashable {
  case created(ResponseSummary)
  case outputTextDelta(String)
  case reasoningDelta(String)
  case outputItemAdded(index: Int, item: ResponseOutputItem)
  case functionCallArgumentsDelta(itemID: String?, outputIndex: Int, delta: String)
  case functionCallArgumentsDone(itemID: String?, outputIndex: Int, arguments: String)
  case completed(ResponseSummary)
  case failed(APIError)
  case ignored(type: String)
}

package struct ResponseSummary: Sendable, Hashable, Decodable {
  package var id: String?
  package var model: String?
  package var status: String?
  package var usage: ResponseUsage?
  package var error: ResponseErrorPayload?
  package var output: [ResponseOutputItem]?
}

package struct ResponseOutputItem: Sendable, Hashable, Decodable {
  package var id: String?
  package var type: String
  package var callID: String?
  package var name: String?
  package var arguments: String?
  package var content: [ResponseContent]?

  private enum CodingKeys: String, CodingKey {
    case id, type, name, arguments, content
    case callID = "call_id"
  }
}

package struct ResponseContent: Sendable, Hashable, Decodable {
  package var type: String
  package var text: String?
  package var refusal: String?
}

package struct ResponseUsage: Sendable, Hashable, Decodable {
  package var inputTokens: Int?
  package var outputTokens: Int?
  package var totalTokens: Int?
  package var inputTokensDetails: InputTokenDetails?
  package var outputTokensDetails: OutputTokenDetails?

  private enum CodingKeys: String, CodingKey {
    case inputTokens = "input_tokens"
    case outputTokens = "output_tokens"
    case totalTokens = "total_tokens"
    case inputTokensDetails = "input_tokens_details"
    case outputTokensDetails = "output_tokens_details"
  }

  package struct InputTokenDetails: Sendable, Hashable, Decodable {
    package var cachedTokens: Int?
    private enum CodingKeys: String, CodingKey {
      case cachedTokens = "cached_tokens"
    }
  }

  package struct OutputTokenDetails: Sendable, Hashable, Decodable {
    package var reasoningTokens: Int?
    private enum CodingKeys: String, CodingKey {
      case reasoningTokens = "reasoning_tokens"
    }
  }
}

package struct ResponseErrorPayload: Sendable, Hashable, Decodable {
  package var type: String?
  package var code: String?
  package var message: String
}

/// Full non-streaming Responses API object.
package struct ResponseObject: Sendable, Hashable, Decodable {
  package var id: String?
  package var model: String?
  package var status: String?
  package var output: [ResponseOutputItem]
  package var usage: ResponseUsage?
  package var error: ResponseErrorPayload?

  package var outputText: String {
    output
      .flatMap { $0.content ?? [] }
      .compactMap(\.text)
      .joined()
  }
}

// MARK: - Wire decoding

extension ResponseStreamEvent: Decodable {
  private enum CodingKeys: String, CodingKey {
    case type, delta, item, response, error, arguments
    case itemID = "item_id"
    case outputIndex = "output_index"
  }

  package init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let type = try c.decode(String.self, forKey: .type)

    switch type {
    case "response.created", "response.in_progress":
      self = .created(try c.decode(ResponseSummary.self, forKey: .response))

    case "response.output_text.delta":
      self = .outputTextDelta(try c.decode(String.self, forKey: .delta))

    case "response.reasoning_summary_text.delta", "response.reasoning_text.delta":
      self = .reasoningDelta(try c.decode(String.self, forKey: .delta))

    case "response.output_item.added":
      self = .outputItemAdded(
        index: try c.decodeIfPresent(Int.self, forKey: .outputIndex) ?? 0,
        item: try c.decode(ResponseOutputItem.self, forKey: .item)
      )

    case "response.function_call_arguments.delta":
      self = .functionCallArgumentsDelta(
        itemID: try c.decodeIfPresent(String.self, forKey: .itemID),
        outputIndex: try c.decodeIfPresent(Int.self, forKey: .outputIndex) ?? 0,
        delta: try c.decode(String.self, forKey: .delta)
      )

    case "response.function_call_arguments.done":
      self = .functionCallArgumentsDone(
        itemID: try c.decodeIfPresent(String.self, forKey: .itemID),
        outputIndex: try c.decodeIfPresent(Int.self, forKey: .outputIndex) ?? 0,
        arguments: try c.decode(String.self, forKey: .arguments)
      )

    case "response.completed":
      self = .completed(try c.decode(ResponseSummary.self, forKey: .response))

    case "response.failed", "response.incomplete":
      let response = try c.decode(ResponseSummary.self, forKey: .response)
      self = .failed(APIError(responseError: response.error, responseID: response.id))

    case "error":
      let error = try c.decode(ResponseErrorPayload.self, forKey: .error)
      self = .failed(APIError(responseError: error, responseID: nil))

    default:
      self = .ignored(type: type)
    }
  }
}

extension APIError {
  fileprivate init(responseError: ResponseErrorPayload?, responseID: String?) {
    let message = responseError?.message ?? "OpenAI response failed."
    self.init(
      kind: Self.classify(
        statusCode: 0,
        message: message,
        type: responseError?.type,
        code: responseError?.code
      ),
      message: message,
      statusCode: nil,
      metadata: responseID.map { ["response_id": $0] }
    )
  }
}

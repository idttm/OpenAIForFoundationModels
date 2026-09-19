import Foundation
import FoundationModels
import OpenAIAPI

/// Maps transport / OpenAI failures onto public error types
/// (`OpenAIError` / `LanguageModelError`). Never surfaces package-internal `APIError`.
enum ErrorMapper {
  /// Map any thrown error from the executor path into a public type.
  static func map(_ error: any Error) -> any Error {
    switch error {
    case is CancellationError:
      return error
    case is LanguageModelError:
      // Already public (e.g. unsupportedGenerationGuide from RequestBuilder).
      return error
    case let openAI as OpenAIError:
      return openAI
    case let api as APIError:
      return map(api)
    case let url as URLError:
      return map(url)
    default:
      return OpenAIError.upstream(
        message: OpenAIError.sanitize(error.localizedDescription)
      )
    }
  }

  /// Map a classified OpenAI / HTTP `APIError`.
  static func map(_ error: APIError) -> any Error {
    let detail = OpenAIError.sanitize(error.message)
    let status = error.statusCode ?? 0
    let safeDetail = detail.isEmpty ? "Request failed" : detail

    switch error.kind {
    case .rateLimit:
      return LanguageModelError.rateLimited(
        .init(resetDate: nil, debugDescription: detail)
      )

    case .contextLength:
      return LanguageModelError.contextSizeExceeded(
        .init(contextSize: 0, tokenCount: 0, debugDescription: detail)
      )

    case .refusal:
      return OpenAIError.refusal(
        message: detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
          ? "The model refused the request."
          : detail
      )

    case .incomplete:
      let reason = (error.metadata?["incomplete_reason"] ?? error.metadata?["reason"] ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
      return OpenAIError.incomplete(
        reason: reason.isEmpty ? "unknown" : OpenAIError.sanitize(reason)
      )

    case .authentication:
      return OpenAIError.missingOrInvalidCredential

    case .insufficientCredits, .paymentRequired:
      return OpenAIError.insufficientCredits

    case .notFound:
      return OpenAIError.notFound(message: detail)

    case .permission:
      return OpenAIError.permission(message: detail)

    case .invalidRequest:
      return mapInvalidRequest(detail: detail, status: status)

    case .api, .server, .other:
      return mapGeneric(detail: safeDetail, status: status)
    }
  }

  // MARK: - Private

  private static func map(_ error: URLError) -> any Error {
    switch error.code {
    case .timedOut:
      return LanguageModelError.timeout(
        .init(debugDescription: error.localizedDescription)
      )
    case .cancelled:
      return CancellationError()
    default:
      return OpenAIError.upstream(
        message: OpenAIError.sanitize(error.localizedDescription)
      )
    }
  }

  private static func mapInvalidRequest(detail: String, status: Int) -> any Error {
    let lower = detail.lowercased()
    if isEmptyStreamMessage(lower) {
      return OpenAIError.emptyStream
    }
    return mapGeneric(detail: detail.isEmpty ? "Request failed" : detail, status: status)
  }

  private static func mapGeneric(detail: String, status: Int) -> any Error {
    if isEmptyStreamMessage(detail.lowercased()) {
      return OpenAIError.emptyStream
    }
    if status > 0 {
      return OpenAIError.http(status: status, message: detail)
    }
    return OpenAIError.upstream(message: detail)
  }

  private static func isEmptyStreamMessage(_ lower: String) -> Bool {
    lower.contains("without any decodable")
      || lower.contains("empty stream")
      || lower.contains("too many consecutive malformed")
  }
}

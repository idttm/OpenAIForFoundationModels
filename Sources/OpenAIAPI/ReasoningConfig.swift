import Foundation

/// OpenAI Responses API `reasoning` request object.
package struct ReasoningConfig: Sendable, Hashable, Codable {
  package var effort: Effort?
  package var summary: Summary?

  package init(
    effort: Effort? = nil,
    summary: Summary? = nil
  ) {
    self.effort = effort
    self.summary = summary
  }

  package enum Effort: String, Sendable, Hashable, Codable, CaseIterable {
    case max
    case xhigh
    case high
    case medium
    case low
    case minimal
    case none
  }

  package enum Summary: String, Sendable, Hashable, Codable {
    case auto
    case concise
    case detailed
  }
}

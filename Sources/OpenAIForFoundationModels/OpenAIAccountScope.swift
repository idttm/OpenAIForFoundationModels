import Foundation

/// Optional account scoping headers for organizations that use multiple
/// OpenAI organizations or projects.
public struct OpenAIAccountScope: Sendable, Hashable {
  public var organizationID: String?
  public var projectID: String?

  public init(
    organizationID: String? = nil,
    projectID: String? = nil
  ) {
    self.organizationID = organizationID
    self.projectID = projectID
  }
}

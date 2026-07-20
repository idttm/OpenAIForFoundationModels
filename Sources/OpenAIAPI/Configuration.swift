import Foundation

package struct Configuration: Sendable {
  package enum Auth: Sendable, Hashable {
    /// `Authorization: Bearer <key>`.
    case apiKey(String)
    /// No credential. Use when a proxy adds auth server-side, or when the
    /// caller injects headers per request.
    case none
  }

  package var auth: Auth
  package var baseURL: URL
  /// Optional OpenAI account scoping headers. These are configuration values,
  /// never accepted through untrusted per-request header maps.
  package var organizationID: String?
  package var projectID: String?

  package init(
    auth: Auth,
    baseURL: URL = URL(string: "https://api.openai.com/v1")!,
    organizationID: String? = nil,
    projectID: String? = nil
  ) {
    self.auth = auth
    self.baseURL = baseURL
    self.organizationID = organizationID
    self.projectID = projectID
  }
}

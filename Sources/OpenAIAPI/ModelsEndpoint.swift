import Foundation

/// Response from `GET /v1/models`.
package struct ModelsListResponse: Sendable, Decodable {
  package var data: [ModelDescriptor]
}

/// OpenAI's models list intentionally exposes identity and ownership, not a
/// provider capability matrix. The bridge derives conservative UI capabilities
/// separately and lets callers override them with a catalog profile.
package struct ModelDescriptor: Sendable, Hashable, Decodable {
  package var id: String
  package var object: String?
  package var created: Int?
  package var ownedBy: String?

  package init(
    id: String,
    object: String? = nil,
    created: Int? = nil,
    ownedBy: String? = nil
  ) {
    self.id = id
    self.object = object
    self.created = created
    self.ownedBy = ownedBy
  }

  private enum CodingKeys: String, CodingKey {
    case id, object, created
    case ownedBy = "owned_by"
  }
}

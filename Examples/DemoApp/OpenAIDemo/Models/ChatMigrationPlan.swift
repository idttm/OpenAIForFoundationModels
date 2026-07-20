import SwiftData

enum ChatMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [ChatSchemaV1.self]
  }

  static var stages: [MigrationStage] {
    []
  }
}

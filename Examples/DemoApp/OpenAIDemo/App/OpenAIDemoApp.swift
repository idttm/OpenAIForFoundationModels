import SwiftData
import SwiftUI

@main
struct OpenAIDemoApp: App {
  private let modelContainer: ModelContainer
  @State private var appState = AppState()

  init() {
    do {
      modelContainer = try ModelContainer(
        for: ChatThread.self,
        ChatMessage.self,
        migrationPlan: ChatMigrationPlan.self
      )
    } catch {
      fatalError("Unable to create the chat store: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      RootTabView()
        .environment(appState)
    }
    .modelContainer(modelContainer)
  }
}

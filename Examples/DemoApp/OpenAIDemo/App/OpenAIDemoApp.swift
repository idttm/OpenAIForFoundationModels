import Foundation
import SwiftData
import SwiftUI

@main
struct OpenAIDemoApp: App {
  private let modelContainer: ModelContainer
  @State private var appState = AppState()

  init() {
    do {
      let applicationSupportDirectory = try FileManager.default.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      )
      try FileManager.default.createDirectory(
        at: applicationSupportDirectory,
        withIntermediateDirectories: true
      )
      let storeURL = applicationSupportDirectory.appendingPathComponent(
        "default.store",
        isDirectory: false
      )
      let configuration = ModelConfiguration(url: storeURL)

      modelContainer = try ModelContainer(
        for: ChatThread.self,
        ChatMessage.self,
        migrationPlan: ChatMigrationPlan.self,
        configurations: configuration
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

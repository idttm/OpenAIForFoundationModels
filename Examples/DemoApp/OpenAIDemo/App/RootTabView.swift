import SwiftUI

struct RootTabView: View {
  @Environment(AppState.self) private var appState

  var body: some View {
    @Bindable var appState = appState

    TabView(selection: $appState.selectedTab) {
      Tab("Chat", systemImage: "bubble.left.and.bubble.right", value: .chat) {
        ChatHomeView()
      }
      Tab("Models", systemImage: "square.stack.3d.up", value: .models) {
        ModelCatalogView()
      }
      Tab("Labs", systemImage: "flask", value: .labs) {
        LabsView()
      }
      Tab("Settings", systemImage: "gearshape", value: .settings) {
        SettingsView()
      }
    }
  }
}

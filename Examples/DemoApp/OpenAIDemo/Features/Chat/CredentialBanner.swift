import SwiftUI

struct CredentialBanner: View {
  @Environment(AppState.self) private var appState

  var body: some View {
    Button {
      appState.selectedTab = .settings
    } label: {
      Label(
        "Add an API key or relay to send messages",
        systemImage: "key"
      )
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.bordered)
    .padding()
  }
}

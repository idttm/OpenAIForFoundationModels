import SwiftUI

struct ArchitectureView: View {
  var body: some View {
    List {
      Section("Pipeline") {
        ArchitectureStep(
          icon: "apple.intelligence",
          title: "Foundation Models",
          detail: "LanguageModelSession owns transcript, tools, and typed output."
        )
        ArchitectureStep(
          icon: "arrow.left.arrow.right",
          title: "OpenAI bridge",
          detail: "Translates requests and semantic stream events."
        )
        ArchitectureStep(
          icon: "cloud",
          title: "Responses API",
          detail: "Streams text, reasoning summaries, tools, and usage."
        )
      }

      Section("Privacy") {
        Label("Local SwiftData history", systemImage: "externaldrive")
        Label("Keychain credentials", systemImage: "key.fill")
        Label("Responses store disabled by default", systemImage: "hand.raised")
      }
    }
    .navigationTitle("Architecture")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
  }
}

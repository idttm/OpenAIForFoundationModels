import OpenAIForFoundationModels
import SwiftUI

struct ModelDetailView: View {
  @Environment(AppState.self) private var appState
  let model: OpenAIModel

  var body: some View {
    List {
      Section("Identity") {
        LabeledContent("Model", value: model.id)
        if let owner = model.owner {
          LabeledContent("Owner", value: owner)
        }
      }

      Section {
        ForEach(ModelFeature.allCases, id: \.self) { feature in
          Label(
            feature.shortLabel,
            systemImage:
              model.supports(feature)
              ? "checkmark.circle.fill"
              : "minus.circle"
          )
          .foregroundStyle(
            model.supports(feature) ? .primary : .secondary
          )
        }
      } header: {
        Text("Bridge profile")
      } footer: {
        Text(
          "The models endpoint does not publish a full capability matrix. "
            + "The package uses conservative family-level inference."
        )
      }

      Button("Use this model", systemImage: "checkmark") {
        appState.settings.selectedModelID = model.id
        appState.settings.persist()
      }
      .disabled(appState.settings.selectedModelID == model.id)
    }
    .navigationTitle(model.name)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
  }
}

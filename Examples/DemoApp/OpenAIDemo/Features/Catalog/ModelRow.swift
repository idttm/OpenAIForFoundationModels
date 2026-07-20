import OpenAIForFoundationModels
import SwiftUI

struct ModelRow: View {
  let model: OpenAIModel

  var body: some View {
    VStack(alignment: .leading) {
      Text(model.name)
        .font(.headline)
      Text(model.id)
        .font(.subheadline.monospaced())
        .foregroundStyle(.secondary)
      if !model.uiConfiguration.featureLabels.isEmpty {
        ScrollView(.horizontal) {
          HStack {
            ForEach(model.uiConfiguration.featureLabels, id: \.self) {
              Text($0)
                .font(.subheadline)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
            }
          }
        }
        .scrollIndicators(.hidden)
      }
    }
    .padding(.vertical, 4)
  }
}

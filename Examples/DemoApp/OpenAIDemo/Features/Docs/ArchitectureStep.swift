import SwiftUI

struct ArchitectureStep: View {
  let icon: String
  let title: String
  let detail: String

  var body: some View {
    Label {
      VStack(alignment: .leading) {
        Text(title)
          .font(.headline)
        Text(detail)
          .foregroundStyle(.secondary)
      }
    } icon: {
      Image(systemName: icon)
    }
  }
}

import SwiftUI

struct ErrorBanner: View {
  let message: String
  let dismiss: () -> Void

  var body: some View {
    HStack(alignment: .top) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        Text("Something went wrong")
          .font(.headline)
        Text(message)
          .font(.callout)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Button("Dismiss error", systemImage: "xmark", action: dismiss)
        .labelStyle(.iconOnly)
        .accessibilityLabel("Dismiss error")
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .contain)
  }
}

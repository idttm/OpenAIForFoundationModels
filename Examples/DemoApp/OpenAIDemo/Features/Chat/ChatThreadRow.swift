import SwiftUI

struct ChatThreadRow: View {
  let thread: ChatThread

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(thread.title)
        .font(.headline)
        .lineLimit(2)
      ViewThatFits(in: .horizontal) {
        HStack {
          Label(thread.modelID, systemImage: "cpu")
          Spacer()
          Text(thread.updatedAt, format: .relative(presentation: .named))
        }
        VStack(alignment: .leading, spacing: 4) {
          Label(thread.modelID, systemImage: "cpu")
          Text(thread.updatedAt, format: .relative(presentation: .named))
        }
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }
}

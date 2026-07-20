import SwiftData
import SwiftUI

struct ChatHomeView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(AppState.self) private var appState
  @Query(sort: \ChatThread.updatedAt, order: .reverse)
  private var threads: [ChatThread]

  var body: some View {
    NavigationStack {
      Group {
        if threads.isEmpty {
          ContentUnavailableView(
            "No conversations",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("Create a conversation to start using OpenAI.")
          )
        } else {
          List {
            ForEach(threads) { thread in
              NavigationLink(value: thread.id) {
                ChatThreadRow(thread: thread)
              }
            }
            .onDelete(perform: delete)
          }
        }
      }
      .navigationTitle("Conversations")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(for: UUID.self) {
        ChatThreadDestination(threadID: $0)
      }
      .toolbar {
        Button("New conversation", systemImage: "square.and.pencil", action: create)
      }
    }
  }

  private func create() {
    let thread = ChatThread(modelID: appState.settings.selectedModelID)
    modelContext.insert(thread)
    try? modelContext.save()
  }

  private func delete(at offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(threads[index])
    }
    try? modelContext.save()
  }
}

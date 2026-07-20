import Foundation
import FoundationModels
import Observation
import OpenAIForFoundationModels
import SwiftData

@Observable
@MainActor
final class ChatSessionController {
  private(set) var isStreaming = false
  private(set) var streamingMessageID: UUID?
  var errorMessage: String?

  @ObservationIgnored
  private var streamTask: Task<Void, Never>?

  @ObservationIgnored
  private var generation = UUID()

  func send(
    text: String,
    thread: ChatThread,
    model: OpenAIModel,
    settings: DemoSettings,
    modelContext: ModelContext
  ) async {
    let prompt = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !prompt.isEmpty, !isStreaming else { return }

    let history = thread.messages
      .filter { !$0.text.isEmpty }
      .map {
        ChatMessageSnapshot(
          id: $0.id,
          role: $0.role,
          text: $0.text,
          createdAt: $0.createdAt
        )
      }
    let transcript = TranscriptBuilder.make(from: history)

    streamTask?.cancel()
    let currentGeneration = UUID()
    generation = currentGeneration
    errorMessage = nil

    let userMessage = ChatMessage(
      role: .user,
      text: prompt,
      thread: thread
    )
    let assistantMessage = ChatMessage(
      role: .assistant,
      text: "",
      thread: thread
    )
    modelContext.insert(userMessage)
    modelContext.insert(assistantMessage)
    thread.updatedAt = .now
    if thread.messages.count <= 2 || thread.title == "New conversation" {
      thread.title = Self.title(from: prompt)
    }
    try? modelContext.save()

    isStreaming = true
    streamingMessageID = assistantMessage.id

    let task = Task { @MainActor [weak self] in
      guard let self else { return }
      defer {
        if generation == currentGeneration {
          isStreaming = false
          streamingMessageID = nil
          streamTask = nil
        }
      }

      do {
        let tools: [any Tool] =
          settings.enableClientTools ? SampleTools.all() : []
        let session = try ModelFactory.makeSession(
          settings: settings,
          model: model,
          tools: tools,
          transcript: transcript
        )
        let stream = session.streamResponse(to: prompt)
        var latestText = ""
        var lastPublish = ContinuousClock.now

        for try await partial in stream {
          try Task.checkCancellation()
          guard generation == currentGeneration else { return }
          latestText = partial.content
          if ContinuousClock.now - lastPublish >= .milliseconds(40) {
            assistantMessage.text = latestText
            lastPublish = .now
          }
        }

        guard generation == currentGeneration else { return }
        assistantMessage.text =
          latestText.isEmpty ? "(empty response)" : latestText
        thread.updatedAt = .now
        try modelContext.save()
      } catch is CancellationError {
        guard generation == currentGeneration else { return }
        if assistantMessage.text.isEmpty {
          modelContext.delete(assistantMessage)
        }
        thread.updatedAt = .now
        try? modelContext.save()
      } catch {
        guard generation == currentGeneration else { return }
        errorMessage = ModelFactory.format(error)
        if assistantMessage.text.isEmpty {
          modelContext.delete(assistantMessage)
        }
        thread.updatedAt = .now
        try? modelContext.save()
      }
    }

    streamTask = task
    await task.value
  }

  func stop() {
    streamTask?.cancel()
  }

  private static func title(from prompt: String) -> String {
    let singleLine =
      prompt
      .replacingOccurrences(of: "\n", with: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if singleLine.count <= 42 { return singleLine }
    return String(singleLine.prefix(41)) + "…"
  }
}

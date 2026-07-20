import Foundation
import FoundationModels
import OpenAIAPI

protocol GenerationEventSink: Sendable {
  func send(_ event: LanguageModelExecutorGenerationChannel.Event) async
  func sendToolCall(
    entryID: String,
    id: String,
    name: String,
    arguments: String,
    tokenCount: Int
  ) async
}

extension GenerationEventSink {
  func sendToolCall(
    entryID: String,
    id: String,
    name: String,
    arguments: String,
    tokenCount: Int
  ) async {
    await send(
      .toolCalls(
        entryID: entryID,
        action: .toolCall(
          id: id,
          name: name,
          action: .appendArguments(
            arguments,
            tokenCount: tokenCount
          )
        )
      )
    )
  }
}

extension LanguageModelExecutorGenerationChannel: GenerationEventSink {}

/// Maps OpenAI Responses semantic events to Foundation Models generation events.
struct EventTranslator: Sendable {
  let responseEntryID: String
  let reasoningEntryID: String
  let toolCallsEntryID: String

  static let deltaTokenCount = 1

  init(
    responseEntryID: String = UUID().uuidString,
    reasoningEntryID: String = UUID().uuidString,
    toolCallsEntryID: String = UUID().uuidString
  ) {
    self.responseEntryID = responseEntryID
    self.reasoningEntryID = reasoningEntryID
    self.toolCallsEntryID = toolCallsEntryID
  }

  func translate(
    _ events: AsyncThrowingStream<ResponseStreamEvent, Error>,
    into sink: some GenerationEventSink
  ) async throws {
    var metadataSent = false
    var textDeltaSent = false
    var toolCalls: [Int: ToolCallState] = [:]

    for try await event in events {
      try Task.checkCancellation()

      switch event {
      case .created(let response):
        if !metadataSent {
          metadataSent = await sendMetadata(response, to: sink)
        }

      case .outputTextDelta(let delta):
        guard !delta.isEmpty else { continue }
        textDeltaSent = true
        await sink.send(
          .response(
            entryID: responseEntryID,
            action: .appendText(
              delta,
              tokenCount: Self.deltaTokenCount
            )
          )
        )

      case .reasoningDelta(let delta):
        guard !delta.isEmpty else { continue }
        await sink.send(
          .reasoning(
            entryID: reasoningEntryID,
            action: .appendText(
              delta,
              tokenCount: Self.deltaTokenCount
            )
          )
        )

      case .outputItemAdded(let index, let item):
        await emitOutputItem(
          item,
          index: index,
          state: &toolCalls,
          sink: sink
        )

      case .functionCallArgumentsDelta(
        let itemID,
        let outputIndex,
        let delta
      ):
        var state =
          toolCalls[outputIndex]
          ?? ToolCallState(
            id: itemID ?? "call_\(outputIndex)",
            name: "",
            sentArgumentDelta: false
          )
        state.sentArgumentDelta = state.sentArgumentDelta || !delta.isEmpty
        toolCalls[outputIndex] = state
        await sendToolArguments(delta, state: state, sink: sink)

      case .functionCallArgumentsDone(
        let itemID,
        let outputIndex,
        let arguments
      ):
        var state =
          toolCalls[outputIndex]
          ?? ToolCallState(
            id: itemID ?? "call_\(outputIndex)",
            name: "",
            sentArgumentDelta: false
          )
        if !state.sentArgumentDelta, !arguments.isEmpty {
          await sendToolArguments(arguments, state: state, sink: sink)
          state.sentArgumentDelta = true
        }
        toolCalls[outputIndex] = state

      case .completed(let response):
        if !metadataSent {
          metadataSent = await sendMetadata(response, to: sink)
        }
        if !textDeltaSent {
          let text =
            response.output?
            .flatMap { $0.content ?? [] }
            .compactMap(\.text)
            .joined() ?? ""
          if !text.isEmpty {
            await sink.send(
              .response(
                entryID: responseEntryID,
                action: .appendText(
                  text,
                  tokenCount: Self.deltaTokenCount
                )
              )
            )
          }
        }
        if let output = response.output {
          for (index, item) in output.enumerated()
          where item.type == "function_call" && toolCalls[index] == nil {
            await emitOutputItem(
              item,
              index: index,
              state: &toolCalls,
              sink: sink
            )
          }
        }
        if let usage = response.usage {
          await sendUsage(usage, to: sink)
        }

      case .failed(let error):
        throw error

      case .ignored:
        continue
      }
    }
  }

  private func sendMetadata(
    _ response: ResponseSummary,
    to sink: some GenerationEventSink
  ) async -> Bool {
    var sent = false
    if let model = response.model {
      sent = true
      await sink.send(
        .response(
          entryID: responseEntryID,
          action: .updateMetadata(["openai.model": model])
        )
      )
    }
    if let id = response.id {
      sent = true
      await sink.send(
        .response(
          entryID: responseEntryID,
          action: .updateMetadata(["openai.response_id": id])
        )
      )
    }
    return sent
  }

  private func emitOutputItem(
    _ item: ResponseOutputItem,
    index: Int,
    state: inout [Int: ToolCallState],
    sink: some GenerationEventSink
  ) async {
    guard item.type == "function_call" else { return }
    let call = ToolCallState(
      id: item.callID ?? item.id ?? "call_\(index)",
      name: item.name ?? "",
      sentArgumentDelta: !(item.arguments ?? "").isEmpty
    )
    state[index] = call
    if let arguments = item.arguments, !arguments.isEmpty {
      await sendToolArguments(arguments, state: call, sink: sink)
    }
  }

  private func sendToolArguments(
    _ arguments: String,
    state: ToolCallState,
    sink: some GenerationEventSink
  ) async {
    guard !arguments.isEmpty else { return }
    await sink.sendToolCall(
      entryID: toolCallsEntryID,
      id: state.id,
      name: state.name,
      arguments: arguments,
      tokenCount: Self.deltaTokenCount
    )
  }

  private func sendUsage(
    _ usage: ResponseUsage,
    to sink: some GenerationEventSink
  ) async {
    await sink.send(
      .response(
        entryID: responseEntryID,
        action: .updateUsage(
          input: .init(
            totalTokenCount: usage.inputTokens ?? 0,
            cachedTokenCount:
              usage.inputTokensDetails?.cachedTokens ?? 0
          ),
          output: .init(
            totalTokenCount: usage.outputTokens ?? 0,
            reasoningTokenCount:
              usage.outputTokensDetails?.reasoningTokens ?? 0
          )
        )
      )
    )
  }
}

private struct ToolCallState: Sendable {
  var id: String
  var name: String
  var sentArgumentDelta: Bool
}

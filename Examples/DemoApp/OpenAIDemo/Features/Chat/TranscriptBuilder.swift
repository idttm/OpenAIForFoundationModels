import Foundation
import FoundationModels

enum TranscriptBuilder {
  static func make(from messages: [ChatMessageSnapshot]) -> Transcript {
    var entries: [Transcript.Entry] = [
      .instructions(
        .init(
          segments: [
            .text(
              .init(
                content:
                  "You are a helpful assistant. Be accurate, clear, and concise."
              )
            )
          ],
          toolDefinitions: []
        )
      )
    ]

    for message in messages.sorted(by: { $0.createdAt < $1.createdAt }) {
      let segment = Transcript.Segment.text(
        .init(content: message.text)
      )
      switch message.role {
      case .user:
        entries.append(
          .prompt(
            .init(
              id: message.id.uuidString,
              segments: [segment]
            )
          )
        )
      case .assistant:
        entries.append(
          .response(
            .init(
              id: message.id.uuidString,
              segments: [segment]
            )
          )
        )
      }
    }
    return Transcript(entries: entries)
  }
}

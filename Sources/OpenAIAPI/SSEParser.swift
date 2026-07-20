import Foundation

/// Parses a `text/event-stream` byte stream into OpenAI Responses semantic events.
enum SSEParser {
  static let maxConsecutiveDecodeFailures = 8

  static func payloads(
    from bytes: AsyncThrowingStream<UInt8, Error>
  ) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          var dataLines: [String] = []

          func flush() {
            guard !dataLines.isEmpty else { return }
            let payload = dataLines.joined(separator: "\n")
            dataLines.removeAll(keepingCapacity: true)
            guard payload != "[DONE]" else { return }
            continuation.yield(payload)
          }

          func handle(_ line: String) {
            if line.isEmpty {
              flush()
            } else if line.hasPrefix("data:") {
              dataLines.append(
                String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
              )
            }
          }

          var line: [UInt8] = []
          line.reserveCapacity(256)
          var previousByteWasCR = false

          for try await byte in bytes {
            try Task.checkCancellation()
            switch byte {
            case UInt8(ascii: "\n") where previousByteWasCR:
              previousByteWasCR = false
            case UInt8(ascii: "\n"), UInt8(ascii: "\r"):
              previousByteWasCR = byte == UInt8(ascii: "\r")
              handle(String(decoding: line, as: UTF8.self))
              line.removeAll(keepingCapacity: true)
            default:
              previousByteWasCR = false
              line.append(byte)
            }
          }

          if !line.isEmpty {
            handle(String(decoding: line, as: UTF8.self))
          }
          flush()
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  static func events(
    from bytes: AsyncThrowingStream<UInt8, Error>
  ) -> AsyncThrowingStream<ResponseStreamEvent, Error> {
    AsyncThrowingStream { continuation in
      let task = Task {
        do {
          let decoder = JSONDecoder()
          var yielded = 0
          var consecutiveDecodeFailures = 0

          for try await payload in payloads(from: bytes) {
            try Task.checkCancellation()
            do {
              let event = try decoder.decode(
                ResponseStreamEvent.self,
                from: Data(payload.utf8)
              )
              if case .failed(let error) = event {
                throw error
              }
              consecutiveDecodeFailures = 0
              yielded += 1
              continuation.yield(event)
            } catch let error as APIError {
              throw error
            } catch is CancellationError {
              throw CancellationError()
            } catch {
              consecutiveDecodeFailures += 1
              if consecutiveDecodeFailures >= maxConsecutiveDecodeFailures {
                throw APIError(
                  kind: .api,
                  message: "Stream contained too many undecodable Responses API events."
                )
              }
            }
          }

          guard yielded > 0 else {
            throw APIError(
              kind: .api,
              message: "Stream ended without any decodable Responses API events."
            )
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}

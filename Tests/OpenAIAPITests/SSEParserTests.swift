import Testing

@testable import OpenAIAPI

struct SSEParserTests {
  @Test("Parses CRLF frames, ignores comments, and skips the DONE sentinel")
  func parsesFrames() async throws {
    let body =
      ": keep-alive\r\n\r\n"
      + "data: {\"type\":\"response.created\",\"response\":{\"id\":\"resp_1\"}}\r\n\r\n"
      + "data: {\"type\":\"response.output_text.delta\",\"delta\":\"Hi\"}\r\n\r\n"
      + "data: [DONE]\r\n\r\n"

    var events: [ResponseStreamEvent] = []
    for try await event in SSEParser.events(from: byteStream(body)) {
      events.append(event)
    }
    #expect(events.count == 2)
    #expect(events[1] == .outputTextDelta("Hi"))
  }

  @Test("Tolerates isolated unknown or malformed events")
  func toleratesNoise() async throws {
    let body =
      "data: not-json\n\n"
      + "data: {\"type\":\"response.audio.delta\",\"delta\":\"ignored\"}\n\n"
      + "data: {\"type\":\"response.output_text.delta\",\"delta\":\"usable\"}\n\n"

    var events: [ResponseStreamEvent] = []
    for try await event in SSEParser.events(from: byteStream(body)) {
      events.append(event)
    }
    #expect(
      events == [
        .ignored(type: "response.audio.delta"),
        .outputTextDelta("usable"),
      ])
  }

  @Test("Rejects a stream with no semantic event")
  func rejectsEmptyStream() async {
    do {
      for try await _ in SSEParser.events(
        from: byteStream("data: [DONE]\n\n")
      ) {}
      Issue.record("Expected an APIError for an empty semantic stream.")
    } catch let error as APIError {
      #expect(error.message.contains("without any decodable"))
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

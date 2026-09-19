import CoreGraphics
import Foundation
import FoundationModels
import ImageIO
import Testing

@testable import OpenAIAPI
@testable import OpenAIForFoundationModels

struct SegmentCompatibilityTests {
  @Test("Maps stable text and structured segments while ignoring attachments in text")
  func rendersStableTranscriptSegments() throws {
    let structured = GeneratedContent("example")
    let attachment = Transcript.AttachmentSegment(
      content: .image(Transcript.ImageAttachment(makeTestImage())),
      label: "pixel"
    )
    let segments: [Transcript.Segment] = [
      .text(.init(content: "visible")),
      .structure(
        .init(schemaName: "Example", content: structured)
      ),
      .attachment(attachment),
    ]

    let rendered = RequestBuilder.text(of: segments, separator: "|")

    #expect(rendered.contains("visible"))
    #expect(rendered.contains("example"))
    #expect(!rendered.contains("pixel"))
    #expect(!rendered.contains("data:image"))
  }

  @Test("Maps a stable image attachment to an OpenAI image content part")
  func mapsImageAttachment() throws {
    let segments: [Transcript.Segment] = [
      .text(.init(content: "caption")),
      .attachment(
        .init(content: .image(Transcript.ImageAttachment(makeTestImage())))
      ),
    ]

    let content = try RequestBuilder.inputContent(from: segments)
    guard case .parts(let parts) = content else {
      Issue.record("Expected an image prompt to use Responses content parts.")
      return
    }

    #expect(parts.count == 2)
    #expect(parts.first?.textValue == "caption")
    guard case .imageURL(let dataURL, let detail) = parts[1] else {
      Issue.record("Expected the attachment to become an input_image part.")
      return
    }
    #expect(dataURL.hasPrefix("data:image/png;base64,"))
    #expect(
      Data(base64Encoded: String(dataURL.dropFirst("data:image/png;base64,".count)))
        != nil
    )
    #expect(detail == nil)
  }

  @Test("Collapses text and structured segments to plain Responses text without an image")
  func mapsTextOnlySegments() throws {
    let structured = GeneratedContent("42")
    let content = try RequestBuilder.inputContent(from: [
      .text(.init(content: "question: ")),
      .structure(.init(schemaName: "Answer", content: structured)),
      .text(.init(content: "?")),
    ])

    guard case .text(let text) = content else {
      Issue.record("Expected text-only segments to use a plain Responses string.")
      return
    }
    #expect(text.hasPrefix("question: "))
    #expect(text.contains("42"))
    #expect(text.hasSuffix("?"))
  }

  @Test("Bakes every image orientation into encoded pixels")
  func bakesImageOrientation() throws {
    #expect(cornerPixels(of: makeAsymmetricImage()) == [.red, .blue, .yellow, .cyan])
    let expectations:
      [(
        orientation: CGImagePropertyOrientation,
        width: Int,
        height: Int,
        corners: [Pixel]
      )] = [
        (.up, 3, 2, [.red, .blue, .yellow, .cyan]),
        (.upMirrored, 3, 2, [.blue, .red, .cyan, .yellow]),
        (.down, 3, 2, [.cyan, .yellow, .blue, .red]),
        (.downMirrored, 3, 2, [.yellow, .cyan, .red, .blue]),
        (.leftMirrored, 2, 3, [.red, .yellow, .blue, .cyan]),
        (.right, 2, 3, [.yellow, .red, .cyan, .blue]),
        (.rightMirrored, 2, 3, [.cyan, .blue, .yellow, .red]),
        (.left, 2, 3, [.blue, .cyan, .red, .yellow]),
      ]

    for expectation in expectations {
      let image = Transcript.ImageAttachment(
        makeAsymmetricImage(),
        orientation: expectation.orientation
      )
      let content = try RequestBuilder.inputContent(from: [
        .attachment(.init(content: .image(image)))
      ])
      guard case .parts(let parts) = content,
        case .imageURL(let dataURL, _) = parts.first
      else {
        Issue.record("Expected an image content part.")
        continue
      }

      let encoded = try decodedImage(from: dataURL)
      #expect(encoded.width == expectation.width)
      #expect(encoded.height == expectation.height)
      #expect(cornerPixels(of: encoded) == expectation.corners)
    }
  }

  private func makeTestImage() -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytes: [UInt8] = [255, 0, 0, 255]
    let provider = CGDataProvider(data: Data(bytes) as CFData)!
    return CGImage(
      width: 1,
      height: 1,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: 4,
      space: colorSpace,
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    )!
  }

  private func makeAsymmetricImage() -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytes: [UInt8] = [
      255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255,
      255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 255,
    ]
    let provider = CGDataProvider(data: Data(bytes) as CFData)!
    return CGImage(
      width: 3,
      height: 2,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: 12,
      space: colorSpace,
      bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    )!
  }

  private func decodedImage(from dataURL: String) throws -> CGImage {
    let prefix = "data:image/png;base64,"
    guard
      dataURL.hasPrefix(prefix),
      let data = Data(base64Encoded: String(dataURL.dropFirst(prefix.count))),
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      throw SegmentCompatibilityError.invalidImageData
    }
    return image
  }

  private func cornerPixels(of image: CGImage) -> [Pixel] {
    var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
    bytes.withUnsafeMutableBytes { buffer in
      guard
        let context = CGContext(
          data: buffer.baseAddress,
          width: image.width,
          height: image.height,
          bitsPerComponent: 8,
          bytesPerRow: image.width * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
      else { return }
      context.interpolationQuality = .none
      context.draw(
        image,
        in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
      )
    }

    func pixel(atX x: Int, y: Int) -> Pixel {
      // Bitmap memory retains the source image's top-to-bottom row order.
      let offset = (y * image.width + x) * 4
      return Pixel(
        red: bytes[offset],
        green: bytes[offset + 1],
        blue: bytes[offset + 2]
      )
    }

    return [
      pixel(atX: 0, y: 0),
      pixel(atX: image.width - 1, y: 0),
      pixel(atX: 0, y: image.height - 1),
      pixel(atX: image.width - 1, y: image.height - 1),
    ]
  }
}

private struct Pixel: Equatable {
  let red: UInt8
  let green: UInt8
  let blue: UInt8

  static let red = Pixel(red: 255, green: 0, blue: 0)
  static let blue = Pixel(red: 0, green: 0, blue: 255)
  static let yellow = Pixel(red: 255, green: 255, blue: 0)
  static let cyan = Pixel(red: 0, green: 255, blue: 255)
}

private enum SegmentCompatibilityError: Error {
  case invalidImageData
}

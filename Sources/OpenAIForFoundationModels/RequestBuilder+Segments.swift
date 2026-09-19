import CoreGraphics
import CoreImage
import Foundation
import FoundationModels
import ImageIO
import OpenAIAPI
import UniformTypeIdentifiers

extension RequestBuilder {
  static func text(
    of segments: [Transcript.Segment],
    separator: String = "\n"
  ) -> String {
    segments.compactMap {
      switch $0 {
      case .text(let value):
        value.content
      case .structure(let value):
        value.content.jsonString
      case .attachment:
        nil
      @unknown default:
        nil
      }
    }
    .joined(separator: separator)
  }

  static func inputContent(
    from segments: [Transcript.Segment]
  ) throws -> InputContent {
    var parts: [InputContentPart] = []
    var plain = ""

    for segment in segments {
      switch segment {
      case .text(let value) where !value.content.isEmpty:
        parts.append(.text(value.content))
        plain += value.content
      case .text:
        break
      case .structure(let value):
        let json = value.content.jsonString
        parts.append(.text(json))
        plain += json
      case .attachment(let attachment):
        switch attachment.content {
        case .image(let image):
          parts.append(
            .imageURL(
              try imageDataURL(
                cgImage: image.cgImage,
                orientation: image.orientation
              ),
              detail: nil
            )
          )
        @unknown default:
          break
        }
      @unknown default:
        break
      }
    }

    let hasImage = parts.contains {
      if case .imageURL = $0 { return true }
      return false
    }
    return hasImage ? .parts(parts) : .text(plain)
  }

  static func stripImages(_ item: ResponseInputItem) -> ResponseInputItem {
    guard case .message(let role, .parts(let parts)) = item else {
      return item
    }
    let text = parts.compactMap(\.textValue).joined()
    return .message(role: role, content: .text(text))
  }

  private static func imageDataURL(
    cgImage: CGImage,
    orientation: CGImagePropertyOrientation
  ) throws -> String {
    let oriented = CIImage(cgImage: cgImage)
      .oriented(forExifOrientation: Int32(orientation.rawValue))
    let context = CIContext()
    guard
      let rendered = context.createCGImage(oriented, from: oriented.extent)
    else {
      throw OpenAIError.upstream(message: "Could not render the oriented image.")
    }
    let data = try pngData(from: rendered)
    return "data:image/png;base64,\(data.base64EncodedString())"
  }

  private static func pngData(from image: CGImage) throws -> Data {
    let data = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        data,
        UTType.png.identifier as CFString,
        1,
        nil
      )
    else {
      throw OpenAIError.upstream(message: "Could not create a PNG encoder.")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
      throw OpenAIError.upstream(message: "Could not finalize PNG encoding.")
    }
    return data as Data
  }
}

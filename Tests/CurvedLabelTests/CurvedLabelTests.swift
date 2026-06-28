import CoreGraphics
import Foundation
import Testing
@testable import CurvedLabel
#if canImport(UIKit)
import UIKit
#endif

struct CurvedLabelTests {
  @Test
  func emptyGlyphWidthsReturnNoArcInfo() {
    #expect(CurvedLabelGlyphArcCalculator.arcInfo(forGlyphWidths: [],
                                                 radius: 120).isEmpty)
  }

  @Test
  func invalidRadiusReturnsNoArcInfo() {
    #expect(CurvedLabelGlyphArcCalculator.arcInfo(forGlyphWidths: [12, 18],
                                                 radius: 0).isEmpty)
    #expect(CurvedLabelGlyphArcCalculator.arcInfo(forGlyphWidths: [12, 18],
                                                 radius: -20).isEmpty)
  }

  @Test
  func glyphAnglesUseCenterToCenterDistances() {
    let arcInfo = CurvedLabelGlyphArcCalculator.arcInfo(forGlyphWidths: [10, 20, 30],
                                                       radius: 100)

    #expect(arcInfo.count == 3)
    #expect(arcInfo[0].width == 10)
    #expect(arcInfo[1].width == 20)
    #expect(arcInfo[2].width == 30)
    #expect(arcInfo[1].angle.isApproximatelyEqual(to: 0.15))
    #expect(arcInfo[2].angle.isApproximatelyEqual(to: 0.25))
  }

  @Test
  func firstGlyphAngleCentersTheLineAcrossTheTopHalfCircle() {
    let arcInfo = CurvedLabelGlyphArcCalculator.arcInfo(forGlyphWidths: [10, 20, 30],
                                                       radius: 100)
    let firstGlyphHalfWidthAngle: CGFloat = 0.05
    let centerToCenterAngles: CGFloat = 0.15 + 0.25
    let maxAngle = firstGlyphHalfWidthAngle + centerToCenterAngles
    let expectedFirstAngle = firstGlyphHalfWidthAngle + (CGFloat.pi - maxAngle) / 2.0

    #expect(arcInfo[0].angle.isApproximatelyEqual(to: expectedFirstAngle))
  }

  @Test
  func smallRadiusAppliesCompensatingSpacing() {
    let normalRadiusArcInfo = CurvedLabelGlyphArcCalculator.arcInfo(forGlyphWidths: [10, 10],
                                                                   radius: 50)
    let smallRadiusArcInfo = CurvedLabelGlyphArcCalculator.arcInfo(forGlyphWidths: [10, 10],
                                                                  radius: 25)

    #expect(normalRadiusArcInfo[1].angle.isApproximatelyEqual(to: 0.2))
    #expect(smallRadiusArcInfo[1].angle.isApproximatelyEqual(to: 0.5))
  }

#if canImport(UIKit)
  @Test
  @MainActor
  func curvedLabelInitializerUsesDefaultConfiguration() {
    let label = CurvedLabel()

    #expect(label.frame == .zero)
    #expect(label.radius == 0)
    #expect(label.rotation == 0)
    #expect(label.textInside == false)
  }

  @Test
  @MainActor
  func zeroRadiusFallsBackToPlainLabelRendering() {
    let label = CurvedLabel(frame: CGRect(x: 0, y: 0, width: 160, height: 60))
    label.backgroundColor = .clear
    label.font = .systemFont(ofSize: 32)
    label.textColor = .black
    label.text = "Hello"

    let image = UIGraphicsImageRenderer(size: label.bounds.size).image { _ in
      label.draw(label.bounds)
    }

    #expect(image.hasVisiblePixels)
  }
#endif
}

private extension CGFloat {
  func isApproximatelyEqual(to other: CGFloat, tolerance: CGFloat = 0.0001) -> Bool {
    Swift.abs(self - other) <= tolerance
  }
}

#if canImport(UIKit)
private extension UIImage {
  var hasVisiblePixels: Bool {
    guard let cgImage else { return false }

    let width = cgImage.width
    let height = cgImage.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
      data: &pixels,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: width * 4,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return false
    }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    return stride(from: 3, to: pixels.count, by: 4).contains { pixels[$0] > 0 }
  }
}
#endif

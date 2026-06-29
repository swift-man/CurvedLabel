//
//  CurvedLabelTests.swift
//  CurvedLabel
//
//  Created by Gorani on 2026/06/29.
//  Copyright © 2026 Gorani. All rights reserved.
//

import CoreGraphics
import CoreText
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
    let trailingGlyphHalfWidthAngle: CGFloat = 0.15
    let maxAngle = firstGlyphHalfWidthAngle + centerToCenterAngles + trailingGlyphHalfWidthAngle
    let expectedFirstAngle = firstGlyphHalfWidthAngle + (CGFloat.pi - maxAngle) / 2.0

    #expect(arcInfo[0].angle.isApproximatelyEqual(to: expectedFirstAngle))
  }

  @Test
  func firstGlyphAngleCentersSingleGlyphAcrossTheTopHalfCircle() {
    let arcInfo = CurvedLabelGlyphArcCalculator.arcInfo(forGlyphWidths: [20],
                                                       radius: 100)
    let firstGlyphHalfWidthAngle: CGFloat = 0.1
    let trailingGlyphHalfWidthAngle: CGFloat = 0.1
    let maxAngle = firstGlyphHalfWidthAngle + trailingGlyphHalfWidthAngle
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

  @Test
  func arcInfoMatchesCoreTextRunGlyphCount() {
    let attributedString = NSAttributedString(string: "Hello World!")
    let line = CTLineCreateWithAttributedString(attributedString as CFAttributedString)
    let runs = CTLineGetGlyphRuns(line) as? [CTRun] ?? []
    let arcInfo = CurvedLabelGlyphArcCalculator.arcInfo(for: line, radius: 120)

    #expect(!runs.isEmpty)
    #expect(arcInfo.count == CurvedLabelGlyphArcCalculator.glyphCount(in: runs))
  }

  @Test
  func glyphWidthsMatchCoreTextTypographicWidths() {
    let font = CTFontCreateWithName("Helvetica" as CFString, 18, nil)
    let attributedString = NSAttributedString(
      string: "Hello World!",
      attributes: [
        kCTFontAttributeName as NSAttributedString.Key: font
      ]
    )
    let line = CTLineCreateWithAttributedString(attributedString as CFAttributedString)

    let advanceWidths = CurvedLabelGlyphArcCalculator.glyphWidths(in: line)
    let typographicWidths = Self.typographicGlyphWidths(in: line)

    #expect(!advanceWidths.isEmpty)
    #expect(advanceWidths.count == typographicWidths.count)
    for (advanceWidth, typographicWidth) in zip(advanceWidths, typographicWidths) {
      #expect(advanceWidth.isApproximatelyEqual(to: typographicWidth))
    }
  }

  private static func typographicGlyphWidths(in line: CTLine) -> [CGFloat] {
    guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return [] }
    var widths: [CGFloat] = []

    for run in runs {
      for glyphIndex in 0..<CTRunGetGlyphCount(run) {
        widths.append(
          CGFloat(
            CTRunGetTypographicBounds(
              run,
              CFRange(location: glyphIndex, length: 1),
              nil,
              nil,
              nil
            )
          )
        )
      }
    }

    return widths
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
  func negativeRadiusClampsToZero() {
    let label = CurvedLabel()

    label.radius = -12

    #expect(label.radius == 0)
  }

  @Test
  @MainActor
  func defaultRadiusUsesPlainLabelIntrinsicSize() {
    let label = CurvedLabel()
    label.text = "Hi"
    label.font = .systemFont(ofSize: 20)

    let plainLabel = UILabel()
    plainLabel.text = label.text
    plainLabel.font = label.font

    #expect(label.intrinsicContentSize == plainLabel.intrinsicContentSize)
  }

  @Test
  @MainActor
  func positiveRadiusDefinesMinimumIntrinsicSize() {
    let label = CurvedLabel()
    label.text = "Hi"
    label.font = .systemFont(ofSize: 20)
    label.textInside = true

    label.radius = 80

    #expect(label.intrinsicContentSize.width >= 160)
    #expect(label.intrinsicContentSize.height >= 160)
  }

  @Test
  @MainActor
  func outsideTextAddsLineHeightToIntrinsicSize() {
    let label = CurvedLabel()
    label.text = "Hi"
    label.font = .systemFont(ofSize: 20)

    label.radius = 80

    let expectedDiameter = ceil((label.radius + ceil(label.font.lineHeight)) * 2.0)
    #expect(label.intrinsicContentSize.width == expectedDiameter)
    #expect(label.intrinsicContentSize.height == expectedDiameter)
  }

  @Test
  @MainActor
  func attributedTextFontDefinesOutsideIntrinsicSize() {
    let label = CurvedLabel()
    label.font = .systemFont(ofSize: 12)
    label.radius = 80

    let attributedFont = UIFont.systemFont(ofSize: 42)
    label.attributedText = NSAttributedString(
      string: "Hi",
      attributes: [
        .font: attributedFont,
        .foregroundColor: UIColor.black
      ]
    )

    let expectedDiameter = ceil((label.radius + ceil(attributedFont.lineHeight)) * 2.0)
    #expect(label.intrinsicContentSize.width == expectedDiameter)
    #expect(label.intrinsicContentSize.height == expectedDiameter)
  }

  @Test
  @MainActor
  func missingAttributedTextFontRangeFallsBackToLabelFontForIntrinsicSize() {
    let label = CurvedLabel()
    label.font = .systemFont(ofSize: 42)
    label.radius = 80

    let attributedText = NSMutableAttributedString(string: "Hi")
    attributedText.addAttribute(
      .font,
      value: UIFont.systemFont(ofSize: 12),
      range: NSRange(location: 0, length: 1)
    )
    label.attributedText = attributedText

    let expectedDiameter = ceil((label.radius + ceil(label.font.lineHeight)) * 2.0)
    #expect(label.intrinsicContentSize.width == expectedDiameter)
    #expect(label.intrinsicContentSize.height == expectedDiameter)
  }

  @Test
  @MainActor
  func zeroRadiusRestoresBaseIntrinsicSize() {
    let label = CurvedLabel()
    label.text = "Hi"
    label.font = .systemFont(ofSize: 20)

    let plainLabel = UILabel()
    plainLabel.text = label.text
    plainLabel.font = label.font

    label.radius = 80
    label.radius = 0

    #expect(label.intrinsicContentSize == plainLabel.intrinsicContentSize)
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

  @Test
  @MainActor
  func positiveRadiusDrawsCurvedText() {
    let label = Self.curvedTextLabel()
    let image = Self.renderedImage(from: label)

    let plainLabel = UILabel(frame: label.frame)
    plainLabel.backgroundColor = label.backgroundColor
    plainLabel.attributedText = label.attributedText

    let plainImage = Self.renderedImage(from: plainLabel)

    #expect(image.hasVisiblePixels)
    #expect(image.differsVisibly(from: plainImage,
                                 channelTolerance: 8,
                                 minimumDifferingPixels: 32))
  }

  @Test
  @MainActor
  func rotationChangesCurvedTextRendering() {
    let topImage = Self.renderedCurvedTextImage(rotation: 0)
    let rotatedImage = Self.renderedCurvedTextImage(rotation: 180)

    #expect(topImage.hasVisiblePixels)
    #expect(rotatedImage.hasVisiblePixels)
    #expect(topImage.differsVisibly(from: rotatedImage,
                                    channelTolerance: 8,
                                    minimumDifferingPixels: 32))
  }

  @Test
  @MainActor
  func textInsideChangesCurvedTextRendering() {
    let outsideImage = Self.renderedCurvedTextImage(textInside: false)
    let insideImage = Self.renderedCurvedTextImage(textInside: true)

    #expect(outsideImage.hasVisiblePixels)
    #expect(insideImage.hasVisiblePixels)
    #expect(outsideImage.differsVisibly(from: insideImage,
                                        channelTolerance: 8,
                                        minimumDifferingPixels: 32))
  }

  @Test
  @MainActor
  func smallPositiveRadiusStillDrawsCurvedText() {
    let image = Self.renderedCurvedTextImage(radius: 24,
                                             text: "Small Radius")

    #expect(image.hasVisiblePixels)
  }

  @MainActor
  private static func renderedCurvedTextImage(radius: CGFloat = 80,
                                              rotation: CGFloat = 180,
                                              textInside: Bool = true,
                                              text: String = "Hello World!") -> UIImage {
    renderedImage(
      from: curvedTextLabel(radius: radius,
                            rotation: rotation,
                            textInside: textInside,
                            text: text)
    )
  }

  @MainActor
  private static func curvedTextLabel(radius: CGFloat = 80,
                                      rotation: CGFloat = 180,
                                      textInside: Bool = true,
                                      text: String = "Hello World!") -> CurvedLabel {
    let label = CurvedLabel(frame: CGRect(x: 0, y: 0, width: 240, height: 240))
    label.backgroundColor = .clear
    label.radius = radius
    label.rotation = rotation
    label.textInside = textInside
    label.attributedText = NSAttributedString(
      string: text,
      attributes: [
        .font: UIFont.systemFont(ofSize: 28),
        .foregroundColor: UIColor.black
      ]
    )

    return label
  }

  @MainActor
  private static func renderedImage(from view: UIView) -> UIImage {
    UIGraphicsImageRenderer(size: view.bounds.size).image { _ in
      view.draw(view.bounds)
    }
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
  var rgbaPixels: [UInt8]? {
    guard let cgImage else { return nil }

    let width = cgImage.width
    let height = cgImage.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let didDraw = pixels.withUnsafeMutableBytes { buffer in
      guard let baseAddress = buffer.baseAddress,
            let context = CGContext(
              data: baseAddress,
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
      return true
    }

    guard didDraw else {
      return nil
    }

    return pixels
  }

  var hasVisiblePixels: Bool {
    guard let pixels = rgbaPixels else { return false }

    return stride(from: 3, to: pixels.count, by: 4).contains { pixels[$0] > 0 }
  }

  func differsVisibly(from image: UIImage,
                      channelTolerance: UInt8 = 8,
                      minimumDifferingPixels: Int = 32) -> Bool {
    guard let lhs = rgbaPixels,
          let rhs = image.rgbaPixels else {
      Issue.record("Unable to extract RGBA pixels for image comparison.")
      return false
    }
    guard lhs.count == rhs.count else { return true }

    let tolerance = Int(channelTolerance)
    var differingPixels = 0
    for offset in stride(from: 0, to: lhs.count, by: 4) {
      let differs = Swift.abs(Int(lhs[offset]) - Int(rhs[offset])) > tolerance
        || Swift.abs(Int(lhs[offset + 1]) - Int(rhs[offset + 1])) > tolerance
        || Swift.abs(Int(lhs[offset + 2]) - Int(rhs[offset + 2])) > tolerance
        || Swift.abs(Int(lhs[offset + 3]) - Int(rhs[offset + 3])) > tolerance

      if differs {
        differingPixels += 1
      }

      if differingPixels >= minimumDifferingPixels {
        return true
      }
    }

    return false
  }
}
#endif

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
#endif
}

private extension CGFloat {
  func isApproximatelyEqual(to other: CGFloat, tolerance: CGFloat = 0.0001) -> Bool {
    Swift.abs(self - other) <= tolerance
  }
}

import CoreGraphics
import CoreText

struct CurvedLabelGlyphArcInfo: Equatable {
  var width: CGFloat
  var angle: CGFloat
}

enum CurvedLabelGlyphArcCalculator {
  static func arcInfo(for line: CTLine, radius: CGFloat) -> [CurvedLabelGlyphArcInfo] {
    let glyphWidths = glyphWidths(in: line)
    return arcInfo(forGlyphWidths: glyphWidths, radius: radius)
  }

  static func arcInfo(forGlyphWidths glyphWidths: [CGFloat],
                      radius: CGFloat) -> [CurvedLabelGlyphArcInfo] {
    guard radius > 0.0, !glyphWidths.isEmpty else { return [] }

    var glyphArcInfo = glyphWidths.map {
      CurvedLabelGlyphArcInfo(width: $0, angle: 0.0)
    }

    let circumference = radius * 2.0 * CGFloat.pi
    let compensatingSpacingFactor = spacingFactor(for: radius)

    var previousHalfWidth = glyphArcInfo[0].width / 2.0
    glyphArcInfo[0].angle = angle(for: previousHalfWidth,
                                  circumference: circumference,
                                  spacingFactor: compensatingSpacingFactor)

    var maxAngle = glyphArcInfo[0].angle

    if glyphArcInfo.count > 1 {
      for index in 1..<glyphArcInfo.count {
        let halfWidth = glyphArcInfo[index].width / 2.0
        let centerToCenterWidth = previousHalfWidth + halfWidth

        glyphArcInfo[index].angle = angle(for: centerToCenterWidth,
                                          circumference: circumference,
                                          spacingFactor: compensatingSpacingFactor)
        maxAngle += glyphArcInfo[index].angle
        previousHalfWidth = halfWidth
      }
    }

    glyphArcInfo[0].angle += (CGFloat.pi - maxAngle) / 2.0

    return glyphArcInfo
  }

  private static func glyphWidths(in line: CTLine) -> [CGFloat] {
    let runArray = CTLineGetGlyphRuns(line)
    let runCount = CFArrayGetCount(runArray)
    var glyphWidths: [CGFloat] = []

    for runIndex in 0..<runCount {
      let run = unsafeBitCast(
        CFArrayGetValueAtIndex(runArray, runIndex),
        to: CTRun.self
      )
      let runGlyphCount = CTRunGetGlyphCount(run)

      for runGlyphIndex in 0..<runGlyphCount {
        let glyphRange = CFRange(location: runGlyphIndex, length: 1)
        let width = CGFloat(
          CTRunGetTypographicBounds(
            run,
            glyphRange,
            nil,
            nil,
            nil
          )
        )
        glyphWidths.append(width)
      }
    }

    return glyphWidths
  }

  private static func spacingFactor(for radius: CGFloat) -> CGFloat {
    radius < 50.0 ? 1.0 + (1.0 - radius / 50.0) / 2.0 : 1.0
  }

  private static func angle(for width: CGFloat,
                            circumference: CGFloat,
                            spacingFactor: CGFloat) -> CGFloat {
    (width / circumference) * spacingFactor * CGFloat.pi * 2.0
  }
}

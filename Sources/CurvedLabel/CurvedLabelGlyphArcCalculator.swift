//
//  CurvedLabelGlyphArcCalculator.swift
//  CurvedLabel
//
//  Created by Gorani on 2026/06/29.
//  Copyright © 2026 Gorani. All rights reserved.
//

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

  static func glyphCount(in runs: [CTRun]) -> Int {
    runs.reduce(0) { $0 + CTRunGetGlyphCount($1) }
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

    let trailingHalfWidth = glyphArcInfo[glyphArcInfo.count - 1].width / 2.0
    maxAngle += angle(for: trailingHalfWidth,
                      circumference: circumference,
                      spacingFactor: compensatingSpacingFactor)

    glyphArcInfo[0].angle += (CGFloat.pi - maxAngle) / 2.0

    return glyphArcInfo
  }

  static func glyphWidths(in line: CTLine) -> [CGFloat] {
    guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return [] }
    return runs.flatMap { glyphWidths(in: $0) }
  }

  private static func glyphWidths(in run: CTRun) -> [CGFloat] {
    let glyphCount = CTRunGetGlyphCount(run)
    guard glyphCount > 0 else { return [] }

    if let advances = CTRunGetAdvancesPtr(run) {
      return (0..<glyphCount).map { Swift.abs(advances[$0].width) }
    }

    var advances = [CGSize](repeating: .zero, count: glyphCount)
    advances.withUnsafeMutableBufferPointer { buffer in
      guard let baseAddress = buffer.baseAddress else { return }

      CTRunGetAdvances(
        run,
        CFRange(location: 0, length: glyphCount),
        baseAddress
      )
    }

    return advances.map { Swift.abs($0.width) }
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

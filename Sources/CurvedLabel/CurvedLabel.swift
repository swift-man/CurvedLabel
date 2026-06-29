//
//  CurvedLabel.swift
//  CurvedLabel
//
//  Created by Gorani on 2026/06/29.
//  Copyright © 2026 Gorani. All rights reserved.
//

#if canImport(UIKit)
import CoreText
import UIKit

/// A `UILabel` subclass that draws attributed text along a circular arc.
public final class CurvedLabel: UILabel {
  public override var text: String? {
    didSet {
      guard text != oldValue else { return }
      invalidateRenderedText(needsIntrinsicSize: true)
    }
  }

  public override var attributedText: NSAttributedString? {
    didSet {
      guard !Self.immutableAttributedText(attributedText,
                                          isEqualTo: oldValue) else { return }
      invalidateRenderedText(needsIntrinsicSize: true)
    }
  }

  public override var font: UIFont! {
    didSet {
      guard font != oldValue else { return }
      invalidateRenderedText(needsIntrinsicSize: true)
    }
  }

  public override var textColor: UIColor! {
    didSet {
      guard textColor != oldValue else { return }

      if attributedText == nil {
        invalidateRenderedText(needsIntrinsicSize: false)
      } else {
        // Attributed text owns foreground attributes; the cached layout can be reused.
        setNeedsDisplay()
      }
    }
  }

  private var storedRadius: CGFloat = 0.0

  /// The radius of the circular text path, measured in points.
  ///
  /// Negative values are clamped to `0`.
  public var radius: CGFloat {
    get {
      storedRadius
    }
    set {
      let clampedRadius = Swift.max(newValue, 0.0)
      guard storedRadius != clampedRadius else {
        return
      }

      storedRadius = clampedRadius
      invalidateRenderedText(needsIntrinsicSize: true)
    }
  }

  /// The rotation offset in degrees. `0` starts text at the top of the circle.
  public var rotation: CGFloat = 0.0 {
    didSet {
      if rotation != oldValue {
        setNeedsDisplay()
      }
    }
  }

  /// Draws text inside the radius when `true`, or outside the radius when `false`.
  public var textInside: Bool = false {
    didSet {
      if textInside != oldValue {
        invalidateIntrinsicContentSize()
        setNeedsDisplay()
      }
    }
  }

  private struct LayoutCache {
    let attributedText: NSAttributedString
    let radius: CGFloat
    // Keep the line alive for the cached CoreText run references.
    let line: CTLine
    let runs: [CTRun]
    let glyphArcInfo: [CurvedLabelGlyphArcInfo]
  }

  private var cachedLayout: LayoutCache?

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public override init(frame: CGRect = .zero) {
    super.init(frame: frame)
  }

  public override var intrinsicContentSize: CGSize {
    let baseSize = super.intrinsicContentSize
    guard radius > 0.0 else { return baseSize }

    let textOutset = textInside ? 0.0 : ceil(renderedTextLineHeight)
    let diameter = ceil((radius + textOutset) * 2.0)

    return CGSize(
      width: max(baseSize.width, diameter),
      height: max(baseSize.height, diameter)
    )
  }

  public override func draw(_ rect: CGRect) {
    let radius = self.radius
    guard radius > 0.0 else {
      super.draw(rect)
      return
    }

    guard let attributedText = renderedAttributedText,
          attributedText.length > 0,
          let context = UIGraphicsGetCurrentContext() else {
      super.draw(rect)
      return
    }

    guard let layout = layout(for: attributedText, radius: radius) else {
      super.draw(rect)
      return
    }

    // arcInfo is derived from these runs today; keep the guard so future
    // calculator changes fail gracefully instead of partially rendering glyphs.
    guard layout.glyphArcInfo.count == CurvedLabelGlyphArcCalculator.glyphCount(in: layout.runs) else {
      assertionFailure("CurvedLabel glyph arc info count must match the CoreText run glyph count.")
      super.draw(rect)
      return
    }

    context.saveGState()
    defer { context.restoreGState() }

    // Setup general affine transform.
    var t0 = context.ctm
    let xScaleFactor = t0.a > 0.0 ? t0.a : -t0.a
    let yScaleFactor = t0.d > 0.0 ? t0.d : -t0.d
    t0 = t0.inverted()

    if xScaleFactor != 1.0 || yScaleFactor != 1.0 {
      t0 = t0.scaledBy(x: xScaleFactor, y: yScaleFactor)
    }

    context.concatenate(t0)
    context.textMatrix = .identity

    // Move the origin to the center of the view so the text can run around.
    context.translateBy(x: bounds.midX, y: bounds.midY)

    // Rotate the context 90 degrees counterclockwise.
    context.rotate(by: (rotation + 90.0) * (CGFloat.pi / 180.0))

    var textPosition = CGPoint(
      x: 0.0,
      y: textInside ? -radius : radius
    )
    context.textPosition = CGPoint(x: textPosition.x, y: textPosition.y)

    var glyphOffset: CFIndex = 0

    for run in layout.runs {
      let runGlyphCount = CTRunGetGlyphCount(run)
      let runTextMatrix = CTRunGetTextMatrix(run)

      for runGlyphIndex in 0..<runGlyphCount {
        let glyphRange = CFRange(location: runGlyphIndex, length: 1)
        let infoIndex = Int(runGlyphIndex + glyphOffset)

        var glyphAngle = layout.glyphArcInfo[infoIndex].angle

        if !textInside {
          glyphAngle = -glyphAngle
        }

        context.rotate(by: glyphAngle)

        // Center this glyph by moving left by half its width.
        let glyphWidth = layout.glyphArcInfo[infoIndex].width
        let halfGlyphWidth = glyphWidth / 2.0
        let positionForThisGlyph = CGPoint(
          x: textPosition.x - halfGlyphWidth,
          y: textPosition.y
        )

        // Glyphs are positioned relative to the text position for the line,
        // so offset text position leftwards by this glyph's width.
        textPosition.x -= glyphWidth

        var textMatrix = runTextMatrix
        textMatrix.tx = positionForThisGlyph.x
        textMatrix.ty = positionForThisGlyph.y
        context.textMatrix = textMatrix
        CTRunDraw(run, context, glyphRange)
      }

      glyphOffset += runGlyphCount
    }
  }

  private var renderedAttributedText: NSAttributedString? {
    if let attributedText, attributedText.length > 0 {
      return attributedText
    }

    guard let text, !text.isEmpty else { return nil }

    var attributes: [NSAttributedString.Key: Any] = [:]
    if let font {
      attributes[.font] = font
    }
    if let textColor {
      attributes[.foregroundColor] = textColor
    }

    return NSAttributedString(string: text, attributes: attributes)
  }

  private var renderedTextLineHeight: CGFloat {
    guard let renderedAttributedText,
          renderedAttributedText.length > 0 else {
      return font?.lineHeight ?? 0.0
    }

    let fullRange = NSRange(location: 0, length: renderedAttributedText.length)
    var maximumLineHeight: CGFloat = 0.0
    var attributedFontLength = 0

    renderedAttributedText.enumerateAttribute(.font, in: fullRange) { value, range, _ in
      guard let lineHeight = Self.lineHeight(for: value) else { return }

      maximumLineHeight = max(maximumLineHeight, lineHeight)
      attributedFontLength += range.length
    }

    if attributedFontLength < renderedAttributedText.length {
      maximumLineHeight = max(maximumLineHeight, font?.lineHeight ?? 0.0)
    }

    return maximumLineHeight
  }

  private static func lineHeight(for fontAttribute: Any?) -> CGFloat? {
    (fontAttribute as? UIFont)?.lineHeight
  }

  private static func immutableAttributedText(_ lhs: NSAttributedString?,
                                              isEqualTo rhs: NSAttributedString?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
      return true
    case let (lhs?, rhs?):
      // Mutable attributed strings can change in place between assignments.
      guard !(lhs is NSMutableAttributedString),
            !(rhs is NSMutableAttributedString) else {
        return false
      }

      return lhs.isEqual(to: rhs)
    default:
      return false
    }
  }

  private func layout(for attributedText: NSAttributedString, radius: CGFloat) -> LayoutCache? {
    if let cachedLayout,
       cachedLayout.radius == radius,
       cachedLayout.attributedText.isEqual(to: attributedText) {
      return cachedLayout
    }

    let line = CTLineCreateWithAttributedString(attributedText as CFAttributedString)
    let glyphArcInfo = CurvedLabelGlyphArcCalculator.arcInfo(for: line, radius: radius)
    guard !glyphArcInfo.isEmpty,
          let runs = CTLineGetGlyphRuns(line) as? [CTRun],
          !runs.isEmpty else {
      cachedLayout = nil
      return nil
    }

    let layout = LayoutCache(
      attributedText: attributedText.copy() as? NSAttributedString ?? attributedText,
      radius: radius,
      line: line,
      runs: runs,
      glyphArcInfo: glyphArcInfo
    )
    cachedLayout = layout

    return layout
  }

  private func invalidateRenderedText(needsIntrinsicSize: Bool) {
    cachedLayout = nil
    if needsIntrinsicSize {
      invalidateIntrinsicContentSize()
    }
    setNeedsDisplay()
  }
}
#endif

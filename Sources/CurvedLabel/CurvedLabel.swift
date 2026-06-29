#if canImport(UIKit)
import CoreText
import UIKit

/// A `UILabel` subclass that draws attributed text along a circular arc.
public final class CurvedLabel: UILabel {
  /// The radius of the circular text path, measured in points.
  ///
  /// Negative values are clamped to `0`.
  public var radius: CGFloat = 0.0 {
    didSet {
      if radius < 0.0 {
        radius = 0.0
      }
      if radius != oldValue {
        invalidateIntrinsicContentSize()
        setNeedsDisplay()
      }
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
        setNeedsDisplay()
      }
    }
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public override init(frame: CGRect = .zero) {
    super.init(frame: frame)
  }

  public override var intrinsicContentSize: CGSize {
    let baseSize = super.intrinsicContentSize
    let diameter = ceil(radius * 2.0)
    guard diameter > 0.0 else { return baseSize }

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

    let attributedStringRef = attributedText as CFAttributedString
    let line = CTLineCreateWithAttributedString(attributedStringRef)
    let glyphArcInfo = CurvedLabelGlyphArcCalculator.arcInfo(for: line, radius: radius)
    guard !glyphArcInfo.isEmpty,
          let runs = CTLineGetGlyphRuns(line) as? [CTRun],
          !runs.isEmpty else {
      super.draw(rect)
      return
    }
    guard glyphArcInfo.count == CurvedLabelGlyphArcCalculator.glyphCount(in: runs) else {
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

    for run in runs {
      let runGlyphCount = CTRunGetGlyphCount(run)

      for runGlyphIndex in 0..<runGlyphCount {
        let glyphRange = CFRange(location: runGlyphIndex, length: 1)
        let infoIndex = Int(runGlyphIndex + glyphOffset)
        guard infoIndex < glyphArcInfo.count else {
          assertionFailure("CurvedLabel glyph arc info index is out of range.")
          return
        }

        var glyphAngle = glyphArcInfo[infoIndex].angle

        if !textInside {
          glyphAngle = -glyphAngle
        }

        context.rotate(by: glyphAngle)

        // Center this glyph by moving left by half its width.
        let glyphWidth = glyphArcInfo[infoIndex].width
        let halfGlyphWidth = glyphWidth / 2.0
        let positionForThisGlyph = CGPoint(
          x: textPosition.x - halfGlyphWidth,
          y: textPosition.y
        )

        // Glyphs are positioned relative to the text position for the line,
        // so offset text position leftwards by this glyph's width.
        textPosition.x -= glyphWidth

        var textMatrix = CTRunGetTextMatrix(run)
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
}
#endif

# ``CurvedLabel``

Draw attributed UIKit text along a circular path.

## Overview

Use `CurvedLabel` when a `UILabel` needs to render text around a circle, such
as badges, dials, stickers, or decorative controls. The label uses its
`attributedText` when present and falls back to `text`, `font`, and `textColor`
for plain string rendering.

`radius` defines the circular path and is clamped to `0` when a negative value
is assigned. When `radius` is greater than `0`, Auto Layout uses at least the
circle diameter for `intrinsicContentSize`, plus the rendered text's line height
when text is drawn outside the circle. `rotation` offsets the path in degrees,
and `textInside` chooses whether glyphs sit inside or outside the circle.

When `attributedText` is set, its font and foreground color attributes drive
rendering. `font` and `textColor` are used for plain `text` fallback and for
attributed ranges that omit a font.

## Installation

Add CurvedLabel to your Swift package dependencies.

```swift
dependencies: [
  .package(url: "https://github.com/swift-man/CurvedLabel.git", from: "1.0.0")
]
```

## Basic Usage

```swift
import UIKit
import CurvedLabel

let label = CurvedLabel()
label.frame = CGRect(x: 0, y: 0, width: 300, height: 300)

label.textColor = .black
label.radius = 120
label.rotation = 180
label.textInside = true
label.attributedText = NSAttributedString(
  string: "Hello World!",
  attributes: [
    .foregroundColor: UIColor.black
  ]
)
```

## Topics

### Views

- ``CurvedLabel``

# CurvedLabel

UIKit label for drawing attributed text along a circular path.

![Badge](https://img.shields.io/badge/Swift-6.0%2B-F05138?style=flat-square&logo=Swift&logoColor=white)
![Badge](https://img.shields.io/badge/UIKit-2396F3.svg?style=flat-square&logo=Apple&logoColor=white)
![Badge - Version](https://img.shields.io/badge/Version-1.0.0-1177AA?style=flat-square)
![Badge - Swift Package Manager](https://img.shields.io/badge/SPM-compatible-orange?style=flat-square)
![Badge - Platform](https://img.shields.io/badge/platform-ios_15|tvos_15-yellow?style=flat-square)
![Badge - License](https://img.shields.io/badge/license-MIT-black?style=flat-square)

---

## Example

![CurvedLabel example](Resources/example.png)

## Usage

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

`radius` controls the circular path in points and is clamped to `0` when a
negative value is assigned. When `radius` is greater than `0`, Auto Layout uses
at least the circle diameter for `intrinsicContentSize`, plus the label font's
line height when text is drawn outside the circle. `rotation` is measured in
degrees, and `textInside` switches the glyphs to the inner side of the circle.

## Documentation

- [DocC Documentation](https://docs.gorani.me/CurvedLabel/documentation/curvedlabel/)

## Installation

### Swift Package Manager

Add CurvedLabel to your package dependencies.

```swift
dependencies: [
  .package(url: "https://github.com/swift-man/CurvedLabel.git", from: "1.0.0")
]
```

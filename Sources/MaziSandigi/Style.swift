import AppKit

func color(_ hex: UInt32) -> NSColor {
  NSColor(
    srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
    blue: CGFloat(hex & 255) / 255, alpha: 1)
}
enum Ink {
  static let paper = color(0xF8F1E4), card = color(0xFFFCF4), dark = color(0x352A25),
    muted = color(0x7B6C5C), red = color(0xA34D37), sage = color(0x496350), line = color(0xDCCDB8),
    pale = color(0xEEE3CF)
  static func serif(_ size: CGFloat) -> NSFont {
    NSFont(name: "Baskerville", size: size) ?? NSFont.systemFont(ofSize: size, weight: .semibold)
  }
}
class PaperView: NSView {
  var fill: NSColor
  var radius: CGFloat
  var border: NSColor?
  override var isFlipped: Bool { true }
  init(
    _ frame: NSRect = .zero, fill: NSColor = Ink.card, radius: CGFloat = 14,
    border: NSColor? = Ink.line
  ) {
    self.fill = fill
    self.radius = radius
    self.border = border
    super.init(frame: frame)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) unsupported") }
  override func draw(_ dirtyRect: NSRect) {
    let path = NSBezierPath(
      roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let border = border {
      border.setStroke()
      path.lineWidth = 1
      path.stroke()
    }
  }
}
@discardableResult func label(
  _ text: String, _ frame: NSRect, on view: NSView, size: CGFloat = 14, color: NSColor = Ink.dark,
  serif: Bool = false, bold: Bool = false
) -> NSTextField {
  let field = NSTextField(wrappingLabelWithString: text)
  field.frame = frame
  field.font =
    serif ? Ink.serif(size) : NSFont.systemFont(ofSize: size, weight: bold ? .semibold : .regular)
  field.textColor = color
  field.isSelectable = true
  field.maximumNumberOfLines = 0
  field.lineBreakMode = .byWordWrapping
  view.addSubview(field)
  return field
}
@discardableResult func button(
  _ text: String, _ frame: NSRect, on view: NSView, target: AnyObject?, action: Selector?,
  tag: Int = 0, primary: Bool = false, dark: Bool = false
) -> NSButton {
  let b = NSButton(title: text, target: target, action: action)
  b.frame = frame
  b.tag = tag
  b.bezelStyle = .rounded
  b.isBordered = false
  b.wantsLayer = true
  b.layer?.cornerRadius = 7
  b.layer?.backgroundColor = (primary ? Ink.red : dark ? color(0x514239) : Ink.pale).cgColor
  b.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
  b.contentTintColor = primary || dark ? Ink.card : Ink.dark
  b.setAccessibilityLabel(text)
  view.addSubview(b)
  return b
}
func symbol(_ name: String, _ frame: NSRect, on view: NSView, tint: NSColor = Ink.red) {
  let image = NSImageView(frame: frame)
  image.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
  image.contentTintColor = tint
  image.imageScaling = .scaleProportionallyUpOrDown
  view.addSubview(image)
}
func resourceURL(_ name: String) -> URL? {
  if let bundled = Bundle.main.url(forResource: name, withExtension: nil) { return bundled }
  let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(
    "Resources/\(name)")
  return FileManager.default.fileExists(atPath: cwd.path) ? cwd : nil
}
func alert(_ title: String, _ detail: String, window: NSWindow?) {
  let a = NSAlert()
  a.messageText = title
  a.informativeText = detail
  a.addButton(withTitle: "Tamam")
  if let window = window { a.beginSheetModal(for: window) } else { a.runModal() }
}
func confirm(_ title: String, _ detail: String, button: String = "Devam et") -> Bool {
  let a = NSAlert()
  a.messageText = title
  a.informativeText = detail
  a.addButton(withTitle: button)
  a.addButton(withTitle: "Vazgeç")
  return a.runModal() == .alertFirstButtonReturn
}
func savePNG(_ view: NSView, to url: URL) throws {
  view.layoutSubtreeIfNeeded()
  guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
    throw NSError(domain: "MaziRender", code: 1)
  }
  view.cacheDisplay(in: view.bounds, to: rep)
  guard let data = rep.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "MaziRender", code: 2)
  }
  try data.write(to: url, options: .atomic)
}
final class RoomView: PaperView {
  var onSelect: ((String) -> Void)?
  let image: NSImage?
  private var hotspots: [(NSButton, CGFloat, CGFloat)] = []
  init(frame: NSRect) {
    image = resourceURL("salon.png").flatMap { NSImage(contentsOf: $0) }
    super.init(frame, fill: Ink.pale, radius: 14, border: nil)
    for (id, title, x, y) in [
      ("tea", "Çay", 0.44, 0.60), ("television", "Televizyon", 0.84, 0.40),
      ("cassette", "Kaset", 0.14, 0.68), ("cologne", "Kolonya", 0.54, 0.56),
    ] {
      let b = button("+ \(title)", .zero, on: self, target: self, action: #selector(tap(_:)))
      b.identifier = NSUserInterfaceItemIdentifier(id)
      hotspots.append((b, x, y))
    }
    setAccessibilityLabel(
      "Çay, televizyon, kaset ve kolonya hatıra durakları bulunan resimli salon.")
  }
  required init?(coder: NSCoder) { fatalError() }
  override func layout() {
    super.layout()
    for (b, x, y) in hotspots {
      b.frame = NSRect(x: bounds.width * x - 48, y: bounds.height * y - 14, width: 100, height: 29)
    }
  }
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    guard let image = image else { return }
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14).addClip()
    image.draw(
      in: bounds, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil
    )
    NSGraphicsContext.restoreGraphicsState()
  }
  @objc private func tap(_ sender: NSButton) {
    if let id = sender.identifier?.rawValue { onSelect?(id) }
  }
}

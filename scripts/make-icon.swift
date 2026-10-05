import AppKit

let url = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
let names = [
  ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
  ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
  ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, pixels) in names {
  let size = CGFloat(pixels)
  let image = NSImage(size: NSSize(width: size, height: size))
  image.lockFocus()
  NSGraphicsContext.current?.imageInterpolation = .high
  let bg = NSBezierPath(
    roundedRect: NSRect(x: size * 0.05, y: size * 0.05, width: size * 0.9, height: size * 0.9),
    xRadius: size * 0.2, yRadius: size * 0.2)
  NSColor(srgbRed: 0.22, green: 0.17, blue: 0.14, alpha: 1).setFill()
  bg.fill()
  let base = NSBezierPath(
    roundedRect: NSRect(x: size * 0.2, y: size * 0.27, width: size * 0.6, height: size * 0.39),
    xRadius: size * 0.04, yRadius: size * 0.04)
  NSColor(srgbRed: 0.75, green: 0.40, blue: 0.26, alpha: 1).setFill()
  base.fill()
  let lid = NSBezierPath(
    roundedRect: NSRect(x: size * 0.18, y: size * 0.59, width: size * 0.64, height: size * 0.15),
    xRadius: size * 0.04, yRadius: size * 0.04)
  NSColor(srgbRed: 0.88, green: 0.66, blue: 0.41, alpha: 1).setFill()
  lid.fill()
  NSColor(srgbRed: 0.99, green: 0.91, blue: 0.72, alpha: 1).setFill()
  NSBezierPath(
    roundedRect: NSRect(x: size * 0.455, y: size * 0.48, width: size * 0.09, height: size * 0.14),
    xRadius: size * 0.018, yRadius: size * 0.018
  ).fill()
  for x in [0.30, 0.65] {
    NSBezierPath(
      rect: NSRect(x: size * x, y: size * 0.29, width: size * 0.045, height: size * 0.28)
    ).fill()
  }
  image.unlockFocus()
  let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
  let png = rep.representation(using: .png, properties: [:])!
  try png.write(to: url.appendingPathComponent(name + ".png"))
}

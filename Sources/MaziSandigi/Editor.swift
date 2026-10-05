import AppKit
import ImageIO
import MaziCore

final class MemoryEditor: NSWindowController, NSWindowDelegate {
  let original: Memory
  var onSave: ((Memory) -> Bool)?
  var photo: Data? { didSet { updatePhoto() } }
  let titleField = NSTextField(), yearField = NSTextField(), placeField = NSTextField(),
    peopleField = NSTextField()
  let bodyField = NSTextView(), doorPopup = NSPopUpButton(), photoView = NSImageView()
  private var parent: NSWindow?
  private var saving = false
  init(memory: Memory, parent: NSWindow?) {
    original = memory
    photo = memory.photo
    self.parent = parent
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 720, height: 710), styleMask: [.titled, .closable],
      backing: .buffered, defer: false)
    window.title = "Hatıranı deftere bırak"
    window.appearance = NSAppearance(named: .aqua)
    super.init(window: window)
    window.delegate = self
    let root = PaperView(
      NSRect(x: 0, y: 0, width: 720, height: 710), fill: Ink.paper, radius: 0, border: nil)
    window.contentView = root
    label(
      "Bir gün, bir yer, bir ses.", NSRect(x: 28, y: 22, width: 650, height: 38), on: root,
      size: 28, serif: true)
    label(
      "Yılı bilmiyorsan boş bırak. Hikâyenin kendi sesi kalsın.",
      NSRect(x: 28, y: 64, width: 660, height: 25), on: root, size: 13, color: Ink.muted)
    func field(_ name: String, _ input: NSTextField, _ frame: NSRect, _ value: String) {
      label(
        name, NSRect(x: frame.minX, y: frame.minY - 23, width: frame.width, height: 20), on: root,
        size: 12, bold: true)
      input.frame = frame
      input.stringValue = value
      input.font = NSFont.systemFont(ofSize: 14)
      input.isBezeled = false
      input.isBordered = false
      input.drawsBackground = true
      input.wantsLayer = true
      input.layer?.backgroundColor = Ink.card.cgColor
      input.layer?.cornerRadius = 5
      input.layer?.borderWidth = 1
      input.layer?.borderColor = Ink.line.cgColor
      input.backgroundColor = Ink.card
      input.textColor = Ink.dark
      input.setAccessibilityLabel(name)
      root.addSubview(input)
    }
    field("Başlık", titleField, NSRect(x: 28, y: 119, width: 506, height: 32), memory.title)
    field(
      "Yaklaşık yıl", yearField, NSRect(x: 550, y: 119, width: 140, height: 32),
      memory.year.map(String.init) ?? "")
    field("Yer / şehir", placeField, NSRect(x: 28, y: 188, width: 325, height: 32), memory.place)
    field(
      "Kimler vardı?", peopleField, NSRect(x: 370, y: 188, width: 320, height: 32), memory.people)
    label(
      "Hatıra durağı", NSRect(x: 28, y: 237, width: 650, height: 20), on: root, size: 12, bold: true
    )
    doorPopup.frame = NSRect(x: 28, y: 261, width: 662, height: 30)
    doorPopup.addItems(withTitles: Catalog.doors.map { "\($0.theme.title) / \($0.title)" })
    doorPopup.selectItem(at: Catalog.doors.firstIndex { $0.id == memory.doorID } ?? 0)
    doorPopup.setAccessibilityLabel("Hatıra durağı")
    root.addSubview(doorPopup)
    label("Hikâyen", NSRect(x: 28, y: 308, width: 500, height: 21), on: root, size: 12, bold: true)
    let scroll = NSScrollView(frame: NSRect(x: 28, y: 333, width: 506, height: 248))
    scroll.hasVerticalScroller = true
    scroll.borderType = .bezelBorder
    bodyField.isRichText = false
    bodyField.allowsUndo = true
    bodyField.string = memory.body
    bodyField.font = Ink.serif(18)
    bodyField.textColor = Ink.dark
    bodyField.backgroundColor = Ink.card
    bodyField.isVerticallyResizable = true
    bodyField.isHorizontallyResizable = false
    bodyField.autoresizingMask = [.width]
    bodyField.textContainerInset = NSSize(width: 12, height: 12)
    bodyField.textContainer?.widthTracksTextView = true
    bodyField.frame = NSRect(x: 0, y: 0, width: 506, height: 248)
    bodyField.setAccessibilityLabel("Hikâyen")
    scroll.documentView = bodyField
    root.addSubview(scroll)
    photoView.frame = NSRect(x: 550, y: 333, width: 140, height: 140)
    photoView.imageScaling = .scaleProportionallyUpOrDown
    photoView.wantsLayer = true
    photoView.layer?.backgroundColor = Ink.pale.cgColor
    root.addSubview(photoView)
    updatePhoto()
    button(
      "Fotoğraf ekle", NSRect(x: 550, y: 486, width: 140, height: 30), on: root, target: self,
      action: #selector(choosePhoto))
    button(
      "Fotoğrafı kaldır", NSRect(x: 550, y: 524, width: 140, height: 28), on: root, target: self,
      action: #selector(removePhoto))
    label(
      "Fotoğrafın kopyası deftere eklenir. Asıl dosya değişmez.",
      NSRect(x: 550, y: 563, width: 140, height: 70), on: root, size: 11, color: Ink.muted)
    label(
      "Bu defter bu Mac'te saklanır. Arşiv yedeği fotoğrafları da içerir.",
      NSRect(x: 28, y: 600, width: 506, height: 40), on: root, size: 12, color: Ink.muted)
    button(
      "Vazgeç", NSRect(x: 410, y: 661, width: 120, height: 32), on: root, target: self,
      action: #selector(cancel))
    let save = button(
      "Deftere kaydet", NSRect(x: 550, y: 661, width: 140, height: 32), on: root, target: self,
      action: #selector(saveMemory), primary: true)
    save.keyEquivalent = "\r"
  }
  required init?(coder: NSCoder) { fatalError() }
  func present() {
    if let window = window, let parent = parent {
      parent.beginSheet(window)
    } else {
      showWindow(nil)
    }
    window?.makeFirstResponder(titleField)
  }
  func draft() throws -> Memory {
    var m = original
    m.title = titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    m.body = bodyField.string.trimmingCharacters(in: .whitespacesAndNewlines)
    m.place = placeField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    m.people = peopleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    let year = yearField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    if !year.isEmpty && Int(year) == nil {
      throw ArchiveError.invalid("Yılı tam sayı olarak yaz veya boş bırak.")
    }
    m.year = year.isEmpty ? nil : Int(year)
    m.doorID = Catalog.doors[max(0, doorPopup.indexOfSelectedItem)].id
    m.photo = photo
    _ = try Archive(memories: [m]).validated()
    return m
  }
  private var dirty: Bool {
    titleField.stringValue != original.title || bodyField.string != original.body
      || yearField.stringValue != (original.year.map(String.init) ?? "")
      || placeField.stringValue != original.place || peopleField.stringValue != original.people
      || photo != original.photo
      || Catalog.doors[max(0, doorPopup.indexOfSelectedItem)].id != original.doorID
  }
  @objc func saveMemory() {
    do {
      var m = try draft()
      m.updatedAt = Date()
      if onSave?(m) == true {
        saving = true
        dismiss()
      }
    } catch { alert("Hatıra kaydedilemedi", error.localizedDescription, window: window) }
  }
  @objc func cancel() {
    if !dirty
      || confirm(
        "Yazdıkların kaydedilmedi", "Bu hatıradaki değişikliklerden vazgeçmek istiyor musun?",
        button: "Değişikliklerden vazgeç")
    {
      dismiss()
    }
  }
  private func dismiss() {
    if let window = window, let parent = parent { parent.endSheet(window) }
    window?.orderOut(nil)
    close()
  }
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if saving { return true }
    if dirty
      && !confirm(
        "Kaydedilmemiş hatıra", "Pencereyi kapatırsan değişiklikler kaybolacak.", button: "Kapat")
    {
      return false
    }
    if let parent = parent { parent.endSheet(sender) }
    return true
  }
  @objc private func choosePhoto() {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["jpg", "jpeg", "png", "heic", "tiff"]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      photo = try Self.preparePhoto(url)
      updatePhoto()
    } catch { alert("Fotoğraf açılamadı", error.localizedDescription, window: window) }
  }
  @objc private func removePhoto() {
    photo = nil
    updatePhoto()
  }
  private func updatePhoto() { photoView.image = photo.flatMap { NSImage(data: $0) } }
  static func validPhoto(_ data: Data) -> Bool {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      let p = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let w = p[kCGImagePropertyPixelWidth] as? Int, let h = p[kCGImagePropertyPixelHeight] as? Int,
      w > 0, h > 0, w <= 1600, h <= 1600
    else { return false }
    return CGImageSourceCreateImageAtIndex(source, 0, nil) != nil
  }
  static func preparePhoto(_ url: URL) throws -> Data {
    let size =
      (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue
      ?? Int.max
    guard size <= 20_000_000, let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = props[kCGImagePropertyPixelWidth] as? Int,
      let height = props[kCGImagePropertyPixelHeight] as? Int,
      width > 0, height > 0, Double(width) * Double(height) <= 40_000_000
    else { throw ArchiveError.invalid("20 MB ve 40 megapikselden küçük bir görsel seç.") }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 1600,
      kCGImageSourceCreateThumbnailWithTransform: true,
    ]
    guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
      let data = NSBitmapImageRep(cgImage: cg).representation(
        using: .jpeg, properties: [.compressionFactor: 0.82]), data.count <= 2_000_000
    else {
      throw ArchiveError.invalid("Bu fotoğraf dönüştürülemedi. Daha küçük bir JPEG veya PNG dene.")
    }
    return data
  }
}

import AppKit
import MaziCore

final class PostcardView: PaperView {
  init(memory: Memory) {
    super.init(
      NSRect(x: 0, y: 0, width: 760, height: 1000), fill: Ink.paper, radius: 0, border: nil)
    label(
      "MAZİ SANDIĞI / KİŞİSEL HATIRA", NSRect(x: 42, y: 36, width: 670, height: 25), on: self,
      size: 11, color: Ink.red, bold: true)
    let photo = NSImageView(frame: NSRect(x: 42, y: 87, width: 676, height: 392))
    photo.imageScaling = .scaleProportionallyUpOrDown
    photo.wantsLayer = true
    photo.layer?.backgroundColor = Ink.pale.cgColor
    photo.image =
      memory.photo.flatMap { NSImage(data: $0) }
      ?? resourceURL("salon.png").flatMap { NSImage(contentsOf: $0) }
    addSubview(photo)
    label(
      memory.title, NSRect(x: 42, y: 516, width: 676, height: 96), on: self, size: 34, serif: true)
    label(
      [memory.year.map(String.init) ?? "Bir zaman", memory.place, memory.people].filter {
        !$0.isEmpty
      }.joined(separator: " · "), NSRect(x: 42, y: 624, width: 676, height: 51), on: self, size: 14,
      color: Ink.muted)
    let text =
      String(memory.body.prefix(340))
      + (memory.body.count > 340 ? "…\n(Tam hikâye hatıra defterinde.)" : "")
    label(text, NSRect(x: 42, y: 697, width: 676, height: 217), on: self, size: 21, serif: true)
    label(
      "\(Catalog.door(memory.doorID)?.title ?? "") · Kişisel anlatı",
      NSRect(x: 42, y: 952, width: 676, height: 24), on: self, size: 11, color: Ink.muted)
  }
  required init?(coder: NSCoder) { fatalError() }
}
extension MaziController {
  @objc func postcardAction(_ sender: NSButton) {
    guard archive.memories.indices.contains(sender.tag) else { return }
    let memory = archive.memories[sender.tag]
    let panel = NSSavePanel()
    panel.allowedFileTypes = ["png"]
    panel.nameFieldStringValue = "Hatira-\(memory.id.uuidString.prefix(8)).png"
    panel.message = "Kartpostal kısa bir alıntı içerir. Tam metin ve fotoğraf için arşiv yedeği al."
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      let card = PostcardView(memory: memory)
      try savePNG(card, to: url)
    } catch { alert("Kartpostal çıkarılamadı", error.localizedDescription, window: window) }
  }
}

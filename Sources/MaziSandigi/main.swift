import AppKit
import MaziCore

final class AppDelegate: NSObject, NSApplicationDelegate {
  var controller: MaziController?
  func applicationDidFinishLaunching(_ notification: Notification) {
    let c = MaziController()
    controller = c
    setupMenu(c)
    c.showWindow(nil)
    c.window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    if let error = c.initialError {
      alert("Defter okunamadı", "Özgün dosya değiştirilmedi. \(error)", window: c.window)
    }
  }
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    if let editor = controller?.editor, editor.window?.isVisible == true,
      editor.windowShouldClose(editor.window!) == false
    {
      return .terminateCancel
    }
    return .terminateNow
  }
  func applicationWillTerminate(_ notification: Notification) { controller?.ambience?.stop() }
  private func setupMenu(_ c: MaziController) {
    let menu = NSMenu()
    NSApp.mainMenu = menu
    func add(_ name: String) -> NSMenu {
      let item = NSMenuItem()
      let sub = NSMenu(title: name)
      item.submenu = sub
      menu.addItem(item)
      return sub
    }
    func entry(
      _ menu: NSMenu, _ title: String, _ key: String, _ target: AnyObject, _ action: Selector
    ) {
      let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
      item.target = target
      menu.addItem(item)
    }
    let app = add("Mazi Sandığı")
    entry(app, "Mazi Sandığı hakkında", "", self, #selector(about))
    app.addItem(.separator())
    entry(app, "Mazi Sandığı'ndan çık", "q", NSApp, #selector(NSApplication.terminate(_:)))
    let file = add("Dosya")
    entry(file, "Yeni hatıra", "n", c, #selector(MaziController.newMemoryAction))
    file.addItem(.separator())
    entry(file, "Arşiv yedeği al…", "s", c, #selector(MaziController.exportArchiveAction))
    entry(file, "Bir yedek aç…", "o", c, #selector(MaziController.importArchiveAction))
    entry(file, "Yazı dosyası çıkar…", "", c, #selector(MaziController.exportMarkdownAction))
    entry(file, "Defter klasörünü göster", "", c, #selector(MaziController.showStorage))
    file.addItem(.separator())
    entry(file, "Kurmaca örnekleri ekle…", "", c, #selector(MaziController.addExamples))
    let edit = add("Düzenle")
    for (title, key, sel) in [
      ("Geri al", "z", "undo:"), ("Kes", "x", "cut:"), ("Kopyala", "c", "copy:"),
      ("Yapıştır", "v", "paste:"), ("Tümünü seç", "a", "selectAll:"),
    ] {
      edit.addItem(NSMenuItem(title: title, action: NSSelectorFromString(sel), keyEquivalent: key))
    }
    let find = NSMenuItem(title: "Defterde ara", action: #selector(findMemory), keyEquivalent: "f")
    find.target = self
    edit.addItem(find)
    let view = add("Gezin")
    for (index, title) in ["Salon", "Hatıra defteri", "Hikâye kartları", "Sokak arası"].enumerated()
    {
      let item = NSMenuItem(
        title: title, action: #selector(navigate(_:)), keyEquivalent: String(index + 1))
      item.target = self
      item.tag = index
      view.addItem(item)
    }
    entry(view, "Ortam sesini aç / kapat", "", c, #selector(MaziController.toggleSound))
    let window = add("Pencere")
    window.addItem(
      NSMenuItem(title: "Kapat", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
    NSApp.windowsMenu = window
    let help = add("Yardım")
    entry(help, "Kullanım kılavuzu ve kaynak kodu", "", self, #selector(source))
  }
  @objc private func about() {
    NSApp.orderFrontStandardAboutPanel(options: [
      .applicationName: "Mazi Sandığı", .applicationVersion: "1.0.0",
      .credits: NSAttributedString(
        string:
          "Bir eşya. Bir ses. Sana ait bir hikâye.\nMete Alp Karvan · MIT · © 2026\nÖzgün görsel, hikâye soruları ve yerel defter."
      ),
    ])
  }
  @objc private func findMemory() { controller?.focusSearch() }
  @objc private func navigate(_ sender: NSMenuItem) { controller?.showTab(sender.tag) }
  @objc private func source() {
    NSWorkspace.shared.open(URL(string: "https://github.com/metealpkarvan/mazi-sandigi")!)
  }
}
func runSmokeTest(screenshots: URL?) throws {
  let temp = FileManager.default.temporaryDirectory.appendingPathComponent(
    "mazi-smoke-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: temp) }
  func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw ArchiveError.invalid(message) }
    print("PASS \(message)")
  }
  let c = MaziController(
    store: ArchiveStore(url: temp.appendingPathComponent("hatiralar.json")), enableTimers: false)
  c.root.frame = NSRect(x: 0, y: 0, width: 1240, height: 850)
  c.layoutDesk()
  try require(c.archive.memories.isEmpty, "Empty first launch uses an isolated archive")
  try require(resourceURL("salon.png") != nil, "Bundled illustration exists")
  try require(c.ambience != nil, "Original ambient WAV decodes through AppKit")
  func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }
  func click(_ title: String) throws {
    guard
      let b = descendants(c.root).compactMap({ $0 as? NSButton }).first(where: { $0.title == title }
      ), let action = b.action
    else { throw ArchiveError.invalid("Missing button \(title)") }
    try require(NSApp.sendAction(action, to: b.target, from: b), "Native button action: \(title)")
  }
  if let screenshots = screenshots {
    try FileManager.default.createDirectory(at: screenshots, withIntermediateDirectories: true)
    try savePNG(c.root, to: screenshots.appendingPathComponent("salon.png"))
  }
  try click("+ Televizyon")
  try require(c.selectedDoor == "television", "Scene hotspot selects the correct memory door")
  c.newMemoryAction()
  guard let editor = c.editor else { throw ArchiveError.invalid("Memory sheet missing") }
  editor.titleField.stringValue = "Kurmaca örnek · Bir yaz akşamı"
  editor.yearField.stringValue = "1994"
  editor.placeField.stringValue = "Örnek mahalle"
  editor.peopleField.stringValue = "Kurmaca aile"
  editor.bodyField.string =
    "Bu bir kurmaca örnektir. Pencereyi açtık, iki bardak çay koyduk. Sokakta bir topun sesi duyuluyordu. Herkesin acele etmeden oturduğu o akşamı hatıra defterine bıraktım."
  if let url = resourceURL("salon.png") { editor.photo = try MemoryEditor.preparePhoto(url) }
  try require(
    try editor.draft().title.contains("Kurmaca"), "Memory editor validates actual field contents")
  if let screenshots = screenshots, let view = editor.window?.contentView {
    try savePNG(view, to: screenshots.appendingPathComponent("editor.png"))
  }
  editor.saveMemory()
  try require(
    c.archive.memories.count == 1 && c.archive.memories[0].photo != nil,
    "Editor save persists text and normalized photo")
  try require(try c.store.load().memories.count == 1, "Saved memory survives reopening")
  try require(
    MemoryEditor.validPhoto(c.archive.memories[0].photo!),
    "Imported photo validation checks dimensions and decoding")
  if let screenshots = screenshots {
    c.showTab(1)
    try savePNG(c.root, to: screenshots.appendingPathComponent("defter.png"))
    try savePNG(
      PostcardView(memory: c.archive.memories[0]),
      to: screenshots.appendingPathComponent("kartpostal.png"))
  }
  c.showTab(2)
  let before = c.questionIndex
  try click("Sonraki →")
  try require(
    c.questionIndex == before + 1, "Question navigation advances to another original prompt")
  if let screenshots = screenshots {
    try savePNG(c.root, to: screenshots.appendingPathComponent("hikaye.png"))
  }
  c.showTab(3)
  try click("Misketi yuvarla")
  for _ in 0..<180 { c.advanceMarble(1.0 / 60) }
  try require(c.marble.shots == 1 && !c.marble.rolling, "Native marble controls complete a throw")
  c.showHop()
  c.hideHop()
  for n in c.hop.sequence {
    let b = NSButton()
    b.tag = n
    c.hopPick(b)
  }
  try require(c.hop.level == 3, "Native hopscotch controls complete a sequence")
  c.resetMarble()
  c.resetHop()
  if let screenshots = screenshots {
    try savePNG(c.root, to: screenshots.appendingPathComponent("sokak.png"))
  }
  c.root.frame.size = NSSize(width: 1100, height: 702)
  c.layoutDesk()
  try require(
    c.scroll.frame.maxX <= c.root.bounds.width && c.search.frame.minX > 450,
    "Minimum window geometry keeps navigation and search available")
  let reloaded = MaziController(store: c.store, enableTimers: false)
  try require(
    reloaded.archive.memories.first?.title == c.archive.memories.first?.title,
    "Controller relaunch restores the archive")
  print("AppKit integration smoke test passed; no personal archive was touched.")
}
let app = NSApplication.shared
if CommandLine.arguments.contains("--smoke-test") {
  app.setActivationPolicy(.prohibited)
  var screenshots: URL?
  if let index = CommandLine.arguments.firstIndex(of: "--screenshots"),
    CommandLine.arguments.count > index + 1
  {
    screenshots = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
  }
  do {
    try runSmokeTest(screenshots: screenshots)
    exit(0)
  } catch {
    fputs("Smoke test failed: \(error)\n", stderr)
    exit(1)
  }
} else {
  app.setActivationPolicy(.regular)
  let delegate = AppDelegate()
  app.delegate = delegate
  app.run()
}

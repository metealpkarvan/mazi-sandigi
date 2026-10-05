import AppKit
import MaziCore

final class DeskRoot: PaperView {
  var onResize: (() -> Void)?
  private var oldSize = NSSize.zero
  init() {
    super.init(
      NSRect(x: 0, y: 0, width: 1240, height: 850), fill: Ink.paper, radius: 0, border: nil)
  }
  required init?(coder: NSCoder) { fatalError() }
  override func layout() {
    super.layout()
    if bounds.size != oldSize {
      oldSize = bounds.size
      onResize?()
    }
  }
}
final class MaziController: NSWindowController, NSTextFieldDelegate {
  let store: ArchiveStore
  private(set) var archive: Archive
  private(set) var readOnly = false
  let root = DeskRoot(), sidebar = PaperView(fill: Ink.dark, radius: 0, border: nil),
    scroll = NSScrollView(), search = NSTextField()
  var tab = 0, selectedDoor = "tea", theme: MemoryTheme = .home, questionTheme: MemoryTheme?,
    questionIndex = 0
  var decade: Int?, favorites = false, oldest = false
  var editor: MemoryEditor?
  let ambience = NSSound(data: AmbientAudio.wave())
  var soundOn = false
  var statusLabel: NSTextField?, audioButton: NSButton?, sidebarCount: NSTextField?
  var marble = MarbleGame(), hop = HopscotchGame(), gameView: PlaygroundView?, timer: Timer?,
    hopTimer: Timer?
  var enableTimers: Bool
  private var navButtons: [NSButton] = []
  private var lastWidth: CGFloat = 0
  var initialError: String?
  init(
    store: ArchiveStore = ArchiveStore(url: ArchiveStore.defaultURL()), enableTimers: Bool = true
  ) {
    self.store = store
    self.enableTimers = enableTimers
    do { archive = try store.load() } catch {
      archive = Archive()
      readOnly = true
      initialError = error.localizedDescription
    }
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1240, height: 850),
      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
    )
    window.title = "Mazi Sandığı"
    window.minSize = NSSize(width: 1100, height: 730)
    window.appearance = NSAppearance(named: .aqua)
    window.center()
    super.init(window: window)
    window.contentView = root
    if enableTimers { window.setFrameAutosaveName("MaziSandigiMainWindow") }
    root.addSubview(sidebar)
    buildSidebar()
    label(
      "KENDİ HİKÂYENİN EVİ", NSRect(x: 246, y: 22, width: 218, height: 20), on: root, size: 10,
      color: Ink.muted, bold: true)
    search.placeholderString = "Defterde bir isim, şehir, kelime…"
    search.font = NSFont.systemFont(ofSize: 13)
    search.delegate = self
    search.target = self
    search.action = #selector(searchChanged)
    search.isBezeled = false
    search.isBordered = false
    search.drawsBackground = true
    search.wantsLayer = true
    search.layer?.backgroundColor = Ink.card.cgColor
    search.layer?.cornerRadius = 6
    search.layer?.borderWidth = 1
    search.layer?.borderColor = Ink.line.cgColor
    search.backgroundColor = Ink.card
    search.textColor = Ink.dark
    search.setAccessibilityLabel("Hatıra defterinde ara")
    root.addSubview(search)
    audioButton = button(
      "◌ Ortam sesi", .zero, on: root, target: self, action: #selector(toggleSound))
    button(
      "+ Hatıra bırak", .zero, on: root, target: self, action: #selector(newMemoryAction), tag: 900,
      primary: true)
    scroll.drawsBackground = false
    scroll.hasVerticalScroller = true
    scroll.borderType = .noBorder
    root.addSubview(scroll)
    root.onResize = { [weak self] in self?.layoutDesk() }
    ambience?.loops = true
    ambience?.volume = 0.28
    layoutDesk()
    if enableTimers {
      timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
        self?.advanceMarble(1.0 / 60)
      }
    }
  }
  required init?(coder: NSCoder) { fatalError() }
  deinit {
    timer?.invalidate()
    hopTimer?.invalidate()
    ambience?.stop()
  }
  func layoutDesk() {
    let width = root.bounds.width
    let height = root.bounds.height
    sidebar.frame = NSRect(x: 0, y: 0, width: 214, height: height)
    search.frame = NSRect(x: width - 628, y: 14, width: 315, height: 30)
    audioButton?.frame = NSRect(x: width - 299, y: 14, width: 128, height: 30)
    root.subviews.compactMap { $0 as? NSButton }.first { $0.tag == 900 }?.frame = NSRect(
      x: width - 156, y: 14, width: 132, height: 30)
    scroll.frame = NSRect(x: 214, y: 62, width: width - 214, height: height - 62)
    if lastWidth != width || scroll.documentView == nil {
      lastWidth = width
      render()
    }
  }
  private func buildSidebar() {
    symbol(
      "shippingbox", NSRect(x: 28, y: 28, width: 42, height: 42), on: sidebar, tint: color(0xDFB889)
    )
    label(
      "Mazi\nSandığı", NSRect(x: 28, y: 83, width: 170, height: 87), on: sidebar, size: 33,
      color: Ink.paper, serif: true)
    label(
      "Bir eşya. Bir ses.\nSana ait bir hikâye.", NSRect(x: 28, y: 177, width: 160, height: 58),
      on: sidebar, size: 13, color: color(0xD8C5AC))
    for (i, title) in [
      "01   Salon", "02   Hatıra defteri", "03   Hikâye kartları", "04   Sokak arası",
    ].enumerated() {
      let b = button(
        title, NSRect(x: 18, y: 268 + CGFloat(i) * 49, width: 178, height: 40), on: sidebar,
        target: self, action: #selector(selectTab(_:)), tag: i, dark: true)
      b.alignment = .left
      navButtons.append(b)
    }
    label(
      "HATIRALARININ YERİ", NSRect(x: 28, y: 494, width: 170, height: 18), on: sidebar, size: 9,
      color: color(0xC8AC8B), bold: true)
    sidebarCount = label(
      "0 hatıra", NSRect(x: 28, y: 521, width: 160, height: 30), on: sidebar, size: 23,
      color: Ink.paper, serif: true)
    label(
      "Bu Mac'te saklanır.\nYedekle, yanında götür.", NSRect(x: 28, y: 559, width: 163, height: 45),
      on: sidebar, size: 12, color: color(0xD8C5AC))
    button(
      "Arşiv yedeği al", NSRect(x: 22, y: 622, width: 171, height: 33), on: sidebar, target: self,
      action: #selector(exportArchiveAction), dark: true)
    button(
      "Bir yedek aç", NSRect(x: 22, y: 663, width: 171, height: 31), on: sidebar, target: self,
      action: #selector(importArchiveAction), dark: true)
  }
  @objc func selectTab(_ sender: NSButton) {
    tab = sender.tag
    render(resetScroll: true)
  }
  func showTab(_ index: Int) {
    tab = index
    render(resetScroll: true)
  }
  @objc private func searchChanged() {
    tab = 1
    render(resetScroll: true)
  }
  func controlTextDidChange(_ obj: Notification) {
    if obj.object as? NSTextField === search { searchChanged() }
  }
  func focusSearch() {
    tab = 1
    render()
    window?.makeFirstResponder(search)
  }
  func render(resetScroll: Bool = false) {
    let w = scroll.contentSize.width - 48
    guard w > 400 else { return }
    let prior = resetScroll ? NSPoint.zero : scroll.contentView.bounds.origin
    let page = PaperView(
      NSRect(x: 0, y: 0, width: scroll.contentSize.width, height: 950), fill: Ink.paper, radius: 0,
      border: nil)
    let body = PaperView(
      NSRect(x: 24, y: 0, width: w, height: 900), fill: Ink.paper, radius: 0, border: nil)
    page.addSubview(body)
    switch tab {
    case 1: buildJournal(on: body, width: w)
    case 2: buildQuestions(on: body, width: w)
    case 3: buildGames(on: body, width: w)
    default: buildHome(on: body, width: w)
    }
    if readOnly {
      label(
        "Defter okunamadı; özgün dosya korunuyor. Düzenleme kapalı. Dosya menüsünden yedeğe dön.",
        NSRect(x: 24, y: body.frame.height + 10, width: w, height: 46), on: page, size: 13,
        color: Ink.red, bold: true)
    }
    page.frame.size.height = max(
      scroll.contentSize.height, body.frame.height + (readOnly ? 76 : 20))
    scroll.documentView = page
    let maxY = max(0, page.frame.height - scroll.contentSize.height)
    scroll.contentView.scroll(to: NSPoint(x: 0, y: min(prior.y, maxY)))
    scroll.reflectScrolledClipView(scroll.contentView)
    for (i, b) in navButtons.enumerated() {
      b.layer?.backgroundColor = (i == tab ? Ink.red : color(0x514239)).cgColor
      b.setAccessibilityValue(i == tab ? "Seçili" : "")
    }
    sidebarCount?.stringValue = "\(archive.memories.count) hatıra"
  }
  private func heading(_ title: String, _ detail: String, on view: NSView, width: CGFloat) {
    label(title, NSRect(x: 0, y: 16, width: width, height: 44), on: view, size: 34, serif: true)
    label(
      detail, NSRect(x: 0, y: 65, width: width, height: 41), on: view, size: 14, color: Ink.muted)
  }
  private func buildHome(on page: PaperView, width: CGFloat) {
    heading(
      "Dünkü ev, bugünkü hikâyen.",
      "Bir eşyaya dokun. Aklına gelen kişiyi, yeri veya küçücük bir günü defterine bırak.",
      on: page, width: width)
    let rw = width * 0.67
    let detailX = rw + 20
    let dw = width - rw - 20
    let room = RoomView(frame: NSRect(x: 0, y: 120, width: rw, height: max(420, rw * 2 / 3)))
    room.onSelect = { [weak self] id in
      self?.selectedDoor = id
      self?.render()
    }
    page.addSubview(room)
    let door = Catalog.door(selectedDoor) ?? Catalog.doors[0]
    let card = PaperView(NSRect(x: detailX, y: 120, width: dw, height: max(420, rw * 2 / 3)))
    page.addSubview(card)
    symbol(door.symbol, NSRect(x: 20, y: 20, width: 33, height: 33), on: card)
    label(
      "BUGÜNÜN HATIRA DURAĞI", NSRect(x: 20, y: 71, width: dw - 40, height: 31), on: card, size: 9,
      color: Ink.muted, bold: true)
    label(
      door.title, NSRect(x: 20, y: 113, width: dw - 40, height: 61), on: card, size: 25, serif: true
    )
    label(
      door.detail, NSRect(x: 20, y: 181, width: dw - 40, height: 86), on: card, size: 13,
      color: Ink.muted)
    label(
      door.questions[0], NSRect(x: 20, y: 276, width: dw - 40, height: 66), on: card, size: 15,
      serif: true)
    button(
      "Bu hatırayı yaz", NSRect(x: 20, y: card.frame.height - 50, width: dw - 40, height: 33),
      on: card, target: self, action: #selector(promptMemory), primary: true)
    let y = room.frame.maxY + 25
    label(
      "Kokusu kalan şeyler", NSRect(x: 0, y: y, width: 400, height: 32), on: page, size: 25,
      serif: true)
    let popup = NSPopUpButton(frame: NSRect(x: width - 230, y: y, width: 230, height: 30))
    popup.addItems(withTitles: MemoryTheme.allCases.map(\.title))
    popup.selectItem(at: MemoryTheme.allCases.firstIndex(of: theme) ?? 0)
    popup.target = self
    popup.action = #selector(changeTheme(_:))
    popup.setAccessibilityLabel("Hatıra duraklarının teması")
    page.addSubview(popup)
    let doors = Catalog.doors.filter { $0.theme == theme }
    let gap: CGFloat = 14
    let cw = (width - gap * 2) / 3
    for (i, d) in doors.enumerated() {
      let c = PaperView(NSRect(x: CGFloat(i) * (cw + gap), y: y + 49, width: cw, height: 150))
      page.addSubview(c)
      symbol(d.symbol, NSRect(x: 18, y: 17, width: 25, height: 25), on: c)
      label(d.title, NSRect(x: 18, y: 53, width: cw - 36, height: 32), on: c, size: 20, serif: true)
      let b = button(
        "Hatırayı aç →", NSRect(x: 18, y: 101, width: cw - 36, height: 29), on: c, target: self,
        action: #selector(selectDoor(_:)), tag: Catalog.doors.firstIndex(of: d) ?? 0)
      b.setAccessibilityLabel("\(d.title) hatıra durağını aç")
    }
    let bottom = y + 225
    label(
      "Her evin, her şehrin hatırası başka. Buradaki eşyalar bir davet; hikâyeyi sen tamamlıyorsun.",
      NSRect(x: 0, y: bottom, width: width, height: 43), on: page, size: 12, color: Ink.muted)
    label(
      "Salon: bu uygulama için üretilmiş özgün illüstrasyon.",
      NSRect(x: 0, y: bottom + 50, width: width, height: 22), on: page, size: 10, color: Ink.muted)
    page.frame.size.height = bottom + 83
  }
  @objc private func changeTheme(_ sender: NSPopUpButton) {
    theme = MemoryTheme.allCases[sender.indexOfSelectedItem]
    render()
  }
  @objc private func selectDoor(_ sender: NSButton) {
    selectedDoor = Catalog.doors[sender.tag].id
    render(resetScroll: true)
  }
  @objc private func promptMemory() {
    let d = Catalog.door(selectedDoor) ?? Catalog.doors[0]
    presentEditor(Memory(doorID: d.id), question: d.questions[0])
  }
  private func buildJournal(on page: PaperView, width: CGFloat) {
    heading(
      "Hatıra defteri",
      archive.memories.isEmpty
        ? "İlk sayfayı bir isim, bir koku veya yarım kalmış bir cümleyle aç."
        : "\(archive.memories.count) küçük hikâye. Fotoğraflarıyla, anlatan kişileriyle, senin bıraktığın gibi.",
      on: page, width: width)
    let popup = NSPopUpButton(frame: NSRect(x: 0, y: 118, width: 184, height: 30))
    popup.addItem(withTitle: "Bütün yıllar")
    let decades = Array(Set(archive.memories.compactMap { $0.year.map { $0 / 10 * 10 } })).sorted()
    popup.addItems(withTitles: decades.map { "\($0)'lar" })
    popup.selectItem(at: decade.flatMap { decades.firstIndex(of: $0).map { $0 + 1 } } ?? 0)
    popup.target = self
    popup.action = #selector(changeDecade(_:))
    popup.setAccessibilityLabel("Hatıraları on yıla göre süz")
    page.addSubview(popup)
    let fav = NSButton(
      checkboxWithTitle: "Sadece yıldızlılar", target: self, action: #selector(toggleFavorites(_:)))
    fav.state = favorites ? .on : .off
    fav.frame = NSRect(x: 203, y: 119, width: 166, height: 28)
    page.addSubview(fav)
    let sort = NSButton(
      checkboxWithTitle: "Eskiden yeniye", target: self, action: #selector(toggleSort(_:)))
    sort.state = oldest ? .on : .off
    sort.frame = NSRect(x: 383, y: 119, width: 170, height: 28)
    page.addSubview(sort)
    button(
      "Yazı dosyası çıkar", NSRect(x: width - 181, y: 118, width: 181, height: 31), on: page,
      target: self, action: #selector(exportMarkdownAction))
    let memories = archive.matching(
      query: search.stringValue, decade: decade, favorites: favorites, oldestFirst: oldest)
    if memories.isEmpty {
      let empty = PaperView(NSRect(x: 0, y: 175, width: width, height: 230))
      page.addSubview(empty)
      label(
        archive.memories.isEmpty
          ? "Bir fotoğrafın arkasına ne yazardın?" : "Bu aramada hatıra bulunamadı.",
        NSRect(x: 28, y: 33, width: width - 56, height: 42), on: empty, size: 27, serif: true)
      label(
        archive.memories.isEmpty
          ? "Salondaki bir eşyadan başlayabilir veya kendi hikâyeni doğrudan yazabilirsin."
          : "Başka bir kelime dene veya yıl / yıldız süzgecini değiştir.",
        NSRect(x: 28, y: 95, width: width - 56, height: 51), on: empty, size: 14, color: Ink.muted)
      button(
        "Yeni hatıra", NSRect(x: 28, y: 166, width: 180, height: 34), on: empty, target: self,
        action: #selector(newMemoryAction), primary: true)
      page.frame.size.height = 440
      return
    }
    let gap: CGFloat = 16
    let cw = (width - gap) / 2
    for (i, m) in memories.enumerated() {
      let c = PaperView(
        NSRect(
          x: CGFloat(i % 2) * (cw + gap), y: 175 + CGFloat(i / 2) * 236, width: cw, height: 218))
      page.addSubview(c)
      let index = archive.memories.firstIndex { $0.id == m.id } ?? 0
      let photo = NSImageView(frame: NSRect(x: 17, y: 18, width: 89, height: 92))
      photo.wantsLayer = true
      photo.layer?.backgroundColor = Ink.pale.cgColor
      photo.imageScaling = .scaleProportionallyUpOrDown
      photo.image = m.photo.flatMap { NSImage(data: $0) }
      c.addSubview(photo)
      if m.photo == nil {
        symbol(m.theme.symbol, NSRect(x: 44, y: 45, width: 35, height: 35), on: c, tint: Ink.muted)
      }
      label(
        m.title, NSRect(x: 123, y: 20, width: cw - 142, height: 54), on: c, size: 23, serif: true)
      label(
        [m.year.map(String.init) ?? "Bir zaman", m.place].filter { !$0.isEmpty }.joined(
          separator: " · "), NSRect(x: 123, y: 79, width: cw - 143, height: 29), on: c, size: 12,
        color: Ink.muted)
      let preview = m.body.replacingOccurrences(of: "\n", with: " ")
      label(
        String(preview.prefix(130)) + (preview.count > 130 ? "…" : ""),
        NSRect(x: 17, y: 124, width: cw - 34, height: 40), on: c, size: 13, color: Ink.muted)
      button(
        "Aç / düzenle", NSRect(x: 17, y: 177, width: 117, height: 28), on: c, target: self,
        action: #selector(editMemory(_:)), tag: index)
      button(
        m.favorite ? "★" : "☆", NSRect(x: 142, y: 177, width: 36, height: 28), on: c, target: self,
        action: #selector(starMemory(_:)), tag: index
      ).setAccessibilityLabel(m.favorite ? "Yıldızı kaldır" : "Hatırayı yıldızla")
      button(
        "Kartpostal", NSRect(x: 187, y: 177, width: 95, height: 28), on: c, target: self,
        action: #selector(postcardAction(_:)), tag: index)
      button(
        "Sil", NSRect(x: cw - 59, y: 177, width: 42, height: 28), on: c, target: self,
        action: #selector(deleteMemory(_:)), tag: index)
    }
    page.frame.size.height = 175 + CGFloat((memories.count + 1) / 2) * 236 + 10
  }
  @objc private func changeDecade(_ sender: NSPopUpButton) {
    let ds = Array(Set(archive.memories.compactMap { $0.year.map { $0 / 10 * 10 } })).sorted()
    decade = sender.indexOfSelectedItem == 0 ? nil : ds[sender.indexOfSelectedItem - 1]
    render()
  }
  @objc private func toggleFavorites(_ sender: NSButton) {
    favorites = sender.state == .on
    render()
  }
  @objc private func toggleSort(_ sender: NSButton) {
    oldest = sender.state == .on
    render()
  }
  @objc private func editMemory(_ sender: NSButton) {
    if archive.memories.indices.contains(sender.tag) { presentEditor(archive.memories[sender.tag]) }
  }
  @objc private func starMemory(_ sender: NSButton) {
    guard archive.memories.indices.contains(sender.tag) else { return }
    var next = archive
    next.memories[sender.tag].favorite.toggle()
    if persist(next) { render() }
  }
  @objc private func deleteMemory(_ sender: NSButton) {
    guard archive.memories.indices.contains(sender.tag) else { return }
    let m = archive.memories[sender.tag]
    if confirm(
      "\(m.title) silinsin mi?",
      "Bu hatıra ve ekli fotoğraf defterden kaldırılacak. Geri dönmek için önceden arşiv yedeği al.",
      button: "Hatırayı sil")
    {
      var next = archive
      next.remove(m.id)
      if persist(next) { render() }
    }
  }
  private func buildQuestions(on page: PaperView, width: CGFloat) {
    heading(
      "Bir sorudan açılan sandık",
      "Birlikte oturun. Tek bir soruyu seçin. Cevabı anlatanın kendi sözcükleriyle saklayın.",
      on: page, width: width)
    let popup = NSPopUpButton(frame: NSRect(x: 0, y: 118, width: 260, height: 30))
    popup.addItem(withTitle: "Bütün hikâye temaları")
    popup.addItems(withTitles: MemoryTheme.allCases.map(\.title))
    popup.selectItem(
      at: questionTheme.flatMap { MemoryTheme.allCases.firstIndex(of: $0).map { $0 + 1 } } ?? 0)
    popup.target = self
    popup.action = #selector(changeQuestionTheme(_:))
    popup.setAccessibilityLabel("Hikâye sorularının teması")
    page.addSubview(popup)
    let questions = Catalog.questions(theme: questionTheme)
    questionIndex = questionIndex % questions.count
    let (door, question) = questions[questionIndex]
    let card = PaperView(NSRect(x: 0, y: 174, width: width, height: 360))
    page.addSubview(card)
    label(
      "HİKÂYE KARTI / \(String(format:"%02d",questionIndex+1))",
      NSRect(x: 30, y: 28, width: width - 60, height: 22), on: card, size: 10, color: Ink.red,
      bold: true)
    label(
      door.theme.title, NSRect(x: 30, y: 70, width: width - 60, height: 35), on: card, size: 22,
      serif: true)
    label(
      question, NSRect(x: 30, y: 132, width: width - 60, height: 110), on: card, size: 32,
      serif: true)
    button(
      "← Önceki", NSRect(x: 30, y: 287, width: 115, height: 34), on: card, target: self,
      action: #selector(previousQuestion))
    button(
      "Sonraki →", NSRect(x: 155, y: 287, width: 115, height: 34), on: card, target: self,
      action: #selector(nextQuestion))
    button(
      "Soruyu kopyala", NSRect(x: width - 390, y: 287, width: 154, height: 34), on: card,
      target: self, action: #selector(copyQuestion))
    button(
      "Cevabı deftere yaz", NSRect(x: width - 223, y: 287, width: 192, height: 34), on: card,
      target: self, action: #selector(answerQuestion), primary: true)
    label(
      "Dinlemek için üç küçük ipucu", NSRect(x: 0, y: 566, width: width, height: 34), on: page,
      size: 24, serif: true)
    let hints = [
      ("Bir ayrıntı iste", "O gün kim vardı? Hava nasıldı? Hangi koku kalmış?"),
      (
        "İzin al, olduğu gibi bırak",
        "Kişisel bir hikâyeyi saklamadan veya paylaşmadan önce anlatana sor."
      ),
      (
        "Bir cümleyi kaybetme",
        "İsim, yer ve yaklaşık yılı not et. Hatırlanmayan boşlukları doldurmak zorunda değilsin."
      ),
    ]
    for (i, h) in hints.enumerated() {
      let cw = (width - 28) / 3
      let c = PaperView(NSRect(x: CGFloat(i) * (cw + 14), y: 618, width: cw, height: 146))
      page.addSubview(c)
      label(h.0, NSRect(x: 18, y: 18, width: cw - 36, height: 45), on: c, size: 18, serif: true)
      label(
        h.1, NSRect(x: 18, y: 70, width: cw - 36, height: 62), on: c, size: 12, color: Ink.muted)
    }
    page.frame.size.height = 792
  }
  @objc private func changeQuestionTheme(_ sender: NSPopUpButton) {
    questionTheme =
      sender.indexOfSelectedItem == 0 ? nil : MemoryTheme.allCases[sender.indexOfSelectedItem - 1]
    questionIndex = 0
    render()
  }
  @objc private func previousQuestion() {
    let count = Catalog.questions(theme: questionTheme).count
    questionIndex = (questionIndex + count - 1) % count
    render()
  }
  @objc private func nextQuestion() {
    questionIndex += 1
    render()
  }
  @objc private func copyQuestion() {
    let q = Catalog.questions(theme: questionTheme)[questionIndex].1
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(q, forType: .string)
  }
  @objc private func answerQuestion() {
    let (d, q) = Catalog.questions(theme: questionTheme)[questionIndex]
    presentEditor(Memory(doorID: d.id), question: q)
  }
  @objc func newMemoryAction() { presentEditor(Memory()) }
  func presentEditor(_ memory: Memory, question: String? = nil) {
    guard !readOnly else {
      alert(
        "Defter korunuyor", "Yeni kayıt için önce Dosya menüsünden sağlam bir yedeği aç.",
        window: window)
      return
    }
    let e = MemoryEditor(memory: memory, parent: window)
    e.onSave = { [weak self, weak e] m in
      guard let self = self else { return false }
      var next = self.archive
      do {
        try next.upsert(m)
        guard self.persist(next) else { return false }
        self.tab = 1
        self.search.stringValue = ""
        self.decade = nil
        self.favorites = false
        self.render(resetScroll: true)
        return true
      } catch {
        alert("Hatıra kaydedilemedi", error.localizedDescription, window: e?.window)
        return false
      }
    }
    editor = e
    if let question = question { e.bodyField.string = "\(question)\n\n" }
    e.present()
  }
  @discardableResult func persist(_ next: Archive) -> Bool {
    guard !readOnly else { return false }
    do {
      try store.save(next)
      archive = next
      return true
    } catch {
      alert(
        "Defter kaydedilemedi", "Değişiklik uygulanmadı. \(error.localizedDescription)",
        window: window)
      return false
    }
  }
  @objc func toggleSound() {
    if soundOn {
      ambience?.stop()
      soundOn = false
    } else {
      soundOn = ambience?.play() == true
    }
    audioButton?.title = soundOn ? "◉ Sesi kapat" : "◌ Ortam sesi"
  }
  @objc func exportArchiveAction() {
    guard exportAllowed() else { return }
    saveFile(name: "Mazi-Sandigi.mazi", types: ["mazi", "json"]) { try self.archive.encoded() }
  }
  @objc func exportMarkdownAction() {
    guard exportAllowed() else { return }
    saveFile(name: "Mazi-Sandigi.md", types: ["md"]) { Data(self.archive.markdown().utf8) }
  }
  private func exportAllowed() -> Bool {
    if readOnly {
      alert(
        "Özgün defter korunuyor",
        "Okunamayan dosya dışa aktarılamaz. Dosya menüsünden defter klasörünü açıp özgün dosyayı kopyalayabilir veya sağlam bir yedeğe dönebilirsin.",
        window: window)
      return false
    }
    return true
  }
  private func saveFile(name: String, types: [String], data: () throws -> Data) {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = name
    panel.allowedFileTypes = types
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do { try data().write(to: url, options: .atomic) } catch {
      alert("Dosya yazılamadı", error.localizedDescription, window: window)
    }
  }
  @objc func importArchiveAction() {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["mazi", "json"]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      let size =
        (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue
        ?? Int.max
      guard size <= 30_000_000 else { throw ArchiveError.invalid("Arşiv en fazla 30 MB olabilir.") }
      let imported = try Archive.decode(Data(contentsOf: url))
      guard imported.memories.allSatisfy({ $0.photo == nil || MemoryEditor.validPhoto($0.photo!) })
      else { throw ArchiveError.invalid("Arşivde okunamayan bir fotoğraf var.") }
      guard
        confirm(
          "\(imported.memories.count) hatıralı arşiv açılsın mı?",
          "Bu defterin yerini alacak. Mevcut dosya aynı klasörde ayrı bir geri dönüş kopyası olarak korunur.",
          button: "Arşivi aç")
      else { return }
      try store.restore(imported)
      archive = imported
      readOnly = false
      tab = 1
      search.stringValue = ""
      decade = nil
      favorites = false
      render(resetScroll: true)
    } catch {
      alert(
        "Arşiv açılamadı", "Mevcut defter değiştirilmedi. \(error.localizedDescription)",
        window: window)
    }
  }
  @objc func showStorage() { NSWorkspace.shared.activateFileViewerSelecting([store.url]) }
  @objc func addExamples() {
    guard !readOnly else { return }
    guard
      confirm(
        "Kurmaca örnekleri ekle",
        "İki açıkça kurmaca hatıra, kendi kayıtların silinmeden deftere eklenecek. İstersen sonradan silebilirsin.",
        button: "Örnekleri ekle")
    else { return }
    do {
      var next = archive
      for m in Self.examples { try next.upsert(m) }
      if persist(next) {
        tab = 1
        render(resetScroll: true)
      }
    } catch { alert("Örnek eklenemedi", error.localizedDescription, window: window) }
  }
  static var examples: [Memory] {
    [
      Memory(
        title: "Kurmaca örnek · Pencere önü",
        body:
          "Bu bir örnek hikâyedir. Yaz akşamında açık pencerenin önüne iki sandalye koyduk. Çay kaşığının sesiyle sokaktaki topun sesi birbirine karışıyordu. Ben o günün neden özel olduğunu yıllar sonra düşündüm.",
        year: 1993, place: "Örnek mahalle", people: "Kurmaca aile", doorID: "tea", favorite: true),
      Memory(
        title: "Kurmaca örnek · İlk sayfa",
        body:
          "Bu bir örnek hikâyedir. Yeni defterin ilk sayfasını açarken adımı çok dikkatli yazdım. Yanımdaki arkadaşım kapağın içine küçük bir güneş çizdi. O güneşi bütün yıl sakladım.",
        year: 1998, place: "Örnek okul", people: "Kurmaca arkadaş", doorID: "notebook"),
    ]
  }
}

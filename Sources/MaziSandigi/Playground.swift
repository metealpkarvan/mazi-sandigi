import AppKit
import MaziCore

final class MarbleBoard: PaperView {
  var game = MarbleGame()
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    let left: CGFloat = 28
    let right = bounds.width - 28
    let y = bounds.height * 0.58
    color(0xC3B6A0).setStroke()
    for row in 0..<5 {
      let line = NSBezierPath()
      line.move(to: NSPoint(x: 14, y: CGFloat(row) * 35 + 22))
      line.line(to: NSPoint(x: bounds.width - 14, y: CGFloat(row) * 35 + 22))
      line.lineWidth = 1
      line.stroke()
    }
    let track = NSBezierPath()
    track.move(to: NSPoint(x: left, y: y))
    track.line(to: NSPoint(x: right, y: y))
    track.lineWidth = 2
    Ink.muted.setStroke()
    track.stroke()
    let targetX = left + (right - left) * game.target
    let hole = NSBezierPath(ovalIn: NSRect(x: targetX - 18, y: y - 18, width: 36, height: 36))
    Ink.dark.setFill()
    hole.fill()
    let ring = NSBezierPath(ovalIn: NSRect(x: targetX - 27, y: y - 27, width: 54, height: 54))
    Ink.red.setStroke()
    ring.lineWidth = 2
    ring.stroke()
    let x = left + (right - left) * game.position
    let marble = NSBezierPath(ovalIn: NSRect(x: x - 11, y: y - 11, width: 22, height: 22))
    color(0x53857B).setFill()
    marble.fill()
    Ink.card.setStroke()
    marble.lineWidth = 2
    marble.stroke()
    let shine = NSBezierPath(ovalIn: NSRect(x: x - 5, y: y - 7, width: 6, height: 6))
    Ink.card.setFill()
    shine.fill()
  }
}
final class PlaygroundView: PaperView {
  let board = MarbleBoard(fill: color(0xDDD0B6), radius: 9, border: nil)
  let score = NSTextField(labelWithString: ""),
    strength = NSSlider(value: 0.74, minValue: 0, maxValue: 1, target: nil, action: nil),
    throwButton = NSButton()
  let hopLabel = NSTextField(wrappingLabelWithString: ""), hopButtons: [NSButton]
  init(frame: NSRect, controller: MaziController) {
    hopButtons = (1...9).map {
      NSButton(title: String($0), target: controller, action: #selector(MaziController.hopPick(_:)))
    }
    super.init(frame, fill: Ink.paper, radius: 0, border: nil)
    let gap: CGFloat = 20
    let cw = (frame.width - gap) / 2
    let card = PaperView(NSRect(x: 0, y: 0, width: cw, height: 550))
    addSubview(card)
    label(
      "Misket hedefi", NSRect(x: 22, y: 24, width: cw - 44, height: 38), on: card, size: 28,
      serif: true)
    label(
      "Gücü ayarla, beş atışta hedefe yaklaş. Bu bir masaüstü misket yorumu; sokakta her mahallenin kuralı başkaydı.",
      NSRect(x: 22, y: 72, width: cw - 44, height: 72), on: card, size: 13, color: Ink.muted)
    board.frame = NSRect(x: 22, y: 157, width: cw - 44, height: 174)
    card.addSubview(board)
    score.frame = NSRect(x: 22, y: 350, width: cw - 44, height: 36)
    score.font = Ink.serif(23)
    score.textColor = Ink.dark
    card.addSubview(score)
    label(
      "Atış gücü", NSRect(x: 22, y: 400, width: cw - 44, height: 23), on: card, size: 12, bold: true
    )
    strength.frame = NSRect(x: 22, y: 432, width: cw - 44, height: 25)
    strength.setAccessibilityLabel("Misket atış gücü")
    card.addSubview(strength)
    throwButton.title = "Misketi yuvarla"
    throwButton.target = controller
    throwButton.action = #selector(MaziController.throwMarble)
    throwButton.frame = NSRect(x: 22, y: 490, width: cw - 169, height: 33)
    throwButton.bezelStyle = .rounded
    card.addSubview(throwButton)
    button(
      "Yeni oyun", NSRect(x: cw - 136, y: 490, width: 114, height: 33), on: card,
      target: controller, action: #selector(MaziController.resetMarble))
    let hopCard = PaperView(NSRect(x: cw + gap, y: 0, width: cw, height: 550))
    addSubview(hopCard)
    label(
      "Seksek sırası", NSRect(x: 22, y: 24, width: cw - 44, height: 38), on: hopCard, size: 28,
      serif: true)
    label(
      "Sıra kartını üç saniye gör, gizlenince numaralara aynı sırayla bas. Her turda yol bir adım uzar.",
      NSRect(x: 22, y: 72, width: cw - 44, height: 72), on: hopCard, size: 13, color: Ink.muted)
    hopLabel.frame = NSRect(x: 22, y: 146, width: cw - 44, height: 55)
    hopLabel.font = Ink.serif(22)
    hopLabel.textColor = Ink.red
    hopCard.addSubview(hopLabel)
    let cx = cw / 2
    let size: CGFloat = 42
    let coords: [(CGFloat, CGFloat)] = [
      (cx - size / 2, 420), (cx - size / 2, 385), (cx - size / 2, 350), (cx - size - 2, 315),
      (cx + 2, 315), (cx - size / 2, 280), (cx - size - 2, 245), (cx + 2, 245),
      (cx - size / 2, 210),
    ]
    // Compact chalk path: drawn below the instruction rather than real physical hopscotch.
    let chalk = PaperView(
      NSRect(x: cx - 72, y: 204, width: 144, height: 254), fill: color(0x4B5C50), radius: 5,
      border: Ink.muted)
    hopCard.addSubview(chalk)
    for (i, b) in hopButtons.enumerated() {
      let point = coords[i]
      b.frame = NSRect(x: point.0, y: point.1, width: size, height: 31)
      b.tag = i + 1
      b.bezelStyle = .rounded
      b.isBordered = false
      b.wantsLayer = true
      b.layer?.backgroundColor = Ink.pale.cgColor
      b.layer?.cornerRadius = 3
      b.contentTintColor = Ink.dark
      b.font = Ink.serif(22)
      b.setAccessibilityLabel("Seksek \(i+1)")
      hopCard.addSubview(b)
    }
    button(
      "Sıra kartını göster", NSRect(x: 22, y: 490, width: cw - 175, height: 33), on: hopCard,
      target: controller, action: #selector(MaziController.showHop), primary: true)
    button(
      "Yeni oyun", NSRect(x: cw - 136, y: 490, width: 114, height: 33), on: hopCard,
      target: controller, action: #selector(MaziController.resetHop))
    update(controller)
  }
  required init?(coder: NSCoder) { fatalError() }
  func update(_ controller: MaziController) {
    board.game = controller.marble
    board.needsDisplay = true
    score.stringValue =
      "\(controller.marble.score) puan · \(controller.marble.shots)/5 atış"
      + (controller.marble.finished ? " · Bitti" : "")
    throwButton.isEnabled = !controller.marble.rolling && !controller.marble.finished
    strength.isEnabled = !controller.marble.rolling && !controller.marble.finished
    let hop = controller.hop
    hopLabel.stringValue =
      hop.showing
      ? hop.sequence.map(String.init).joined(separator: " → ")
      : hop.finished
        ? "Bütün yollar tamam!"
        : hop.lost
          ? "Bir adım şaştı. Yeniden deneyelim."
          : hop.ready
            ? "\(hop.entered.count)/\(hop.sequence.count) adım · Sıra sende"
            : "\(hop.level) adımlık kart hazır."
    for b in hopButtons { b.isEnabled = hop.ready && !hop.showing && !hop.lost && !hop.finished }
  }
}
extension MaziController {
  func buildGames(on page: PaperView, width: CGFloat) {
    label(
      "Sokak arası", NSRect(x: 0, y: 16, width: width, height: 44), on: page, size: 34, serif: true)
    label(
      "Avucunda bir misket, yerde tebeşir izleri. Küçük bir mola; puanlar bu oturumda kalır.",
      NSRect(x: 0, y: 65, width: width, height: 41), on: page, size: 14, color: Ink.muted)
    let games = PlaygroundView(
      frame: NSRect(x: 0, y: 122, width: width, height: 550), controller: self)
    gameView = games
    page.addSubview(games)
    label(
      "Bir oyun seni birine götürdüyse, o arkadaşın adını deftere bırak.",
      NSRect(x: 0, y: 704, width: width - 200, height: 36), on: page, size: 16, serif: true)
    button(
      "O günü yaz", NSRect(x: width - 173, y: 696, width: 173, height: 34), on: page, target: self,
      action: #selector(gameMemory), primary: true)
    page.frame.size.height = 756
  }
  @objc func throwMarble() {
    guard let gameView = gameView else { return }
    marble.throwMarble(strength: gameView.strength.doubleValue)
    gameView.update(self)
  }
  @objc func resetMarble() {
    marble = MarbleGame()
    gameView?.update(self)
  }
  func advanceMarble(_ seconds: Double) {
    if marble.rolling {
      marble.advance(seconds)
      gameView?.update(self)
    }
  }
  @objc func showHop() {
    hop.show()
    gameView?.update(self)
    hopTimer?.invalidate()
    if enableTimers && hop.showing {
      hopTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
        self?.hideHop()
      }
    }
  }
  func hideHop() {
    hop.hide()
    gameView?.update(self)
  }
  @objc func hopPick(_ sender: NSButton) {
    hop.pick(sender.tag)
    gameView?.update(self)
  }
  @objc func resetHop() {
    hopTimer?.invalidate()
    hop = HopscotchGame()
    gameView?.update(self)
  }
  @objc private func gameMemory() { presentEditor(Memory(doorID: "marble")) }
}

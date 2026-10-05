import Foundation
import MaziCore

var failures = 0
var count = 0
func expect(_ condition: Bool, _ message: String = "Assertion failed") throws {
  if !condition { throw ArchiveError.invalid(message) }
}
func rejects(_ body: () throws -> Void) throws {
  do { try body() } catch { return }
  throw ArchiveError.invalid("Expected rejection")
}
func rule(_ name: String, _ body: () throws -> Void) {
  count += 1
  do {
    try body()
    print("PASS \(name)")
  } catch {
    failures += 1
    fputs("FAIL \(name): \(error)\n", stderr)
  }
}
func memory(_ title: String = "Çay saati", year: Int? = 1993) -> Memory {
  Memory(
    title: title, body: "Isparta'da bir yaz akşamı. İki çay bardağı, bir aile hikâyesi.",
    year: year, place: "İSTANBUL", people: "Ayşe", now: Date(timeIntervalSince1970: 1_700_000_000))
}
rule("Eighteen distinct memory doors with original questions") {
  try expect(Catalog.doors.count == 18 && Set(Catalog.doors.map(\.id)).count == 18)
  try expect(Catalog.doors.allSatisfy { $0.questions.count == 2 && !$0.detail.isEmpty })
}
rule("All six themes have three doors") {
  try expect(
    MemoryTheme.allCases.allSatisfy { theme in Catalog.doors.filter { $0.theme == theme }.count == 3
    })
}
rule("Thirty-six distinct interview prompts") {
  let q = Catalog.questions(theme: nil)
  try expect(q.count == 36 && Set(q.map { $0.1 }).count == 36)
}
rule("Question theme filtering preserves the chosen theme") {
  try expect(Catalog.questions(theme: .school).allSatisfy { $0.0.theme == .school })
}
rule("Empty archive roundtrip") { try expect(try Archive.decode(Archive().encoded()) == Archive()) }
rule("Complete memory roundtrip preserves fields") {
  let a = Archive(memories: [memory()])
  try expect(try Archive.decode(a.encoded()) == a)
}
rule("Wrong archive identity rejected") {
  var a = Archive()
  a.kind = "other"
  try rejects { _ = try a.encoded() }
}
rule("Unsupported archive version rejected") {
  var a = Archive()
  a.version = 2
  try rejects { _ = try a.validated() }
}
rule("Malformed JSON rejected") { try rejects { _ = try Archive.decode(Data("broken".utf8)) } }
rule("Oversize backup rejected before decoding") {
  try rejects { _ = try Archive.decode(Data(repeating: 32, count: 30_000_001)) }
}
rule("Duplicate IDs rejected") {
  let m = memory()
  try rejects { _ = try Archive(memories: [m, m]).validated() }
}
rule("Memory count limit enforced") {
  try rejects { _ = try Archive(memories: (0..<101).map { memory("Hatıra \($0)") }).validated() }
}
rule("Blank titles rejected") {
  try rejects { _ = try Archive(memories: [memory(" ")]).validated() }
}
rule("Blank story rejected") {
  var m = memory()
  m.body = "\n "
  try rejects { _ = try Archive(memories: [m]).validated() }
}
rule("Short fields cannot contain line breaks") {
  var m = memory()
  m.place = "A\nB"
  try rejects { _ = try Archive(memories: [m]).validated() }
}
rule("Unknown memory door rejected") {
  var m = memory()
  m.doorID = "missing"
  try rejects { _ = try Archive(memories: [m]).validated() }
}
rule("Unknown year is accepted") { _ = try Archive(memories: [memory(year: nil)]).validated() }
rule("Invalid year rejected") {
  try rejects { _ = try Archive(memories: [memory(year: 1799)]).validated() }
}
rule("Overlong story rejected") {
  var m = memory()
  m.body = String(repeating: "a", count: 10001)
  try rejects { _ = try Archive(memories: [m]).validated() }
}
rule("Nonfinite record timestamp rejected") {
  var m = memory()
  m.createdAt = Date(timeIntervalSince1970: .infinity)
  try rejects { _ = try Archive(memories: [m]).validated() }
}
rule("Photo bytes must have a JPEG header") {
  var m = memory()
  m.photo = Data("not a picture".utf8)
  try rejects { _ = try Archive(memories: [m]).validated() }
}
rule("Photo size limit enforced") {
  var m = memory()
  m.photo = Data([0xFF, 0xD8, 0xFF]) + Data(repeating: 0, count: 2_000_001)
  try rejects { _ = try Archive(memories: [m]).validated() }
}
rule("Photo count limit enforced") {
  let ms = (0..<11).map { n -> Memory in
    var m = memory("\(n)")
    m.photo = Data([0xFF, 0xD8, 0xFF])
    return m
  }
  try rejects { _ = try Archive(memories: ms).validated() }
}
rule("Upsert edits by ID rather than creating duplicates") {
  var a = Archive(memories: [memory()])
  var m = a.memories[0]
  m.body = "Yeni anlatı"
  try a.upsert(m)
  try expect(a.memories.count == 1 && a.memories[0].body == "Yeni anlatı")
}
rule("Invalid upsert leaves original archive unchanged") {
  var a = Archive(memories: [memory()])
  let old = a
  var m = a.memories[0]
  m.title = ""
  try rejects { try a.upsert(m) }
  try expect(a == old)
}
rule("Remove only deletes the specified memory") {
  var a = Archive(memories: [memory("A"), memory("B")])
  a.remove(a.memories[0].id)
  try expect(a.memories.map(\.title) == ["B"])
}
rule("Turkish dotted and dotless I match tolerant search") {
  let a = Archive(memories: [memory()])
  try expect(a.matching(query: "istanbul").count == 1 && a.matching(query: "ISPARTA").count == 1)
}
rule("Search includes people and ignores surrounding whitespace") {
  try expect(Archive(memories: [memory()]).matching(query: " ayse ").count == 1)
}
rule("Decade and favorite filters combine") {
  var m = memory(year: 1993)
  m.favorite = true
  let a = Archive(memories: [m, memory("Diğer", year: 1980)])
  try expect(a.matching(query: "", decade: 1990, favorites: true).count == 1)
}
rule("Unknown dates sort after known dates in both orders") {
  let a = Archive(memories: [
    memory("Bilinmiyor", year: nil), memory("Eski", year: 1980), memory("Yeni", year: 2000),
  ])
  try expect(
    a.matching(query: "", oldestFirst: true).map(\.title) == ["Eski", "Yeni", "Bilinmiyor"])
  try expect(a.matching(query: "").map(\.title) == ["Yeni", "Eski", "Bilinmiyor"])
}
rule("Markdown export includes provenance and normalizes CR line endings") {
  var m = memory()
  m.body = "A\rB\r\nC"
  let report = Archive(memories: [m]).markdown()
  try expect(report.contains("> A\n> B\n> C") && report.contains("kayıt sahibinin beyanıdır"))
}
let temp = FileManager.default.temporaryDirectory.appendingPathComponent(
  "mazi-rules-\(UUID().uuidString)")
defer { try? FileManager.default.removeItem(at: temp) }
rule("Store creates an empty archive without a file") {
  try expect(
    try ArchiveStore(url: temp.appendingPathComponent("absent.json")).load().memories.isEmpty)
}
rule("Store persists and reloads atomically") {
  let s = ArchiveStore(url: temp.appendingPathComponent("saved.json"))
  let a = Archive(memories: [memory()])
  try s.save(a)
  try expect(try s.load() == a)
}
rule("Failed validation does not overwrite saved data") {
  let s = ArchiveStore(url: temp.appendingPathComponent("protected.json"))
  try s.save(Archive(memories: [memory()]))
  let old = try Data(contentsOf: s.url)
  var bad = memory()
  bad.title = ""
  try rejects { try s.save(Archive(memories: [bad])) }
  try expect(try Data(contentsOf: s.url) == old)
}
rule("Unreadable archive is never silently replaced") {
  let url = temp.appendingPathComponent("broken.json")
  try Data("broken".utf8).write(to: url)
  let s = ArchiveStore(url: url)
  try rejects { _ = try s.load() }
  try expect(try String(contentsOf: url) == "broken")
}
rule("Restore preserves a separate recovery copy") {
  let dir = temp.appendingPathComponent("restore")
  let s = ArchiveStore(url: dir.appendingPathComponent("hatiralar.json"))
  try s.save(Archive(memories: [memory("Önce")]))
  try s.restore(Archive(memories: [memory("Sonra")]))
  let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
  let recovery = try files.first(where: { $0.lastPathComponent.hasPrefix("geri-donus-") }).map {
    try Archive.decode(Data(contentsOf: $0))
  }
  try expect(recovery?.memories[0].title == "Önce" && s.load().memories[0].title == "Sonra")
}
func settle(_ game: inout MarbleGame, dt: Double = 1 / 60) { for _ in 0..<300 { game.advance(dt) } }
rule("Marble does not move before a throw") {
  var g = MarbleGame()
  g.advance(0.02)
  try expect(g.position == 0.04 && g.shots == 0)
}
rule("Marble ignores invalid strengths and time") {
  var g = MarbleGame()
  g.throwMarble(strength: .nan)
  try expect(!g.rolling)
  g.throwMarble(strength: 0.5)
  let x = g.position
  g.advance(.infinity)
  g.advance(-1)
  try expect(g.position == x)
}
rule("Marble duplicate throws cannot reset a rolling shot") {
  var g = MarbleGame()
  g.throwMarble(strength: 0.5)
  g.advance(0.02)
  let x = g.position
  g.throwMarble(strength: 1)
  try expect(g.position == x)
}
rule("Marble integration is consistent at different frame rates") {
  var a = MarbleGame()
  var b = MarbleGame()
  a.throwMarble(strength: 0.7)
  b.throwMarble(strength: 0.7)
  settle(&a, dt: 0.01)
  settle(&b, dt: 0.02)
  try expect(abs(a.position - b.position) < 1e-8 && a.score == b.score)
}
rule("Five ideal marble throws finish at fifty points") {
  var g = MarbleGame()
  for _ in 0..<5 {
    let strength = sqrt(2 * (g.target - 0.04)) - 0.4
    g.throwMarble(strength: strength)
    settle(&g)
  }
  try expect(g.finished && g.score == 50 && g.shots == 5)
  g.throwMarble(strength: 1)
  try expect(!g.rolling)
}
rule("Marble wake delta is capped") {
  var a = MarbleGame()
  var b = MarbleGame()
  a.throwMarble(strength: 1)
  b.throwMarble(strength: 1)
  a.advance(1000)
  b.advance(0.05)
  try expect(a.position == b.position)
}
rule("Hopscotch input is ignored until card is hidden") {
  var g = HopscotchGame()
  g.pick(1)
  g.show()
  g.pick(1)
  try expect(g.entered.isEmpty && g.showing)
  g.hide()
  try expect(g.ready)
}
rule("Wrong hopscotch step ends the round") {
  var g = HopscotchGame()
  g.show()
  g.hide()
  g.pick(9)
  try expect(g.lost && !g.ready)
}
rule("Invalid hopscotch number is ignored") {
  var g = HopscotchGame()
  g.show()
  g.hide()
  g.pick(99)
  try expect(g.entered.isEmpty && !g.lost)
}
rule("Correct hopscotch paths advance and finish") {
  var g = HopscotchGame()
  for _ in 2...7 {
    g.show()
    g.hide()
    for n in g.sequence { g.pick(n) }
  }
  try expect(g.finished && !g.ready)
  g.show()
  try expect(!g.showing)
}
rule("Ambient WAV has valid PCM header and bounded duration") {
  let wave = AmbientAudio.wave(seconds: 1)
  try expect(
    String(data: wave.prefix(4), encoding: .ascii) == "RIFF" && wave.count == 44 + 22050 * 2)
  try expect(AmbientAudio.wave(seconds: 0).count == wave.count)
}
rule("Ambient synthesis is deterministic") {
  try expect(AmbientAudio.wave(seconds: 1) == AmbientAudio.wave(seconds: 1))
}
print("\(count) rules checked; \(failures) failures.")
exit(failures == 0 ? 0 : 1)

import Foundation

public struct Memory: Codable, Equatable, Identifiable {
  public var id: UUID
  public var title: String
  public var body: String
  public var year: Int?
  public var place: String
  public var people: String
  public var doorID: String
  public var favorite: Bool
  public var photo: Data?
  public var createdAt: Date
  public var updatedAt: Date
  public init(
    id: UUID = UUID(), title: String = "", body: String = "", year: Int? = nil, place: String = "",
    people: String = "", doorID: String = "tea", favorite: Bool = false, photo: Data? = nil,
    now: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.body = body
    self.year = year
    self.place = place
    self.people = people
    self.doorID = doorID
    self.favorite = favorite
    self.photo = photo
    self.createdAt = now
    self.updatedAt = now
  }
  public var theme: MemoryTheme { Catalog.door(doorID)?.theme ?? .home }
}
public struct Archive: Codable, Equatable {
  public var kind: String = "mazi-sandigi"
  public var version: Int = 1
  public var memories: [Memory]
  public init(memories: [Memory] = []) { self.memories = memories }
  public func validated() throws -> Archive {
    guard kind == "mazi-sandigi", version == 1 else {
      throw ArchiveError.invalid("Bu uygulamaya ait sürüm 1 arşivi gerekli.")
    }
    guard memories.count <= 100, Set(memories.map(\.id)).count == memories.count else {
      throw ArchiveError.invalid("En fazla 100 hatıra ve benzersiz kayıt kimlikleri gerekli.")
    }
    guard memories.filter({ $0.photo != nil }).count <= 10 else {
      throw ArchiveError.invalid("Bir defterde en fazla 10 fotoğraflı hatıra saklanabilir.")
    }
    for m in memories {
      guard !m.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, m.title.count <= 100,
        !m.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, m.body.count <= 10000,
        m.place.count <= 100, m.people.count <= 160,
        ![m.title, m.place, m.people].contains(where: { $0.contains("\n") || $0.contains("\r") }),
        Catalog.door(m.doorID) != nil
      else { throw ArchiveError.invalid("Başlık, hikâye veya hatıra durağı geçersiz.") }
      if let year = m.year, !(1800...2100).contains(year) {
        throw ArchiveError.invalid("Yıl 1800–2100 arasında olmalı; bilmiyorsan boş bırak.")
      }
      if let photo = m.photo, photo.count > 2_000_000 || !photo.starts(with: [0xFF, 0xD8, 0xFF]) {
        throw ArchiveError.invalid("Fotoğraf en fazla 2 MB olmalı.")
      }
      guard
        [m.createdAt, m.updatedAt].allSatisfy({
          $0.timeIntervalSince1970.isFinite
            && (-2_208_988_800...4_133_980_800).contains($0.timeIntervalSince1970)
        })
      else { throw ArchiveError.invalid("Kayıt tarihi geçersiz.") }
    }
    return self
  }
  public static func decode(_ data: Data) throws -> Archive {
    guard data.count <= 30_000_000 else {
      throw ArchiveError.invalid("Arşiv en fazla 30 MB olabilir.")
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(Archive.self, from: data).validated()
  }
  public func encoded() throws -> Data {
    _ = try validated()
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(self)
    guard data.count <= 30_000_000 else {
      throw ArchiveError.invalid("Arşiv 30 MB sınırını aşıyor.")
    }
    return data
  }
  public mutating func upsert(_ memory: Memory) throws {
    var next = self
    if let index = next.memories.firstIndex(where: { $0.id == memory.id }) {
      next.memories[index] = memory
    } else {
      next.memories.append(memory)
    }
    _ = try next.validated()
    self = next
  }
  public mutating func remove(_ id: UUID) { memories.removeAll { $0.id == id } }
  public func matching(
    query: String, decade: Int? = nil, favorites: Bool = false, oldestFirst: Bool = false
  ) -> [Memory] {
    let needle = Search.normalized(query.trimmingCharacters(in: .whitespacesAndNewlines))
    let items = memories.filter { m in
      (!favorites || m.favorite) && (decade == nil || m.year.map { $0 / 10 * 10 == decade } == true)
        && (needle.isEmpty
          || Search.normalized(
            [m.title, m.body, m.place, m.people, Catalog.door(m.doorID)?.title ?? ""].joined(
              separator: " ")
          ).contains(needle))
    }
    return items.sorted { a, b in
      let ay = a.year ?? (oldestFirst ? Int.max : Int.min)
      let by = b.year ?? (oldestFirst ? Int.max : Int.min)
      if ay != by { return oldestFirst ? ay < by : ay > by }
      if a.updatedAt != b.updatedAt { return a.updatedAt > b.updatedAt }
      return a.id.uuidString < b.id.uuidString
    }
  }
  public func markdown() -> String {
    let lines = matching(query: "", oldestFirst: true).map { m -> String in
      let meta = [m.year.map(String.init) ?? "Yıl bilinmiyor", m.place, m.people].filter {
        !$0.isEmpty
      }.joined(separator: " · ")
      let body = m.body.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
        of: "\r", with: "\n"
      ).split(separator: "\n", omittingEmptySubsequences: false).map { "> " + $0 }.joined(
        separator: "\n")
      return
        "## \(m.title)\n\n\(meta)\n\nDurak: \(Catalog.door(m.doorID)?.title ?? "")\n\n\(body)\n"
        + (m.photo == nil ? "" : "\nFotoğraf, özgün arşiv yedeğinde bulunur.\n")
    }
    return
      "# Mazi Sandığı\n\nKişisel hatıralar. Tarihler ve anlatılar kayıt sahibinin beyanıdır.\nFotoğraflar Markdown dosyasına gömülmez; tam yedek için arşiv dışa aktar.\n\n"
      + lines.joined(separator: "\n---\n\n")
  }
}
public enum Search {
  public static func normalized(_ text: String) -> String {
    text.lowercased(with: Locale(identifier: "tr_TR")).replacingOccurrences(of: "ı", with: "i")
      .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "tr_TR"))
  }
}
public enum ArchiveError: Error, LocalizedError {
  case invalid(String)
  public var errorDescription: String? {
    if case let .invalid(message) = self { return message }
    return nil
  }
}
public final class ArchiveStore {
  public let url: URL
  public init(url: URL) { self.url = url }
  public static func defaultURL() -> URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("MaziSandigi", isDirectory: true).appendingPathComponent(
        "hatiralar.json")
  }
  public func load() throws -> Archive {
    guard FileManager.default.fileExists(atPath: url.path) else { return Archive() }
    let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
    guard ((attrs[.size] as? NSNumber)?.intValue ?? Int.max) <= 30_000_000 else {
      throw ArchiveError.invalid("Yerel arşiv boyutu geçersiz; dosya korunuyor.")
    }
    return try Archive.decode(Data(contentsOf: url))
  }
  public func save(_ archive: Archive) throws {
    let data = try archive.encoded()
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
    try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
  }
  public func restore(_ archive: Archive) throws {
    _ = try archive.validated()
    if FileManager.default.fileExists(atPath: url.path) {
      let recovery = url.deletingLastPathComponent().appendingPathComponent(
        "geri-donus-\(UUID().uuidString).json")
      try FileManager.default.copyItem(at: url, to: recovery)
    }
    try save(archive)
  }
}

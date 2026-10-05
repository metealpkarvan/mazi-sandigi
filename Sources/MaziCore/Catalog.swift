import Foundation

public enum MemoryTheme: String, Codable, CaseIterable {
  case home, street, school, holidays, journeys, table
  public var title: String {
    switch self {
    case .home: return "Evde bir akşam"
    case .street: return "Mahalle arası"
    case .school: return "Okul yılları"
    case .holidays: return "Bayram sabahı"
    case .journeys: return "Yol ve yaz"
    case .table: return "Sofranın etrafı"
    }
  }
  public var symbol: String {
    switch self {
    case .home: return "house"
    case .street: return "basket"
    case .school: return "book.closed"
    case .holidays: return "gift"
    case .journeys: return "tram"
    case .table: return "cup.and.saucer"
    }
  }
}
public struct MemoryDoor: Equatable {
  public let id: String
  public let title: String
  public let theme: MemoryTheme
  public let symbol: String
  public let detail: String
  public let questions: [String]
  public init(
    _ id: String, _ title: String, _ theme: MemoryTheme, _ symbol: String, _ detail: String,
    _ questions: [String]
  ) {
    self.id = id
    self.title = title
    self.theme = theme
    self.symbol = symbol
    self.detail = detail
    self.questions = questions
  }
}
public enum Catalog {
  public static let doors: [MemoryDoor] = [
    .init(
      "tea", "İnce belli bardak", .home, "cup.and.saucer",
      "Bir tabak şıngırtısı, demli bir çay. Bazen eve dönmek bir sesle başlar.",
      [
        "Evinde çay kimin elinden içilirdi? O kişinin bir sözünü hatırlıyor musun?",
        "Hiç bitmesin istediğin bir çay sohbetini anlatır mısın?",
      ]),
    .init(
      "television", "Dantelli televizyon", .home, "tv",
      "Kanal düğmesi, anten ayarı, ekranın etrafında toplanan sandalyeler. Kendi evinin akşamını düşün.",
      [
        "Birlikte televizyon izlediğiniz bir akşamda odada kimler vardı?",
        "Elektrik kesilince evde ne yapardınız? En çok hangi ses duyulurdu?",
      ]),
    .init(
      "cassette", "Kalemle sarılan kaset", .home, "radio",
      "A ve B yüzü arasında küçük bir dünya. Burada eski şarkılar yerine, senin onlarla kalan hikâyen var.",
      [
        "Sana bir kişiyi ya da bir yolu hatırlatan kasetin hikâyesi neydi?",
        "Kasetlerin üstüne ne yazardın? Sana hediye edilen bir kayıt var mıydı?",
      ]),
    .init(
      "grocer", "Bakkalın defteri", .street, "basket",
      "Bir tartı, cam kavanozlar, kapıdan söylenen bir selam. Bir mahallenin tanışıklığını hatırla.",
      [
        "Mahallenin bakkalı sana nasıl seslenirdi? Dükkânı tarif eder misin?",
        "Çocukken tek başına aldığın ilk şeyi ve elindeki parayı hatırlıyor musun?",
      ]),
    .init(
      "doorstep", "Kapı önü", .street, "door.left.hand.open",
      "İki sandalye bir sokağı sohbete çevirebilir. Senin mahallenin ritmi nasıldı?",
      [
        "Kapı önünde ya da balkonda kimler otururdu? Ne konuşulurdu?",
        "Mahallende seni eve çağıran ses hangisiydi?",
      ]),
    .init(
      "marble", "Cepteki misket", .street, "circle.grid.2x2",
      "Camın içinde kıvrılan renkler, avuçta biriken küçük hazineler. Her sokak kendi oyununu kurardı.",
      [
        "Hangi sokak oyununu oynardınız? Kurallarını sizin usulünüzle anlatır mısın?",
        "En sevdiğin oyun arkadaşını ve onunla bir gününü hatırlıyor musun?",
      ]),
    .init(
      "notebook", "Çizgili defter", .school, "pencil",
      "Kâğıt kokusu, kenara düşülen notlar, bir sayfada kalan el yazısı. Kendi ilk sayfanı aç.",
      [
        "İlk öğretmeninin aklında kalan bir cümlesi var mı?",
        "Defterinin kenarına neler çizerdin? Bir sınıf gününü ayrıntılarıyla anlat.",
      ]),
    .init(
      "bell", "Teneffüs zili", .school, "bell",
      "Bir zil çalar; koridor bir anda başka bir dünyaya dönüşür.",
      [
        "Teneffüste hep gittiğin bir köşe var mıydı?",
        "Okula giderken izlediğin yolu, yanından geçtiğin yerlerle tarif eder misin?",
      ]),
    .init(
      "report", "Karne günü", .school, "doc.text",
      "Çantadaki bir kâğıdın evde açtığı sohbet. Rakamların gerisinde kalan günü hatırla.",
      [
        "Karne gününde eve nasıl dönerdin? Kapıyı kim açardı?",
        "Okul yıllarında küçük bir başarını ilk kiminle paylaştın?",
      ]),
    .init(
      "cologne", "Kolonya şişesi", .holidays, "drop",
      "Avuçlarda serinlik, kapıda karşılanan misafir. Kokular bazen yıllardan daha hızlı geri getirir.",
      [
        "Bayram sabahında evin ilk hazırlığı ne olurdu?",
        "Bir ziyaretin kapısını açan kişiyi, kokusunu ve sesini hatırlıyor musun?",
      ]),
    .init(
      "handkerchief", "Cepteki mendil", .holidays, "gift",
      "Özenle hazırlanmış bir mendil, temiz bir yaka, çıkılacak ziyaretler.",
      [
        "Bayramda giydiğin bir kıyafeti ve onu hazırlayan kişiyi anlatır mısın?",
        "Harçlığını ilk neye ayırırdın? Sakladığın bir mendil ya da küçük eşya var mı?",
      ]),
    .init(
      "shadow", "Gölge perdesi", .holidays, "theatermasks",
      "Perdede konuşan iki gölge, onları izleyen bir çocuk. Karagöz geleneğini kendi seyir hatıranla düşün.",
      [
        "İzlediğin bir gölge oyunu ya da mahalle gösterisi aklında kaldı mı?",
        "Seni çocukken kahkahaya boğan bir anlatıcının hikâyesini paylaşır mısın?",
      ]),
    .init(
      "bus", "Otobüs camı", .journeys, "bus",
      "Camdan kayan tarlalar, mola yerinin telaşı, bir yolculuğun başlangıcı.",
      [
        "Uzun bir yolculukta yanında kim vardı? Camın dışında ne görüyordun?",
        "Bir mola yerini tat, ses ve kokusuyla tarif eder misin?",
      ]),
    .init(
      "postcard", "Yazlık kartpostal", .journeys, "envelope",
      "Uzakta bir adres, arkasında birkaç satır. Küçük bir kâğıda sığan koca bir yaz.",
      [
        "Yazları gittiğiniz bir yer varsa orada gün nasıl başlardı?",
        "Birine gönderdiğin ya da aldığın mektuptan hatırladığın bir şey var mı?",
      ]),
    .init(
      "train", "Gar saati", .journeys, "tram",
      "Beklemek de yolun bir parçası. Bir istasyon, valiz ve ilk kez görülen bir şehir.",
      [
        "Bir şehirle ilk karşılaşmanı hatırlıyor musun?",
        "Bir yolculukta seni uğurlayan veya karşılayan kişi ne söyledi?",
      ]),
    .init(
      "coffee", "Hatır fincanı", .table, "cup.and.saucer",
      "Küçük bir fincanın çevresinde uzayan sohbet. Kahve, kimi zaman bir ziyaretin bahanesi olur.",
      [
        "Kahve sofrasında en çok kimin hikâyeleri anlatılırdı?",
        "Bir fincanla başlayan ve aklında kalan bir tanışmayı anlatır mısın?",
      ]),
    .init(
      "bread", "Ekmek örtüsü", .table, "leaf",
      "Bir örtünün altında paylaşılan ekmek. Sofrada kimin nereye oturduğunu hatırla.",
      [
        "Evde sofrayı kim kurardı? Birlikte yaptığınız küçük bir hazırlık neydi?",
        "Sana çocukluğunu hatırlatan yemeği ve onu yapan kişiyi anlatır mısın?",
      ]),
    .init(
      "jam", "Reçel kavanozu", .table, "sun.max",
      "Bir mevsimin rengi kavanozda kalır. Bir mutfak hatırasının tarifini birlikte çıkar.",
      [
        "Evde mevsimlik hangi hazırlık yapılırdı? Senin küçük görevin ne olurdu?",
        "Bir aile tarifinin ölçülerini ve söylenişini olduğu gibi kaydetmek ister misin?",
      ]),
  ]
  public static func door(_ id: String) -> MemoryDoor? { doors.first { $0.id == id } }
  public static func questions(theme: MemoryTheme?) -> [(MemoryDoor, String)] {
    doors.filter { theme == nil || $0.theme == theme }.flatMap { door in
      door.questions.map { (door, $0) }
    }
  }
}

import Foundation

public struct MarbleGame {
  public private(set) var position: Double = 0.04
  public private(set) var velocity: Double = 0
  public private(set) var rolling = false
  public private(set) var shots = 0
  public private(set) var score = 0
  public private(set) var lastPoints = 0
  public var finished: Bool { shots >= 5 && !rolling }
  public var target: Double { [0.70, 0.44, 0.82, 0.60, 0.75][min(shots, 4)] }
  public init() {}
  public mutating func throwMarble(strength: Double) {
    guard !rolling, !finished, strength.isFinite else { return }
    position = 0.04
    velocity = 0.4 + min(1, max(0, strength))
    rolling = true
    lastPoints = 0
  }
  public mutating func advance(_ elapsed: Double) {
    guard rolling, elapsed.isFinite, elapsed > 0 else { return }
    let dt = min(elapsed, min(0.05, velocity))
    position += velocity * dt - 0.5 * dt * dt
    velocity = max(0, velocity - dt)
    if velocity < 0.000001 || position >= 0.97 {
      position = min(0.97, position)
      velocity = 0
      rolling = false
      let distance = abs(position - target)
      lastPoints = distance <= 0.06 ? 10 : distance <= 0.12 ? 5 : 0
      score += lastPoints
      shots += 1
    }
  }
}
public struct HopscotchGame {
  public private(set) var level = 2
  public private(set) var entered: [Int] = []
  public private(set) var showing = false
  public private(set) var ready = false
  public private(set) var lost = false
  public private(set) var finished = false
  public let path = [1, 3, 5, 2, 8, 4, 9, 6, 7]
  public var sequence: [Int] { Array(path.prefix(level)) }
  public init() {}
  public mutating func show() {
    guard !lost, !finished else { return }
    showing = true
    ready = false
    entered = []
  }
  public mutating func hide() {
    if showing {
      showing = false
      ready = true
    }
  }
  public mutating func pick(_ number: Int) {
    guard ready, !showing, !lost, !finished, (1...9).contains(number) else { return }
    guard sequence[entered.count] == number else {
      lost = true
      ready = false
      return
    }
    entered.append(number)
    if entered.count == sequence.count {
      ready = false
      if level == 7 { finished = true } else { level += 1 }
    }
  }
}
public enum AmbientAudio {
  /// Original deterministic low-volume rain and a soft clock tick. No recordings or songs.
  public static func wave(seconds: Int = 20) -> Data {
    let sampleRate = 22050
    let frames = sampleRate * max(1, min(30, seconds))
    var pcm = Data(capacity: frames * 2)
    var state: UInt32 = 731
    var smooth = 0.0
    for i in 0..<frames {
      state = state &* 1_664_525 &+ 1_013_904_223
      let noise = (Double(state) / Double(UInt32.max)) * 2 - 1
      smooth = smooth * 0.85 + noise * 0.15
      let edge = min(1, Double(min(i, frames - i)) / 2205)
      let phase = i % (sampleRate * 4)
      let tick = phase < 550 ? sin(Double(phase) * 0.42) * exp(-Double(phase) / 110) * 0.035 : 0
      let value = Int16(max(-1, min(1, (smooth * 0.08 + tick) * edge)) * 32767)
      var little = value.littleEndian
      withUnsafeBytes(of: &little) { pcm.append(contentsOf: $0) }
    }
    var data = Data()
    func ascii(_ s: String) { data.append(contentsOf: s.utf8) }
    func u32(_ n: UInt32) {
      var x = n.littleEndian
      withUnsafeBytes(of: &x) { data.append(contentsOf: $0) }
    }
    func u16(_ n: UInt16) {
      var x = n.littleEndian
      withUnsafeBytes(of: &x) { data.append(contentsOf: $0) }
    }
    ascii("RIFF")
    u32(UInt32(36 + pcm.count))
    ascii("WAVEfmt ")
    u32(16)
    u16(1)
    u16(1)
    u32(UInt32(sampleRate))
    u32(UInt32(sampleRate * 2))
    u16(2)
    u16(16)
    ascii("data")
    u32(UInt32(pcm.count))
    data.append(pcm)
    return data
  }
}

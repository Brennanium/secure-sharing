import Foundation

final class Locked<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Value

  init(_ value: Value) {
    self.value = value
  }

  func withLock<R>(_ operation: (inout Value) -> R) -> R {
    lock.lock()
    defer { lock.unlock() }
    return operation(&value)
  }
}

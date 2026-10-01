import ConcurrencyExtras
import Dependencies
@preconcurrency import Foundation
import IssueReporting
import Sharing

extension SharedReaderKey {
  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Bool> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Int> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Double> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<String> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<[String]> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<URL> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Data> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Date> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  @_disfavoredOverload
  public static func secureAppStorage<Value: Codable>(
    _ key: String,
    store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Value> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage<Value: RawRepresentable>(
    _ key: String,
    store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Value.RawValue == Int, Self == SecureAppStorageKey<Value> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage<Value: RawRepresentable>(
    _ key: String,
    store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Value.RawValue == String, Self == SecureAppStorageKey<Value> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Bool?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Int?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Double?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<String?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<[String]?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<URL?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Data?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage(
    _ key: String, store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Date?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  @_disfavoredOverload
  public static func secureAppStorage<Value: Codable>(
    _ key: String,
    store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Self == SecureAppStorageKey<Value?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage<Value: RawRepresentable>(
    _ key: String,
    store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Value.RawValue == Int, Self == SecureAppStorageKey<Value?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }

  public static func secureAppStorage<Value: RawRepresentable>(
    _ key: String,
    store: UserDefaults? = nil, crypto: SecureCryptoClient? = nil
  ) -> Self
  where Value.RawValue == String, Self == SecureAppStorageKey<Value?> {
    SecureAppStorageKey(key, store: store, crypto: crypto)
  }
}

private let securePrefix = "secure_"

/// A Sharing key that persists encrypted values in `UserDefaults`.
///
/// Configure `secureAppStorageCrypto` before using this key, or pass `crypto:` to override it for
/// one key.
/// Loads and saves run synchronously and may block the calling thread.
/// See <doc:GettingStarted> for setup and <doc:SecureAppStorage> for storage behavior.
public struct SecureAppStorageKey<Value: Sendable>: SharedKey {
  private let lookup: any Lookup<Value>
  private let key: String
  private let secureKey: String
  private let store: UncheckedSendable<UserDefaults>
  private let crypto: SecureCryptoClient
  private let saveProtectionState = Locked(
    (blockedUntilSuccessfulLoad: false, loadFailureGeneration: UInt64.zero)
  )

  public var id: SecureAppStorageKeyID {
    SecureAppStorageKeyID(key: key, store: store.wrappedValue, crypto: crypto)
  }

  private init(
    lookup: some Lookup<Value>,
    key: String,
    store: UserDefaults?,
    crypto: SecureCryptoClient?
  ) {
    @Dependency(\.defaultAppStorage) var defaultStore
    @Dependency(\.secureAppStorageCrypto) var defaultCrypto

    self.lookup = lookup
    self.key = key
    self.secureKey = securePrefix + key
    self.store = UncheckedSendable(store ?? defaultStore)
    self.crypto = crypto ?? defaultCrypto
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Bool {
    self.init(lookup: CodableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Int {
    self.init(lookup: CodableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Double {
    self.init(lookup: CodableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == String {
    self.init(lookup: CodableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == [String] {
    self.init(lookup: CodableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == URL {
    self.init(lookup: CodableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Data {
    self.init(lookup: CodableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Date {
    self.init(lookup: CodableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value: Codable {
    self.init(lookup: CodableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value: RawRepresentable, Value.RawValue == Int {
    self.init(
      lookup: RawRepresentableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value: RawRepresentable, Value.RawValue == String {
    self.init(
      lookup: RawRepresentableLookup(), key: key, store: store, crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Bool? {
    self.init(
      lookup: OptionalLookup(base: CodableLookup<Bool>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Int? {
    self.init(
      lookup: OptionalLookup(base: CodableLookup<Int>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Double? {
    self.init(
      lookup: OptionalLookup(base: CodableLookup<Double>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == String? {
    self.init(
      lookup: OptionalLookup(base: CodableLookup<String>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == [String]? {
    self.init(
      lookup: OptionalLookup(base: CodableLookup<[String]>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == URL? {
    self.init(
      lookup: OptionalLookup(base: CodableLookup<URL>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Data? {
    self.init(
      lookup: OptionalLookup(base: CodableLookup<Data>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init(_ key: String, store: UserDefaults?, crypto: SecureCryptoClient?)
  where Value == Date? {
    self.init(
      lookup: OptionalLookup(base: CodableLookup<Date>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init<C: Codable>(
    _ key: String, store: UserDefaults?, crypto: SecureCryptoClient?
  ) where Value == C? {
    self.init(
      lookup: OptionalLookup(base: CodableLookup<C>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init<R: RawRepresentable>(
    _ key: String, store: UserDefaults?, crypto: SecureCryptoClient?
  )
  where R.RawValue == Int, Value == R? {
    self.init(
      lookup: OptionalLookup(base: RawRepresentableLookup<R>()), key: key, store: store,
      crypto: crypto)
  }

  fileprivate init<R: RawRepresentable>(
    _ key: String, store: UserDefaults?, crypto: SecureCryptoClient?
  )
  where R.RawValue == String, Value == R? {
    self.init(
      lookup: OptionalLookup(base: RawRepresentableLookup<R>()), key: key, store: store,
      crypto: crypto)
  }

  public func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    guard crypto.isConfigured else {
      continuation.resume(throwing: SecureStorageError.cryptoNotConfigured)
      return
    }
    @Dependency(\.secureStorageStatus) var secureStorageStatus

    let result = Result {
      try loadValue(default: context.initialValue, status: secureStorageStatus)
    }
    deliver(result, to: continuation)
  }

  public func subscribe(context: LoadContext<Value>, subscriber: SharedSubscriber<Value>)
    -> SharedSubscription
  {
    guard crypto.isConfigured else {
      return SharedSubscription {}
    }
    @Dependency(\.secureStorageStatus) var secureStorageStatus
    let status = secureStorageStatus

    let keyContainsPeriod = key.contains(".")
    let keyHasAtPrefix = key.hasPrefix("@")
    @Dependency(\.appStorageKeyFormatWarningEnabled) var appStorageKeyFormatWarningEnabled
    if (keyContainsPeriod || keyHasAtPrefix) && appStorageKeyFormatWarningEnabled {
      let character = keyContainsPeriod ? "." : "@"
      reportIssue(
        """
        A Shared secure app storage key (\(key.debugDescription)) contains an invalid character \
        (\(character.debugDescription)) for key-value observation. External updates will be \
        observed less efficiently and accurately via notification center, instead.

        Please reformat this key by removing invalid characters in order to ensure efficient, \
        cross-process observation.

        If you cannot control the format of this key and would like to silence this warning, \
        override the '\\.appStorageKeyFormatWarningEnabled' dependency at the entry point of \
        your application. For example:

            import Dependencies

            @main
            struct MyApp: App {
              init() {
                prepareDependencies {
                  $0.appStorageKeyFormatWarningEnabled = false
                }
                // ...
              }
              // ...
            }
        """
      )
    }

    let removeObservers = Locked<[@Sendable () -> Void]>([])

    let protectedDataObserver = NotificationCenter.default.addObserver(
      forName: status.protectedDataDidBecomeAvailableNotification,
      object: nil,
      queue: nil
    ) { _ in
      guard status.isProtectedDataAvailable(), !SharedSecureAppStorageLocals.isSetting
      else {
        return
      }

      deliver(
        Result { try loadValue(default: context.initialValue, status: status) },
        to: subscriber
      )
    }
    removeObservers.withLock {
      $0.append { NotificationCenter.default.removeObserver(protectedDataObserver) }
    }

    if keyContainsPeriod || keyHasAtPrefix {
      let previousValue = Locked<Value?>(context.initialValue)
      let userDefaultsDidChange = NotificationCenter.default.addObserver(
        forName: UserDefaults.didChangeNotification,
        object: store.wrappedValue,
        queue: nil
      ) { _ in
        guard !SharedSecureAppStorageLocals.isSetting else { return }
        DispatchQueue.main.async {
          guard status.isProtectedDataAvailable() else { return }
          let result = Result {
            try loadValue(default: context.initialValue, status: status)
          }

          switch result {
          case .success(let newValue):
            let oldValue = previousValue.withLock { $0 }
            let valuesAreEqual = isEqual(newValue, oldValue) ?? false
            let isInitialValue = isEqual(newValue, context.initialValue) ?? true
            guard !valuesAreEqual || isInitialValue else { return }

            previousValue.withLock { $0 = newValue }
            deliver(.success(newValue), to: subscriber)
          case .failure(let error):
            deliver(.failure(error), to: subscriber)
          }
        }
      }
      removeObservers.withLock {
        $0.append { NotificationCenter.default.removeObserver(userDefaultsDidChange) }
      }
    } else {
      let observer = Observer {
        guard status.isProtectedDataAvailable(), !SharedSecureAppStorageLocals.isSetting
        else {
          return
        }

        deliver(
          Result { try loadValue(default: context.initialValue, status: status) },
          to: subscriber
        )
      }

      store.wrappedValue.addObserver(observer, forKeyPath: secureKey, context: nil)
      removeObservers.withLock {
        $0.append { store.wrappedValue.removeObserver(observer, forKeyPath: secureKey) }
      }
    }

    return SharedSubscription {
      removeObservers.withLock {
        $0.forEach { remove in remove() }
      }
    }
  }

  public func save(_ value: Value, context _: SaveContext, continuation: SaveContinuation) {
    guard crypto.isConfigured else {
      continuation.resume(throwing: SecureStorageError.cryptoNotConfigured)
      return
    }
    @Dependency(\.secureStorageStatus) var secureStorageStatus

    continuation.resume(
      with: Result {
        try saveValue(value, status: secureStorageStatus)
      })
  }

  private func loadValue(default initialValue: Value?, status: SecureStorageStatusClient) throws
    -> Value?
  {
    guard crypto.isConfigured else { throw SecureStorageError.cryptoNotConfigured }
    guard status.isProtectedDataAvailable() else {
      throw SecureStorageError.protectedDataUnavailable
    }
    let value = try storedData().map {
      try lookup.decodeValue(from: $0, associatedDataKey: key, crypto: crypto)
    }
    guard status.isProtectedDataAvailable() else {
      throw SecureStorageError.protectedDataUnavailable
    }
    return value ?? initialValue
  }

  private func saveValue(_ value: Value, status: SecureStorageStatusClient) throws {
    guard crypto.isConfigured else { throw SecureStorageError.cryptoNotConfigured }
    guard status.isProtectedDataAvailable() else {
      throw SecureStorageError.protectedDataUnavailable
    }
    if let existingData = try storedData() {
      _ = try lookup.decodeValue(from: existingData, associatedDataKey: key, crypto: crypto)
    }
    guard !saveProtectionState.withLock({ $0.blockedUntilSuccessfulLoad }) else {
      throw SecureStorageError.saveBlockedUntilSuccessfulLoad
    }
    let encryptedData = try lookup.encodeValue(value, associatedDataKey: key, crypto: crypto)
    guard status.isProtectedDataAvailable() else {
      throw SecureStorageError.protectedDataUnavailable
    }
    guard !saveProtectionState.withLock({ $0.blockedUntilSuccessfulLoad }) else {
      throw SecureStorageError.saveBlockedUntilSuccessfulLoad
    }
    SharedSecureAppStorageLocals.$isSetting.withValue(true) {
      if let encryptedData {
        store.wrappedValue.set(encryptedData, forKey: secureKey)
      } else {
        store.wrappedValue.removeObject(forKey: secureKey)
      }
    }
  }

  private func storedData() throws -> Data? {
    guard let storedValue = store.wrappedValue.object(forKey: secureKey) else { return nil }
    guard let data = storedValue as? Data else { throw SecureStorageError.invalidStoredValue }
    return data
  }

  private func deliver(
    _ result: Result<Value?, any Error>,
    to continuation: LoadContinuation<Value>
  ) {
    let failureGeneration = recordLoadResultBeforeDelivery(result)
    continuation.resume(with: result)
    if let failureGeneration {
      clearSaveBlockAfterSuccessfulDelivery(ifNoNewerFailureThan: failureGeneration)
    }
  }

  private func deliver(
    _ result: Result<Value?, any Error>,
    to subscriber: SharedSubscriber<Value>
  ) {
    let failureGeneration = recordLoadResultBeforeDelivery(result)
    subscriber.yield(with: result)
    if let failureGeneration {
      clearSaveBlockAfterSuccessfulDelivery(ifNoNewerFailureThan: failureGeneration)
    }
  }

  private func recordLoadResultBeforeDelivery(_ result: Result<Value?, any Error>) -> UInt64? {
    saveProtectionState.withLock { state in
      switch result {
      case .success:
        return state.loadFailureGeneration
      case .failure:
        state.loadFailureGeneration &+= 1
        state.blockedUntilSuccessfulLoad = true
        return nil
      }
    }
  }

  private func clearSaveBlockAfterSuccessfulDelivery(ifNoNewerFailureThan generation: UInt64) {
    saveProtectionState.withLock { state in
      if state.loadFailureGeneration == generation {
        state.blockedUntilSuccessfulLoad = false
      }
    }
  }
}

extension SecureAppStorageKey: CustomStringConvertible {
  public var description: String {
    ".secureAppStorage(\(String(reflecting: key)))"
  }
}

/// The in-memory Sharing identity of a secure app storage key.
public struct SecureAppStorageKeyID: Hashable {
  fileprivate let key: String
  fileprivate let store: UserDefaults
  fileprivate let crypto: SecureCryptoClient
}

private protocol Lookup<Value>: Sendable {
  associatedtype Value: Sendable

  func decodeValue(
    from encryptedData: Data,
    associatedDataKey: String,
    crypto: SecureCryptoClient
  ) throws -> Value

  func encodeValue(
    _ newValue: Value,
    associatedDataKey: String,
    crypto: SecureCryptoClient
  ) throws -> Data?
}

private struct CodableLookup<Value: Codable & Sendable>: Lookup {
  func decodeValue(
    from encryptedData: Data,
    associatedDataKey: String,
    crypto: SecureCryptoClient
  ) throws -> Value {
    let associatedData = Data(associatedDataKey.utf8)
    let clearData = try crypto.decrypt(encryptedData, associatedData)

    do {
      return try JSONDecoder().decode(Value.self, from: clearData)
    } catch {
      throw SecureStorageError.decodingFailed
    }
  }

  func encodeValue(
    _ newValue: Value,
    associatedDataKey: String,
    crypto: SecureCryptoClient
  ) throws -> Data? {
    let clearData: Data
    do {
      clearData = try JSONEncoder().encode(newValue)
    } catch {
      throw SecureStorageError.encodingFailed
    }

    let associatedData = Data(associatedDataKey.utf8)
    return try crypto.encrypt(clearData, associatedData)
  }
}

private struct RawRepresentableLookup<Value: RawRepresentable & Sendable>: Lookup
where Value.RawValue: Codable & Sendable {
  func decodeValue(
    from encryptedData: Data,
    associatedDataKey: String,
    crypto: SecureCryptoClient
  ) throws -> Value {
    let rawValue = try CodableLookup<Value.RawValue>().decodeValue(
      from: encryptedData,
      associatedDataKey: associatedDataKey,
      crypto: crypto
    )

    guard let value = Value(rawValue: rawValue) else {
      throw SecureStorageError.invalidRawRepresentable
    }

    return value
  }

  func encodeValue(
    _ newValue: Value,
    associatedDataKey: String,
    crypto: SecureCryptoClient
  ) throws -> Data? {
    try CodableLookup<Value.RawValue>().encodeValue(
      newValue.rawValue,
      associatedDataKey: associatedDataKey,
      crypto: crypto
    )
  }
}

private struct OptionalLookup<Base: Lookup>: Lookup {
  let base: Base

  func decodeValue(
    from encryptedData: Data,
    associatedDataKey: String,
    crypto: SecureCryptoClient
  ) throws -> Base.Value? {
    try base.decodeValue(
      from: encryptedData,
      associatedDataKey: associatedDataKey,
      crypto: crypto
    )
  }

  func encodeValue(
    _ newValue: Base.Value?,
    associatedDataKey: String,
    crypto: SecureCryptoClient
  ) throws -> Data? {
    guard let newValue else { return nil }
    return try base.encodeValue(newValue, associatedDataKey: associatedDataKey, crypto: crypto)
  }
}

private enum SharedSecureAppStorageLocals {
  @TaskLocal static var isSetting = false
}

private final class Observer: NSObject, @unchecked Sendable {
  private let didChange: @Sendable () -> Void

  init(didChange: @escaping @Sendable () -> Void) {
    self.didChange = didChange
    super.init()
  }

  override func observeValue(
    forKeyPath _: String?,
    of _: Any?,
    change _: [NSKeyValueChangeKey: Any]?,
    context _: UnsafeMutableRawPointer?
  ) {
    self.didChange()
  }
}

private func isEqual<T>(_ lhs: T, _ rhs: T) -> Bool? {
  func open<U: Equatable>(_ lhs: U) -> Bool {
    lhs == rhs as? U
  }

  guard let lhs = lhs as? any Equatable else {
    return nil
  }

  return open(lhs)
}

import Dependencies
import Foundation
import Sharing

extension SharedReaderKey {
  /// Creates a key for a JSON-encoded value stored in a generic-password Keychain item.
  ///
  /// The access group must be authorized by the target's signed entitlements. See
  /// <doc:KeychainStorage> for availability and cross-process reload behavior.
  public static func keychainStorage<Value: Codable & Sendable>(
    _ account: String,
    service: String,
    accessGroup: String,
    accessibility: SecureKeyStoreAccessibility = .afterFirstUnlockThisDeviceOnly
  ) -> Self where Self == KeychainStorageKey<Value> {
    KeychainStorageKey(
      item: KeychainStorageItem(
        service: service,
        account: account,
        accessGroup: accessGroup,
        accessibility: accessibility
      )
    )
  }
}

/// Persists a small Codable value as JSON in a generic-password Keychain item.
///
/// Changing the value's encoding requires an explicit migration of the stored item.
/// Keychain reads and writes are synchronous and may block the calling thread.
/// See <doc:KeychainStorage> for setup and cross-process behavior.
public struct KeychainStorageKey<Value: Codable & Sendable>: SharedKey {
  private let item: KeychainStorageItem
  private let client: KeychainStorageClient
  private let saveProtectionState = Locked(false)

  public var id: KeychainStorageKeyID {
    KeychainStorageKeyID(itemIdentity: item.identity, clientIdentity: client.identity)
  }

  fileprivate init(item: KeychainStorageItem) {
    @Dependency(\.keychainStorageClient) var keychainStorageClient
    self.item = item
    self.client = keychainStorageClient
  }

  public func load(context: LoadContext<Value>, continuation: LoadContinuation<Value>) {
    let result = Result {
      try item.validate()
      return try client.read(item).map(decode) ?? missingStoredValue(for: context)
    }
    recordLoadResultBeforeDelivery(result)
    continuation.resume(with: result)
  }

  public func subscribe(context _: LoadContext<Value>, subscriber _: SharedSubscriber<Value>)
    -> SharedSubscription
  {
    SharedSubscription {}
  }

  public func save(_ value: Value, context _: SaveContext, continuation: SaveContinuation) {
    continuation.resume(
      with: Result {
        try item.validate()
        if let existingData = try client.read(item) {
          _ = try decode(existingData)
        }
        guard !saveProtectionState.withLock({ $0 }) else {
          throw SecureStorageError.saveBlockedUntilSuccessfulLoad
        }
        if let data = try encode(value) {
          try client.write(data, item)
        } else {
          try client.delete(item)
        }
      })
  }

  private func decode(_ data: Data) throws -> Value {
    do { return try JSONDecoder().decode(Value.self, from: data) }
    catch { throw SecureStorageError.decodingFailed }
  }

  private func encode(_ value: Value) throws -> Data? {
    if let optional = value as? any NilValue, optional.isNil { return nil }
    do { return try JSONEncoder().encode(value) }
    catch { throw SecureStorageError.encodingFailed }
  }

  private func recordLoadResultBeforeDelivery(_ result: Result<Value?, any Error>) {
    saveProtectionState.withLock { state in
      switch result {
      case .success: state = false
      case .failure: state = true
      }
    }
  }
}

extension KeychainStorageKey: CustomStringConvertible {
  public var description: String {
    let account = String(reflecting: item.account)
    let service = String(reflecting: item.service)
    return ".keychainStorage(\(account), service: \(service))"
  }
}

public struct KeychainStorageKeyID: Hashable, Sendable {
  fileprivate let itemIdentity: KeychainStorageItem.Identity
  fileprivate let clientIdentity: UUID
}

private protocol NilValue {
  var isNil: Bool { get }
}

extension Optional: NilValue {
  fileprivate var isNil: Bool { self == nil }
}

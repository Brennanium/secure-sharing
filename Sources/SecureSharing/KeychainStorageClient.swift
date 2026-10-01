import Dependencies
import Foundation
import Security

/// The identity and creation policy of a generic-password Keychain item.
///
/// Service, account, and access group must be nonempty.
/// The access group must be authorized by every app or extension that uses this item.
/// Accessibility is used only when an item is created; it does not distinguish existing items.
public struct KeychainStorageItem: Hashable, Sendable {
  public let service: String
  public let account: String
  public let accessGroup: String
  public let accessibility: SecureKeyStoreAccessibility

  public init(
    service: String,
    account: String,
    accessGroup: String,
    accessibility: SecureKeyStoreAccessibility = .afterFirstUnlockThisDeviceOnly
  ) {
    self.service = service
    self.account = account
    self.accessGroup = accessGroup
    self.accessibility = accessibility
  }

  var identity: Identity {
    Identity(service: service, account: account, accessGroup: accessGroup)
  }

  func validate() throws {
    try validateKeychainConfiguration(
      service: service, account: account, accessGroup: accessGroup)
  }

  struct Identity: Hashable, Sendable {
    let service: String
    let account: String
    let accessGroup: String
  }
}

/// Replaceable Keychain operations used by `KeychainStorageKey`.
///
/// Tests use ``testValue`` automatically. Override the dependency to simulate specific responses.
public struct KeychainStorageClient: Sendable {
  let identity: UUID
  public var read: @Sendable (KeychainStorageItem) throws -> Data?
  public var write: @Sendable (Data, KeychainStorageItem) throws -> Void
  public var delete: @Sendable (KeychainStorageItem) throws -> Void

  public init(
    read: @escaping @Sendable (KeychainStorageItem) throws -> Data?,
    write: @escaping @Sendable (Data, KeychainStorageItem) throws -> Void,
    delete: @escaping @Sendable (KeychainStorageItem) throws -> Void
  ) {
    self.identity = UUID()
    self.read = read
    self.write = write
    self.delete = delete
  }
}

extension KeychainStorageClient: DependencyKey {
  public static var liveValue: Self { liveClient }

  private static let liveClient = Self(
    read: { item in
      var query = try keychainQuery(for: item)
      query[kSecMatchLimit as String] = kSecMatchLimitOne
      query[kSecReturnData as String] = true
      var result: CFTypeRef?
      let status = SecItemCopyMatching(query as CFDictionary, &result)
      switch status {
      case errSecSuccess:
        guard let data = result as? Data else { throw SecureStorageError.invalidStoredValue }
        return data
      case errSecItemNotFound:
        return nil
      default:
        throw keychainStorageError(status)
      }
    },
    write: { data, item in
      let query = try keychainQuery(for: item)
      let update = [kSecValueData as String: data]
      let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
      switch status {
      case errSecSuccess:
        return
      case errSecItemNotFound:
        var attributes = query
        attributes[kSecAttrAccessible as String] = item.accessibility.keychainValue
        attributes[kSecValueData as String] = data
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        switch addStatus {
        case errSecSuccess:
          return
        case errSecDuplicateItem:
          let retryStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
          guard retryStatus == errSecSuccess else { throw keychainStorageError(retryStatus) }
        default:
          throw keychainStorageError(addStatus)
        }
      default:
        throw keychainStorageError(status)
      }
    },
    delete: { item in
      let query = try keychainQuery(for: item)
      let status = SecItemDelete(query as CFDictionary)
      guard status == errSecSuccess || status == errSecItemNotFound else {
        throw keychainStorageError(status)
      }
    }
  )

  /// An in-memory item store for tests; it does not exercise signed Keychain access.
  public static var testValue: Self {
    let items = Locked<[KeychainStorageItem.Identity: Data]>([:])
    return Self(
      read: { item in items.withLock { $0[item.identity] } },
      write: { data, item in items.withLock { $0[item.identity] = data } },
      delete: { item in items.withLock { _ = $0.removeValue(forKey: item.identity) } }
    )
  }
}

extension DependencyValues {
  /// The Keychain operations used by ``KeychainStorageKey``.
  ///
  /// Tests use an in-memory client by default. Live use requires a signed target with an
  /// authorized access group. See <doc:KeychainStorage>.
  public var keychainStorageClient: KeychainStorageClient {
    get { self[KeychainStorageClient.self] }
    set { self[KeychainStorageClient.self] = newValue }
  }
}

private func keychainQuery(for item: KeychainStorageItem) throws -> [String: Any] {
  try item.validate()
  var query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: item.service,
    kSecAttrAccount as String: item.account,
    kSecUseDataProtectionKeychain as String: true,
  ]
  query[kSecAttrAccessGroup as String] = item.accessGroup
  return query
}

func validateKeychainConfiguration(
  service: String, account: String, accessGroup: String?
) throws {
  guard !service.isEmpty else {
    throw SecureStorageError.invalidKeychainConfiguration(field: .service)
  }
  guard !account.isEmpty else {
    throw SecureStorageError.invalidKeychainConfiguration(field: .account)
  }
  if let accessGroup, accessGroup.isEmpty {
    throw SecureStorageError.invalidKeychainConfiguration(field: .accessGroup)
  }
}

func keychainStorageError(_ status: OSStatus) -> SecureStorageError {
  switch status {
  case errSecInteractionNotAllowed:
    return .keychainInteractionNotAllowed
  case errSecMissingEntitlement:
    return .keychainMissingEntitlement
  default:
    return .keychainFailure(status: status)
  }
}

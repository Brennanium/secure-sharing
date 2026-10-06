import ConcurrencyExtras
import CryptoKit
import Dependencies
import Foundation
import IssueReporting
import Security
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The accessibility of a newly created Keychain item.
///
/// Changing this policy does not change an item already stored under the same identity.
public enum SecureKeyStoreAccessibility: Hashable, Sendable {
  /// Available only while unlocked on a device with a passcode.
  case whenPasscodeSetThisDeviceOnly
  /// Available only while unlocked; does not migrate to another device.
  case whenUnlockedThisDeviceOnly
  /// Available only while unlocked; can migrate with an encrypted backup.
  case whenUnlocked
  /// Available after the first unlock until restart; does not migrate to another device.
  case afterFirstUnlockThisDeviceOnly
  /// Available after the first unlock until restart; can migrate with an encrypted backup.
  case afterFirstUnlock

  var keychainValue: CFString {
    switch self {
    case .whenPasscodeSetThisDeviceOnly:
      kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
    case .whenUnlockedThisDeviceOnly:
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    case .whenUnlocked:
      kSecAttrAccessibleWhenUnlocked
    case .afterFirstUnlockThisDeviceOnly:
      kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    case .afterFirstUnlock:
      kSecAttrAccessibleAfterFirstUnlock
    }
  }
}

/// The stable Keychain identity used to encrypt a secure app storage value.
///
/// Service and account must be nonempty, as must an explicitly supplied access group.
public struct SecureKeyStoreID: Hashable, Sendable {
  public let service: String
  public let account: String
  public let accessGroup: String?

  public init(service: String, account: String, accessGroup: String? = nil) {
    self.service = service
    self.account = account
    self.accessGroup = accessGroup
  }
}

/// A source of symmetric keys for AES-GCM encryption.
public struct SecureKeyStoreClient: Sendable {
  public let id: SecureKeyStoreID
  /// Reads an existing key without creating one.
  public var loadSymmetricKey: @Sendable () throws -> SymmetricKey
  /// Creates a key only if one does not exist.
  public var loadOrCreateSymmetricKey: @Sendable () throws -> SymmetricKey

  public init(
    id: SecureKeyStoreID,
    loadSymmetricKey: @escaping @Sendable () throws -> SymmetricKey,
    loadOrCreateSymmetricKey: @escaping @Sendable () throws -> SymmetricKey
  ) {
    self.id = id
    self.loadSymmetricKey = loadSymmetricKey
    self.loadOrCreateSymmetricKey = loadOrCreateSymmetricKey
  }

  /// Creates a Keychain client using an app-owned, stable service and account.
  ///
  /// The accessibility applies only when creating a new Keychain item. Changing it does not
  /// update an existing item; changing the service, account, or access group does not migrate data.
  public static func keychain(
    service: String,
    account: String,
    accessGroup: String? = nil,
    accessibility: SecureKeyStoreAccessibility = .afterFirstUnlockThisDeviceOnly
  ) -> Self {
    let id = SecureKeyStoreID(service: service, account: account, accessGroup: accessGroup)
    let store = LiveSecureKeyStore(id: id, accessibility: accessibility)
    return Self(
      id: id,
      loadSymmetricKey: { try store.loadSymmetricKey() },
      loadOrCreateSymmetricKey: { try store.loadOrCreateSymmetricKey() }
    )
  }
}

/// An encryption strategy for secure app storage.
///
/// Use ``keychain(service:account:accessGroup:accessibility:)`` for a Keychain-backed key, or
/// ``CryptoKit/AES/GCM/secureAppStorage(keyStore:)`` for a custom symmetric-key source.
public struct SecureCryptoClient: Hashable, Sendable {
  private let identity: AnyHashableSendable
  let isConfigured: Bool
  /// Custom implementations must encrypt data and authenticate the associated data.
  public let encrypt: @Sendable (_ clearData: Data, _ associatedData: Data) throws -> Data
  /// Custom implementations must reject data when authentication fails.
  public let decrypt: @Sendable (_ cipherData: Data, _ associatedData: Data) throws -> Data

  private init<ID: Hashable & Sendable>(
    id: ID,
    isConfigured: Bool,
    encrypt: @escaping @Sendable (_ clearData: Data, _ associatedData: Data) throws -> Data,
    decrypt: @escaping @Sendable (_ cipherData: Data, _ associatedData: Data) throws -> Data
  ) {
    self.identity = AnyHashableSendable(id)
    self.isConfigured = isConfigured
    self.encrypt = encrypt
    self.decrypt = decrypt
  }

  /// Creates a strategy whose identity is used to share instances of the same storage key.
  ///
  /// Authenticate the associated data and use the same ID only for clients with compatible
  /// ciphertext formats and key material.
  public init<ID: Hashable & Sendable>(
    id: ID,
    encrypt: @escaping @Sendable (_ clearData: Data, _ associatedData: Data) throws -> Data,
    decrypt: @escaping @Sendable (_ cipherData: Data, _ associatedData: Data) throws -> Data
  ) {
    self.init(id: id, isConfigured: true, encrypt: encrypt, decrypt: decrypt)
  }

  static var unconfigured: Self {
    Self(
      id: UnconfiguredCryptoID(),
      isConfigured: false,
      encrypt: { _, _ in throw SecureStorageError.cryptoNotConfigured },
      decrypt: { _, _ in throw SecureStorageError.cryptoNotConfigured }
    )
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.identity == rhs.identity
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(identity)
  }

  /// Encrypts with AES-GCM using a Keychain-backed symmetric key.
  ///
  /// Accessibility applies only when creating the key. Changing the service, account, or access
  /// group does not migrate existing ciphertext.
  public static func keychain(
    service: String,
    account: String,
    accessGroup: String? = nil,
    accessibility: SecureKeyStoreAccessibility = .afterFirstUnlockThisDeviceOnly
  ) -> Self {
    AES.GCM.secureAppStorage(
      keyStore: .keychain(
        service: service,
        account: account,
        accessGroup: accessGroup,
        accessibility: accessibility
      )
    )
  }

  /// Uses a replaceable symmetric-key store, primarily for custom key sources and tests.
  @_documentation(visibility: private)
  public static func aesGCM(keyStore: SecureKeyStoreClient) -> Self {
    AES.GCM.secureAppStorage(keyStore: keyStore)
  }
}

private struct UnconfiguredCryptoID: Hashable, Sendable {}

extension AES.GCM {
  /// Creates a secure app storage crypto client using AES-GCM and the given key store.
  public static func secureAppStorage(keyStore: SecureKeyStoreClient) -> SecureCryptoClient {
    SecureCryptoClient(
      id: AESGCMKeyStoreIdentity(keyStoreID: keyStore.id),
      encrypt: { clearData, associatedData in
        let key = try keyStore.loadOrCreateSymmetricKey()
        do {
          let sealedBox = try AES.GCM.seal(clearData, using: key, authenticating: associatedData)
          guard let combined = sealedBox.combined else {
            throw SecureStorageError.encryptionFailed
          }
          return combined
        } catch let error as SecureStorageError {
          throw error
        } catch {
          throw SecureStorageError.encryptionFailed
        }
      },
      decrypt: { cipherData, associatedData in
        let key = try keyStore.loadSymmetricKey()
        do {
          let sealedBox = try AES.GCM.SealedBox(combined: cipherData)
          return try AES.GCM.open(sealedBox, using: key, authenticating: associatedData)
        } catch {
          throw SecureStorageError.decryptionFailed
        }
      }
    )
  }
}

private struct AESGCMKeyStoreIdentity: Hashable, Sendable {
  let keyStoreID: SecureKeyStoreID
}

extension SecureKeyStoreClient {
  static var inMemoryTestValue: SecureKeyStoreClient {
    let key = SymmetricKey(data: Data(repeating: 0xA5, count: 32))
    return SecureKeyStoreClient(
      id: SecureKeyStoreID(service: "SecureSharing.test", account: "in-memory"),
      loadSymmetricKey: { key },
      loadOrCreateSymmetricKey: { key }
    )
  }
}

private enum SecureAppStorageCryptoKey: DependencyKey {
  static var liveValue: SecureCryptoClient {
    if shouldReportUnimplemented {
      reportIssue(
        """
        Secure app storage has no encryption client. Configure \
        'secureAppStorageCrypto' with 'prepareDependencies' before using \
        'secureAppStorage', or provide a per-key 'crypto' override.
        """
      )
    }
    return .unconfigured
  }
  static var testValue: SecureCryptoClient {
    AES.GCM.secureAppStorage(keyStore: .inMemoryTestValue)
  }
}

private enum ProtectedDataDidBecomeAvailableNotificationKey: DependencyKey {
  static var liveValue: Notification.Name {
    #if os(macOS)
    .NSApplicationProtectedDataDidBecomeAvailable
    #else
    UIApplication.protectedDataDidBecomeAvailableNotification
    #endif
  }

  static var testValue: Notification.Name {
    Notification.Name("SecureStorageProtectedDataDidBecomeAvailable")
  }
}

extension DependencyValues {
  /// The default encryption client used by `secureAppStorage` keys.
  ///
  /// Set this in `prepareDependencies` before creating secure keys. In a live app, a missing
  /// client reports an issue and causes loads and saves to fail. See <doc:GettingStarted>.
  public var secureAppStorageCrypto: SecureCryptoClient {
    get { self[SecureAppStorageCryptoKey.self] }
    set { self[SecureAppStorageCryptoKey.self] = newValue }
  }

  /// A notification that prompts active `secureAppStorage` keys to retry loading.
  ///
  /// The live value is posted when protected files become available. It is a retry signal,
  /// not proof that a particular Keychain item is accessible.
  /// Override this dependency in tests to simulate an unlock notification.
  /// See <doc:AvailabilityAndFailures>.
  public var protectedDataDidBecomeAvailableNotification: Notification.Name {
    get { self[ProtectedDataDidBecomeAvailableNotificationKey.self] }
    set { self[ProtectedDataDidBecomeAvailableNotificationKey.self] = newValue }
  }
}

private final class LiveSecureKeyStore: Sendable {
  let id: SecureKeyStoreID
  let accessibility: SecureKeyStoreAccessibility

  init(id: SecureKeyStoreID, accessibility: SecureKeyStoreAccessibility) {
    self.id = id
    self.accessibility = accessibility
  }

  func loadOrCreateSymmetricKey() throws -> SymmetricKey {
    if let keyData = try self.readKeyData() {
      return try self.symmetricKey(from: keyData)
    }

    let newKey = SymmetricKey(size: .bits256)
    let newKeyData = newKey.withUnsafeBytes { Data($0) }

    do {
      try self.storeKeyData(newKeyData)
      return newKey
    } catch SecureStorageError.keychainFailure(let status) where status == errSecDuplicateItem {
      if let keyData = try self.readKeyData() {
        return try self.symmetricKey(from: keyData)
      }
      throw SecureStorageError.keyUnavailable
    }
  }

  func loadSymmetricKey() throws -> SymmetricKey {
    guard let data = try readKeyData() else {
      throw SecureStorageError.keyUnavailable
    }
    return try symmetricKey(from: data)
  }

  private func symmetricKey(from data: Data) throws -> SymmetricKey {
    guard data.count == 32 else {
      throw SecureStorageError.keyUnavailable
    }
    return SymmetricKey(data: data)
  }

  private func readKeyData() throws -> Data? {
    let query = try genericPasswordReadQuery(
      service: id.service, account: id.account, accessGroup: id.accessGroup)

    var dataRef: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &dataRef)

    switch status {
    case errSecSuccess:
      guard let data = dataRef as? Data else {
        throw SecureStorageError.keyUnavailable
      }
      return data
    case errSecItemNotFound:
      return nil
    default:
      throw keychainStorageError(status)
    }
  }

  private func storeKeyData(_ keyData: Data) throws {
    let query = try genericPasswordAddAttributes(
      service: id.service, account: id.account, accessGroup: id.accessGroup,
      accessibility: accessibility, data: keyData)

    let status = SecItemAdd(query as CFDictionary, nil)
    switch status {
    case errSecSuccess:
      return
    default:
      throw keychainStorageError(status)
    }
  }
}

import CryptoKit
import Dependencies
import Foundation
import Sharing
import Testing
@testable import SecureSharing

@Suite("Secure Storage Dependencies")
struct SecureStorageDependenciesTests {
  @Test("Missing live crypto reports a configuration issue", .dependency(\.context, .live))
  func missingLiveCryptoReportsIssue() {
    withKnownIssue {
      @Dependency(\.secureAppStorageCrypto) var crypto
      #expect(throws: SecureStorageError.cryptoNotConfigured) {
        try crypto.encrypt(Data(), Data())
      }
    } matching: {
      $0.description.contains("Secure app storage has no encryption client.")
    }
  }

  @Test("AES-GCM uses its key store")
  func aesGCMUsesKeyStore() throws {
    let key = SymmetricKey(data: Data(repeating: 0x42, count: 32))
    let reads = LockIsolated(0)
    let creations = LockIsolated(0)
    let crypto = AES.GCM.secureAppStorage(
      keyStore: SecureKeyStoreClient(
        id: SecureKeyStoreID(service: "test.service", account: "key"),
        loadSymmetricKey: {
          reads.withValue { $0 += 1 }
          return key
        },
        loadOrCreateSymmetricKey: {
          creations.withValue { $0 += 1 }
          return key
        }
      )
    )

    let associatedData = Data("token".utf8)
    let plaintext = Data("secret".utf8)
    let ciphertext = try crypto.encrypt(plaintext, associatedData)
    #expect(ciphertext != plaintext)
    #expect(creations.value == 1)
    #expect(reads.value == 0)
    #expect(try crypto.decrypt(ciphertext, associatedData) == plaintext)
    #expect(creations.value == 1)
    #expect(reads.value == 1)
  }

  @Test("Decryption never creates a missing key")
  func decryptionNeverCreatesMissingKey() {
    let creations = LockIsolated(0)
    let crypto = SecureCryptoClient.aesGCM(
      keyStore: SecureKeyStoreClient(
        id: SecureKeyStoreID(service: "test.service", account: "missing"),
        loadSymmetricKey: { throw SecureStorageError.keyUnavailable },
        loadOrCreateSymmetricKey: {
          creations.withValue { $0 += 1 }
          return SymmetricKey(size: .bits256)
        }
      )
    )

    #expect(throws: SecureStorageError.keyUnavailable) {
      try crypto.decrypt(Data([1, 2, 3]), Data("token".utf8))
    }
    #expect(creations.value == 0)
  }

  @Test("Empty encryption-key identifiers fail before accessing Keychain")
  func emptyEncryptionKeyIdentifiers() {
    let invalidIDs: [(SecureKeyStoreID, SecureStorageError.KeychainField)] = [
      (SecureKeyStoreID(service: "", account: "key"), .service),
      (SecureKeyStoreID(service: "test.service", account: ""), .account),
      (SecureKeyStoreID(service: "test.service", account: "key", accessGroup: ""), .accessGroup),
    ]

    for (id, field) in invalidIDs {
      let keyStore = SecureKeyStoreClient.keychain(
        service: id.service, account: id.account, accessGroup: id.accessGroup)
      let expectedError = SecureStorageError.invalidKeychainConfiguration(field: field)
      #expect(throws: expectedError) { try keyStore.loadSymmetricKey() }
      #expect(throws: expectedError) { try keyStore.loadOrCreateSymmetricKey() }
    }
  }

  @Test(
    "An unconfigured secure key never accesses UserDefaults",
    .dependency(\.secureAppStorageCrypto, .unconfigured)
  )
  func unconfiguredSecureKeyFailsBeforeAccessingStorage() async {
    let store = AccessRecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    let existingCiphertext = Data([1, 2, 3])
    store.set(existingCiphertext, forKey: "secure_existing")
    store.resetCounts()

    for name in ["missing", "existing"] {
      let key = SecureAppStorageKey<Int?>.secureAppStorage(name, store: store)

      await confirmation { confirm in
        key.load(
          context: .initialValue(42),
          continuation: LoadContinuation { result in
            #expect(throws: SecureStorageError.cryptoNotConfigured) { try result.get() }
            confirm()
          }
        )
      }
      for value: Int? in [42, nil] {
        await confirmation { confirm in
          key.save(
            value,
            context: .didSet,
            continuation: SaveContinuation { result in
              #expect(throws: SecureStorageError.cryptoNotConfigured) { try result.get() }
              confirm()
            }
          )
        }
      }
    }

    #expect(store.readCount.value == 0)
    #expect(store.writeCount.value == 0)
    #expect(store.data(forKey: "secure_missing") == nil)
    #expect(store.data(forKey: "secure_existing") == existingCiphertext)
  }

  @Test(
    "An explicit crypto client works without a configured default",
    .dependency(\.secureAppStorageCrypto, .unconfigured)
  )
  func explicitCryptoWithoutDefault() throws {
    let store = UserDefaults.inMemory
    let keyStore = inMemoryKeyStore(account: "explicit", byte: 0x42)
    let crypto = SecureCryptoClient.aesGCM(keyStore: keyStore)
    let key = SecureAppStorageKey<String>.secureAppStorage(
      "token", store: store, crypto: crypto)

    let loadedValue = LockIsolated<String?>(nil)
    key.load(
      context: .initialValue("initial"),
      continuation: LoadContinuation { result in
        if case .success(let value) = result { loadedValue.setValue(value) }
      }
    )
    #expect(loadedValue.value == "initial")

    key.save("secret", context: .didSet, continuation: SaveContinuation { _ in })
    let ciphertext = try #require(store.data(forKey: "secure_token"))
    #expect(try crypto.decrypt(ciphertext, Data("token".utf8)) == Data(#""secret""#.utf8))

    loadedValue.setValue(nil)
    key.load(
      context: .initialValue("initial"),
      continuation: LoadContinuation { result in
        if case .success(let value) = result { loadedValue.setValue(value) }
      }
    )
    #expect(loadedValue.value == "secret")
  }

  @Test("An explicit crypto client overrides the default for encryption and identity")
  func explicitCryptoOverridesDefault() throws {
    let store = UserDefaults.inMemory
    let defaultCrypto = SecureCryptoClient.aesGCM(
      keyStore: inMemoryKeyStore(account: "default", byte: 0x11))
    let alternateBackend = SecureCryptoClient.aesGCM(
      keyStore: inMemoryKeyStore(account: "alternate", byte: 0x22))
    let alternateCrypto = SecureCryptoClient(
      id: AlternateCryptoID(key: "test.alternate"),
      encrypt: alternateBackend.encrypt,
      decrypt: alternateBackend.decrypt
    )
    #expect(alternateCrypto != alternateBackend)
    let (defaultKey, alternateKey, sameKeyWithAlternateCrypto) = withDependencies {
      $0.secureAppStorageCrypto = defaultCrypto
    } operation: {
      (
        SecureAppStorageKey<String>.secureAppStorage("default", store: store),
        SecureAppStorageKey<String>.secureAppStorage(
          "alternate", store: store, crypto: alternateCrypto),
        SecureAppStorageKey<String>.secureAppStorage(
          "default", store: store, crypto: alternateCrypto)
      )
    }
    #expect(defaultKey.id != sameKeyWithAlternateCrypto.id)

    defaultKey.save("first", context: .didSet, continuation: SaveContinuation { _ in })
    alternateKey.save("second", context: .didSet, continuation: SaveContinuation { _ in })
    let defaultCiphertext = try #require(store.data(forKey: "secure_default"))
    let alternateCiphertext = try #require(store.data(forKey: "secure_alternate"))
    #expect(
      try defaultCrypto.decrypt(defaultCiphertext, Data("default".utf8))
        == Data(#""first""#.utf8)
    )
    #expect(
      try alternateCrypto.decrypt(alternateCiphertext, Data("alternate".utf8))
        == Data(#""second""#.utf8)
    )
    #expect(throws: SecureStorageError.decryptionFailed) {
      try defaultCrypto.decrypt(alternateCiphertext, Data("alternate".utf8))
    }
  }

  @Test("Keychain identity is part of shared key identity")
  func keychainIdentityIsPartOfSharedKeyIdentity() {
    let store = UserDefaults.inMemory
    let keyStore = SecureKeyStoreClient.keychain(service: "test.service", account: "first")
    let aesGCM = AES.GCM.secureAppStorage(keyStore: keyStore)
    #expect(
      SecureCryptoClient.keychain(service: "test.service", account: "first")
        == aesGCM
    )
    #expect(SecureCryptoClient.aesGCM(keyStore: keyStore) == aesGCM)
    let first = withDependencies {
      $0.secureAppStorageCrypto = .keychain(service: "test.service", account: "first")
    } operation: {
      SecureAppStorageKey<Int>.secureAppStorage("count", store: store)
    }
    let second = withDependencies {
      $0.secureAppStorageCrypto = .keychain(service: "test.service", account: "second")
    } operation: {
      SecureAppStorageKey<Int>.secureAppStorage("count", store: store)
    }

    #expect(first.id != second.id)
  }

  @Test("Accessibility does not change the Keychain or shared key identity")
  func accessibilityIsCreationPolicy() {
    let store = UserDefaults.inMemory
    let defaultClient = SecureCryptoClient.keychain(service: "test.service", account: "key")
    let customClient = SecureCryptoClient.keychain(
      service: "test.service",
      account: "key",
      accessibility: .whenUnlockedThisDeviceOnly
    )

    #expect(defaultClient == customClient)

    let first = withDependencies {
      $0.secureAppStorageCrypto = defaultClient
    } operation: {
      SecureAppStorageKey<Int>.secureAppStorage("count", store: store)
    }
    let second = withDependencies {
      $0.secureAppStorageCrypto = customClient
    } operation: {
      SecureAppStorageKey<Int>.secureAppStorage("count", store: store)
    }
    #expect(first.id == second.id)
  }

  @Test("Missing keys cannot overwrite or delete existing ciphertext")
  func missingKeysCannotOverwriteExistingCiphertext() {
    let store = UserDefaults.inMemory
    let ciphertext = Data([1, 2, 3])
    store.set(ciphertext, forKey: "secure_token")
    let creations = LockIsolated(0)
    let key = withDependencies {
      $0.secureAppStorageCrypto = .aesGCM(
        keyStore: SecureKeyStoreClient(
          id: SecureKeyStoreID(service: "test.service", account: "lost"),
          loadSymmetricKey: { throw SecureStorageError.keyUnavailable },
          loadOrCreateSymmetricKey: {
            creations.withValue { $0 += 1 }
            return SymmetricKey(size: .bits256)
          }
        )
      )
    } operation: {
      SecureAppStorageKey<Int?>.secureAppStorage("token", store: store)
    }

    for value: Int? in [42, nil] {
      let error = LockIsolated<SecureStorageError?>(nil)
      key.save(
        value,
        context: .didSet,
        continuation: SaveContinuation { result in
          if case .failure(let failure) = result {
            error.setValue(failure as? SecureStorageError)
          }
        }
      )
      #expect(error.value == .keyUnavailable)
      #expect(store.data(forKey: "secure_token") == ciphertext)
    }
    #expect(creations.value == 0)
  }
}

private struct AlternateCryptoID: Hashable, Sendable {
  let key: String
}

private final class AccessRecordingUserDefaults: UserDefaults {
  let readCount = LockIsolated(0)
  let writeCount = LockIsolated(0)

  override func object(forKey defaultName: String) -> Any? {
    readCount.withValue { $0 += 1 }
    return super.object(forKey: defaultName)
  }

  override func set(_ value: Any?, forKey defaultName: String) {
    writeCount.withValue { $0 += 1 }
    super.set(value, forKey: defaultName)
  }

  override func removeObject(forKey defaultName: String) {
    writeCount.withValue { $0 += 1 }
    super.removeObject(forKey: defaultName)
  }

  func resetCounts() {
    readCount.setValue(0)
    writeCount.setValue(0)
  }
}

private func inMemoryKeyStore(account: String, byte: UInt8) -> SecureKeyStoreClient {
  let key = SymmetricKey(data: Data(repeating: byte, count: 32))
  return SecureKeyStoreClient(
    id: SecureKeyStoreID(service: "test.service", account: account),
    loadSymmetricKey: { key },
    loadOrCreateSymmetricKey: { key }
  )
}

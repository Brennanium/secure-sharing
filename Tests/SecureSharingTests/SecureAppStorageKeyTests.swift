import Dependencies
import DependenciesTestSupport
import Foundation
import SecureSharing
import Sharing
import Testing

@Suite("Secure App Storage Key", .dependency(\.defaultAppStorage, .inMemory))
struct SecureAppStorageKeyTests {
  @Dependency(\.defaultAppStorage) var store
  @Dependency(\.secureAppStorageCrypto) private var secureCrypto

  @Test func bool() throws {
    @Shared(.secureAppStorage("bool")) var bool = true
    #expect(store.data(forKey: secureStoreKey("bool")) == nil)

    $bool.withLock { $0 = false }
    #expect(
      try decryptedStoreValue(Bool.self, key: "bool", store: store, crypto: secureCrypto) == false)

    try writeEncryptedStoreValue(true, key: "bool", store: store, crypto: secureCrypto)
    #expect(bool)
  }

  @Test func int() throws {
    @Shared(.secureAppStorage("int")) var int = 42
    #expect(store.data(forKey: secureStoreKey("int")) == nil)

    $int.withLock { $0 = 1729 }
    #expect(
      try decryptedStoreValue(Int.self, key: "int", store: store, crypto: secureCrypto) == 1729)

    try writeEncryptedStoreValue(123, key: "int", store: store, crypto: secureCrypto)
    #expect(int == 123)
  }

  @Test func double() throws {
    @Shared(.secureAppStorage("double")) var double = 1.2
    #expect(store.data(forKey: secureStoreKey("double")) == nil)

    $double.withLock { $0 = 3.4 }
    #expect(
      try decryptedStoreValue(Double.self, key: "double", store: store, crypto: secureCrypto) == 3.4
    )

    try writeEncryptedStoreValue(5.6, key: "double", store: store, crypto: secureCrypto)
    #expect(double == 5.6)
  }

  @Test func string() throws {
    @Shared(.secureAppStorage("string")) var string = "Blob"
    #expect(store.data(forKey: secureStoreKey("string")) == nil)

    $string.withLock { $0 = "Blob, Jr." }
    #expect(
      try decryptedStoreValue(String.self, key: "string", store: store, crypto: secureCrypto)
        == "Blob, Jr.")

    try writeEncryptedStoreValue("Blob III", key: "string", store: store, crypto: secureCrypto)
    #expect(string == "Blob III")
  }

  @Test func stringArray() throws {
    @Shared(.secureAppStorage("string-array")) var stringArray = ["Blob"]
    #expect(store.data(forKey: secureStoreKey("string-array")) == nil)

    $stringArray.withLock { $0 = ["Blob", "Blob, Jr."] }
    #expect(
      try decryptedStoreValue(
        [String].self, key: "string-array", store: store, crypto: secureCrypto)
        == ["Blob", "Blob, Jr."]
    )

    try writeEncryptedStoreValue(
      ["Blob III"], key: "string-array", store: store, crypto: secureCrypto)
    #expect(stringArray == ["Blob III"])
  }

  @Test func url() throws {
    @Shared(.secureAppStorage("url")) var url = URL(fileURLWithPath: "/dev")
    #expect(store.data(forKey: secureStoreKey("url")) == nil)

    let tmpURL = URL(fileURLWithPath: "/tmp")
    $url.withLock { $0 = tmpURL }
    #expect(
      try decryptedStoreValue(URL.self, key: "url", store: store, crypto: secureCrypto) == tmpURL)

    let usrURL = URL(fileURLWithPath: "/usr")
    try writeEncryptedStoreValue(usrURL, key: "url", store: store, crypto: secureCrypto)
    #expect(url == usrURL)
  }

  @Test func optionalURL() throws {
    @Shared(.secureAppStorage("optional-url")) var url: URL? = URL(fileURLWithPath: "/dev")
    #expect(store.data(forKey: secureStoreKey("optional-url")) == nil)

    let tmpURL = URL(fileURLWithPath: "/tmp")
    $url.withLock { $0 = tmpURL }
    #expect(
      try decryptedStoreValue(URL.self, key: "optional-url", store: store, crypto: secureCrypto)
        == tmpURL)

    $url.withLock { $0 = nil }
    #expect(url == nil)
    #expect(store.data(forKey: secureStoreKey("optional-url")) == nil)
  }

  @Test func data() throws {
    @Shared(.secureAppStorage("data")) var data = Data([4, 2])
    #expect(store.data(forKey: secureStoreKey("data")) == nil)

    $data.withLock { $0 = Data([1, 7, 2, 9]) }
    #expect(
      try decryptedStoreValue(Data.self, key: "data", store: store, crypto: secureCrypto)
        == Data([1, 7, 2, 9]))

    try writeEncryptedStoreValue(Data([9, 9]), key: "data", store: store, crypto: secureCrypto)
    #expect(data == Data([9, 9]))
  }

  @Test func date() throws {
    @Shared(.secureAppStorage("date")) var date = Date(timeIntervalSinceReferenceDate: 0)
    #expect(store.data(forKey: secureStoreKey("date")) == nil)

    let newDate = Date(timeIntervalSince1970: 0)
    $date.withLock { $0 = newDate }
    #expect(
      try decryptedStoreValue(Date.self, key: "date", store: store, crypto: secureCrypto) == newDate
    )

    let futureDate = Date(timeIntervalSince1970: 86_400)
    try writeEncryptedStoreValue(futureDate, key: "date", store: store, crypto: secureCrypto)
    #expect(date == futureDate)
  }

  @Test func codable() throws {
    struct Item: Codable, Equatable, Sendable {
      var id: Int
    }

    @Shared(.secureAppStorage("codable")) var item = Item(id: 42)
    #expect(store.data(forKey: secureStoreKey("codable")) == nil)

    $item.withLock { $0 = Item(id: 1729) }
    #expect(
      try decryptedStoreValue(Item.self, key: "codable", store: store, crypto: secureCrypto)
        == Item(id: 1729))

    try writeEncryptedStoreValue(Item(id: 99), key: "codable", store: store, crypto: secureCrypto)
    #expect(item == Item(id: 99))
  }

  @Test func rawRepresentableInt() throws {
    struct ID: RawRepresentable, Equatable, Sendable {
      var rawValue: Int
    }

    @Shared(.secureAppStorage("raw-int")) var id = ID(rawValue: 42)
    #expect(store.data(forKey: secureStoreKey("raw-int")) == nil)

    $id.withLock { $0 = ID(rawValue: 1729) }
    #expect(
      try decryptedStoreValue(Int.self, key: "raw-int", store: store, crypto: secureCrypto) == 1729)

    try writeEncryptedStoreValue(123, key: "raw-int", store: store, crypto: secureCrypto)
    #expect(id == ID(rawValue: 123))
  }

  @Test func rawRepresentableString() throws {
    struct ID: RawRepresentable, Equatable, Sendable {
      var rawValue: String
    }

    @Shared(.secureAppStorage("raw-string")) var id = ID(rawValue: "Blob")
    #expect(store.data(forKey: secureStoreKey("raw-string")) == nil)

    $id.withLock { $0 = ID(rawValue: "Blob, Jr.") }
    #expect(
      try decryptedStoreValue(String.self, key: "raw-string", store: store, crypto: secureCrypto)
        == "Blob, Jr.")

    try writeEncryptedStoreValue("Blob III", key: "raw-string", store: store, crypto: secureCrypto)
    #expect(id == ID(rawValue: "Blob III"))
  }

  @Test func rawRepresentableCodableString() throws {
    struct ID: Codable, RawRepresentable, Equatable, Sendable {
      var rawValue: String
    }

    @Shared(.secureAppStorage("raw-codable-string")) var id = ID(rawValue: "Blob")
    #expect(store.data(forKey: secureStoreKey("raw-codable-string")) == nil)

    $id.withLock { $0 = ID(rawValue: "Blob, Jr.") }
    #expect(
      try decryptedStoreValue(
        String.self, key: "raw-codable-string", store: store, crypto: secureCrypto)
        == "Blob, Jr."
    )

    try writeEncryptedStoreValue(
      "Blob III", key: "raw-codable-string", store: store, crypto: secureCrypto)
    #expect(id == ID(rawValue: "Blob III"))
  }

  @Test func optionalRawRepresentableCodableString() throws {
    struct ID: Codable, RawRepresentable, Equatable, Sendable {
      var rawValue: String
    }

    @Shared(.secureAppStorage("optional-raw-codable-string")) var id: ID?
    #expect(store.data(forKey: secureStoreKey("optional-raw-codable-string")) == nil)

    $id.withLock { $0 = ID(rawValue: "Blob") }
    #expect(
      try decryptedStoreValue(
        String.self, key: "optional-raw-codable-string", store: store, crypto: secureCrypto)
        == "Blob"
    )

    try writeEncryptedStoreValue(
      "Blob, Jr.", key: "optional-raw-codable-string", store: store, crypto: secureCrypto)
    #expect(id == ID(rawValue: "Blob, Jr."))

    $id.withLock { $0 = nil }
    #expect(store.data(forKey: secureStoreKey("optional-raw-codable-string")) == nil)
  }

  @Test func optional() throws {
    @Shared(.secureAppStorage("optional-bool")) var bool: Bool?
    #expect(store.data(forKey: secureStoreKey("optional-bool")) == nil)

    try writeEncryptedStoreValue(false, key: "optional-bool", store: store, crypto: secureCrypto)
    #expect(bool == false)

    $bool.withLock { $0 = nil }
    #expect(store.data(forKey: secureStoreKey("optional-bool")) == nil)
  }

  @Test func optionalDefault() throws {
    @Shared(.secureAppStorage("optional-default-bool")) var bool: Bool? = true

    #expect(bool == true)
    #expect(store.data(forKey: secureStoreKey("optional-default-bool")) == nil)

    try writeEncryptedStoreValue(
      false, key: "optional-default-bool", store: store, crypto: secureCrypto)
    #expect(bool == false)

    store.removeObject(forKey: secureStoreKey("optional-default-bool"))
    #expect(bool == true)

    $bool.withLock { $0 = nil }
    #expect(bool == nil)
    #expect(store.data(forKey: secureStoreKey("optional-default-bool")) == nil)
  }

  @Test("Load does not mutate UserDefaults")
  func loadDoesNotMutateUserDefaults() throws {
    let store = RecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    @Shared(.secureAppStorage("missing", store: store)) var missing = 123
    #expect(missing == 123)
    #expect(store.writeCount.value == 0)

    try writeEncryptedStoreValue(42, key: "existing", store: store, crypto: secureCrypto)
    store.writeCount.setValue(0)
    @Shared(.secureAppStorage("existing", store: store)) var existing = 0
    #expect(existing == 42)
    #expect(store.writeCount.value == 0)
  }

  @Test("Corrupt ciphertext reports an error without overwriting it")
  func corruptCiphertextDoesNotGetOverwritten() {
    let ciphertext = Data([1, 2, 3])
    store.set(ciphertext, forKey: secureStoreKey("corrupt"))
    let key: SecureAppStorageKey<Int> = .secureAppStorage("corrupt")
    let error = LockIsolated<SecureStorageError?>(nil)

    key.load(
      context: .initialValue(0),
      continuation: LoadContinuation { result in
        if case .failure(let failure) = result {
          error.setValue(failure as? SecureStorageError)
        }
      }
    )

    #expect(error.value == .decryptionFailed)
    #expect(store.data(forKey: secureStoreKey("corrupt")) == ciphertext)
  }

  @Test("A non-Data stored value cannot be loaded, replaced, or removed")
  func invalidStoredValueIsNotTreatedAsMissing() {
    let store = RecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    store.set("unexpected", forKey: secureStoreKey("invalid"))
    store.writeCount.setValue(0)
    let key: SecureAppStorageKey<Int?> = .secureAppStorage("invalid", store: store)

    key.load(
      context: .initialValue(42),
      continuation: LoadContinuation { result in
        #expect(throws: SecureStorageError.invalidStoredValue) { try result.get() }
      }
    )
    for value: Int? in [1, nil] {
      key.save(
        value,
        context: .didSet,
        continuation: SaveContinuation { result in
          #expect(throws: SecureStorageError.invalidStoredValue) { try result.get() }
        }
      )
    }
    #expect(store.object(forKey: secureStoreKey("invalid")) as? String == "unexpected")
    #expect(store.writeCount.value == 0)
  }

  @Test("Authenticated but undecodable ciphertext cannot be replaced or removed")
  func undecodableCiphertextIsNotOverwritten() throws {
    let store = RecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    let ciphertext = try secureCrypto.encrypt(Data("not-json".utf8), Data("undecodable".utf8))
    store.set(ciphertext, forKey: secureStoreKey("undecodable"))
    store.writeCount.setValue(0)
    let key: SecureAppStorageKey<Int?> = .secureAppStorage("undecodable", store: store)

    key.load(
      context: .initialValue(42),
      continuation: LoadContinuation { result in
        #expect(throws: SecureStorageError.decodingFailed) { try result.get() }
      }
    )
    for value: Int? in [1, nil] {
      key.save(
        value,
        context: .didSet,
        continuation: SaveContinuation { result in
          #expect(throws: SecureStorageError.decodingFailed) { try result.get() }
        }
      )
    }
    #expect(store.data(forKey: secureStoreKey("undecodable")) == ciphertext)
    #expect(store.writeCount.value == 0)
  }

  @Test("Readiness changes during a read or save do not succeed")
  func readinessChangeDuringProcessing() throws {
    let store = RecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    let originalCrypto = secureCrypto
    let ready = LockIsolated(true)
    let status = SecureStorageStatusClient(
      isProtectedDataAvailable: { ready.value },
      protectedDataDidBecomeAvailableNotification: Notification.Name("test.protected")
    )
    let ciphertext = try encryptedPayload(42, key: "transition", crypto: originalCrypto)
    store.set(ciphertext, forKey: secureStoreKey("transition"))
    store.writeCount.setValue(0)

    let (readKey, saveKey) = withDependencies {
      $0.secureAppStorageCrypto = SecureCryptoClient(
        id: "test.readiness-transition",
        encrypt: { data, associatedData in
          ready.setValue(false)
          return try originalCrypto.encrypt(data, associatedData)
        },
        decrypt: { data, associatedData in
          let clearData = try originalCrypto.decrypt(data, associatedData)
          ready.setValue(false)
          return clearData
        }
      )
    } operation: {
      (
        SecureAppStorageKey<Int>.secureAppStorage("transition", store: store),
        SecureAppStorageKey<Int>.secureAppStorage("new", store: store)
      )
    }

    withDependencies {
      $0.secureStorageStatus = status
    } operation: {
      readKey.load(
        context: .initialValue(0),
        continuation: LoadContinuation { result in
          #expect(throws: SecureStorageError.protectedDataUnavailable) { try result.get() }
        }
      )
      ready.setValue(true)
      saveKey.save(
        99,
        context: .didSet,
        continuation: SaveContinuation { result in
          #expect(throws: SecureStorageError.protectedDataUnavailable) { try result.get() }
        }
      )
    }
    #expect(store.data(forKey: secureStoreKey("transition")) == ciphertext)
    #expect(store.data(forKey: secureStoreKey("new")) == nil)
    #expect(store.writeCount.value == 0)
  }

  @Test("A failed initial load blocks saves until the shared value is reloaded")
  func failedLoadRequiresReloadBeforeSave() async throws {
    let store = UserDefaults.inMemory
    let ciphertext = try encryptedPayload(42, key: "stale", crypto: secureCrypto)
    store.set(ciphertext, forKey: secureStoreKey("stale"))
    let ready = LockIsolated(false)

    try await withDependencies {
      $0.secureStorageStatus = SecureStorageStatusClient(
        isProtectedDataAvailable: { ready.value },
        protectedDataDidBecomeAvailableNotification: Notification.Name("test.protected")
      )
    } operation: {
      @Shared(.secureAppStorage("stale", store: store)) var count = 0
      #expect($count.loadError as? SecureStorageError == .protectedDataUnavailable)

      ready.setValue(true)
      $count.withLock { $0 = 1 }
      #expect($count.saveError as? SecureStorageError == .saveBlockedUntilSuccessfulLoad)
      #expect(store.data(forKey: secureStoreKey("stale")) == ciphertext)

      try await $count.load()
      #expect(count == 42)
      #expect(store.data(forKey: secureStoreKey("stale")) == ciphertext)
    }
  }

  @Test("Saved value is not plaintext JSON")
  func savedValueIsNotPlaintextJSON() throws {
    @Shared(.secureAppStorage("token")) var token = "seed"
    $token.withLock { $0 = "super-secret-token" }

    let encrypted = try #require(store.data(forKey: secureStoreKey("token")))
    let plaintext = try JSONEncoder().encode("super-secret-token")
    #expect(encrypted != plaintext)
    #expect(
      try decryptedStoreValue(String.self, key: "token", store: store, crypto: secureCrypto)
        == token)
  }

  @Test func invalidKeyWarning() async {
    await withKnownIssue {
      @Shared(.secureAppStorage("co.pointfree.isEnabled")) var isEnabled = false
      let encrypted = try! encryptedPayload(
        true, key: "co.pointfree.isEnabled", crypto: secureCrypto)
      store.set(encrypted, forKey: secureStoreKey("co.pointfree.isEnabled"))
      await MainActor.run {
        #expect(isEnabled)
      }
    } matching: {
      $0.description.contains(
        #"A Shared secure app storage key ("co.pointfree.isEnabled") contains an invalid character (".")"#
      )
    }

    await withKnownIssue {
      @Shared(.secureAppStorage("@count")) var count = 0
      let encrypted = try! encryptedPayload(42, key: "@count", crypto: secureCrypto)
      store.set(encrypted, forKey: secureStoreKey("@count"))
      await MainActor.run {
        #expect(count == 42)
      }
    } matching: {
      $0.description.contains(
        #"A Shared secure app storage key ("@count") contains an invalid character ("@")"#
      )
    }
  }

  @Test(.dependency(\.appStorageKeyFormatWarningEnabled, false))
  func invalidKeyWarningSuppression() {
    @Shared(.secureAppStorage("co.pointfree.isEnabled")) var isEnabled = false
    @Shared(.secureAppStorage("@count")) var count = 0
    _ = isEnabled
    _ = count
  }

  @Test func testPersistenceKeySubscription() async throws {
    let persistenceKey: SecureAppStorageKey<Int> = .secureAppStorage("shared")
    let changes = LockIsolated<[Result<Int?, any Error>]>([])
    var subscription: SharedSubscription? = persistenceKey.subscribe(
      context: .userInitiated,
      subscriber: SharedSubscriber { value in
        changes.withValue { $0.append(value) }
      }
    )

    try writeEncryptedStoreValue(1, key: "shared", store: store, crypto: secureCrypto)
    try writeEncryptedStoreValue(42, key: "shared", store: store, crypto: secureCrypto)
    subscription?.cancel()
    try writeEncryptedStoreValue(123, key: "shared", store: store, crypto: secureCrypto)
    subscription = nil

    #expect(try changes.value.map { try $0.get() } == [1, 42])

    await confirmation { confirm in
      persistenceKey.load(
        context: .userInitiated,
        continuation: LoadContinuation { result in
          let success = try? result.get()
          #expect(success == 123)
          confirm()
        }
      )
    }
  }

  @Test(
    "Protected data unavailable blocks load/save and writes",
    .dependency(
      \.secureStorageStatus,
      SecureStorageStatusClient(
        isProtectedDataAvailable: { false },
        protectedDataDidBecomeAvailableNotification: Notification.Name("test.protected")
      )
    )
  )
  func protectedDataUnavailableBlocksLoadAndSaveAndWrites() throws {
    let key: SecureAppStorageKey<Int> = .secureAppStorage("blocked-count")
    let existingData = try encryptedPayload(99, key: "blocked-count", crypto: secureCrypto)
    store.set(existingData, forKey: secureStoreKey("blocked-count"))

    let loadHadProtectedDataError = LockIsolated<Bool?>(nil)
    key.load(
      context: .initialValue(0),
      continuation: LoadContinuation { result in
        loadHadProtectedDataError.setValue(isProtectedDataUnavailable(result))
      })
    #expect(loadHadProtectedDataError.value == true)

    let saveHadProtectedDataError = LockIsolated<Bool?>(nil)
    key.save(
      1, context: .didSet,
      continuation: SaveContinuation { result in
        saveHadProtectedDataError.setValue(isProtectedDataUnavailable(result))
      })
    #expect(saveHadProtectedDataError.value == true)

    #expect(store.data(forKey: secureStoreKey("blocked-count")) == existingData)
  }

  @Test("Protected data transition reloads value and unblocks saves")
  func protectedDataTransitionReloadsValueAndUnblocksSaves() async throws {
    let key: SecureAppStorageKey<Int> = .secureAppStorage("transition-count")
    let ready = LockIsolated(false)
    let notificationName = Notification.Name("test.protected-data-became-available")
    let capturedResults = LockIsolated<[Result<Int?, any Error>]>([])

    try await withDependencies {
      $0.secureStorageStatus = SecureStorageStatusClient(
        isProtectedDataAvailable: { ready.value },
        protectedDataDidBecomeAvailableNotification: notificationName
      )
    } operation: {
      try writeEncryptedStoreValue(42, key: "transition-count", store: store, crypto: secureCrypto)
      let originalEncrypted = store.data(forKey: secureStoreKey("transition-count"))
      #expect(capturedResults.value.isEmpty)
      let didConfirm = LockIsolated(false)

      key.load(
        context: .initialValue(0),
        continuation: LoadContinuation { result in
          #expect(throws: SecureStorageError.protectedDataUnavailable) { try result.get() }
        }
      )

      await confirmation { confirm in
        let subscription = key.subscribe(
          context: .initialValue(0),
          subscriber: SharedSubscriber { result in
            capturedResults.withValue { $0.append(result) }
            if didConfirm.value == false {
              didConfirm.setValue(true)
              confirm()
            }
          }
        )
        defer { subscription.cancel() }

        ready.setValue(true)
        NotificationCenter.default.post(name: notificationName, object: nil)
      }

      let capturedValues = try capturedResults.value.map { try $0.get() }
      #expect(capturedValues.contains(42))
      #expect(store.data(forKey: secureStoreKey("transition-count")) == originalEncrypted)

      let saveSucceeded = LockIsolated(false)
      key.save(
        43,
        context: .didSet,
        continuation: SaveContinuation { result in
          if case .success = result { saveSucceeded.setValue(true) }
        }
      )
      #expect(saveSucceeded.value)
      #expect(
        try decryptedStoreValue(Int.self, key: "transition-count", store: store, crypto: secureCrypto)
          == 43
      )
    }
  }
}

private func encryptedPayload<Value: Codable>(
  _ value: Value,
  key: String,
  crypto: SecureCryptoClient
) throws -> Data {
  let encoded = try JSONEncoder().encode(value)
  return try crypto.encrypt(encoded, Data(key.utf8))
}

private func writeEncryptedStoreValue<Value: Codable>(
  _ value: Value,
  key: String,
  store: UserDefaults,
  crypto: SecureCryptoClient
) throws {
  let encrypted = try encryptedPayload(value, key: key, crypto: crypto)
  store.set(encrypted, forKey: secureStoreKey(key))
}

private func decryptedStoreValue<Value: Codable>(
  _ type: Value.Type,
  key: String,
  store: UserDefaults,
  crypto: SecureCryptoClient
) throws -> Value? {
  guard let encrypted = store.data(forKey: secureStoreKey(key)) else {
    return nil
  }

  let clear = try crypto.decrypt(encrypted, Data(key.utf8))
  return try JSONDecoder().decode(Value.self, from: clear)
}

private func isProtectedDataUnavailable<T>(_ result: Result<T?, any Error>) -> Bool {
  guard case .failure(let error) = result,
    let secureError = error as? SecureStorageError
  else {
    return false
  }
  return secureError == .protectedDataUnavailable
}

private func secureStoreKey(_ key: String) -> String {
  "secure_\(key)"
}

private final class RecordingUserDefaults: UserDefaults {
  let writeCount = LockIsolated(0)

  override func set(_ value: Any?, forKey defaultName: String) {
    writeCount.withValue { $0 += 1 }
    super.set(value, forKey: defaultName)
  }

  override func removeObject(forKey defaultName: String) {
    writeCount.withValue { $0 += 1 }
    super.removeObject(forKey: defaultName)
  }
}

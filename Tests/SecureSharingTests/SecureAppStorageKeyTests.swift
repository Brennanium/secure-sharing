import Combine
import CryptoKit
import Dependencies
import DependenciesTestSupport
import Foundation
import IssueReporting
import SecureSharing
import Sharing
import Testing

@Suite("Secure App Storage Key", .dependency(\.defaultAppStorage, .inMemory))
struct SecureAppStorageKeyTests {
  @Dependency(\.defaultAppStorage) var store
  @Dependency(\.secureAppStorageCrypto) private var secureCrypto

  @Test("A type-safe default does not write to UserDefaults during load")
  func typeSafeDefault() async throws {
    @Shared(.defaultPrivateNotes) var privateNotes

    #expect(privateNotes.isEmpty)
    #expect(store.data(forKey: secureStoreKey("default-private-notes")) == nil)

    $privateNotes.withLock { $0 = ["Saved"] }
    try await $privateNotes.save()
    #expect(
      try decryptedStoreValue(
        [String].self, key: "default-private-notes", store: store, crypto: secureCrypto)
        == ["Saved"]
    )
  }

  @Test("Encrypted data takes precedence over a type-safe default")
  func storedValueOverridesTypeSafeDefault() async throws {
    try writeEncryptedStoreValue(
      ["Stored"], key: "default-private-notes", store: store, crypto: secureCrypto)

    @Shared(.defaultPrivateNotes) var privateNotes
    try await $privateNotes.load()
    #expect(privateNotes == ["Stored"])
  }

  @Test func bool() async throws {
    @Shared(.secureAppStorage("bool")) var bool = true
    #expect(store.data(forKey: secureStoreKey("bool")) == nil)

    $bool.withLock { $0 = false }
    try await $bool.save()
    #expect(
      try decryptedStoreValue(Bool.self, key: "bool", store: store, crypto: secureCrypto) == false)

    try writeEncryptedStoreValue(true, key: "bool", store: store, crypto: secureCrypto)
    try await $bool.load()
    #expect(bool)
  }

  @Test func int() async throws {
    @Shared(.secureAppStorage("int")) var int = 42
    #expect(store.data(forKey: secureStoreKey("int")) == nil)

    $int.withLock { $0 = 1729 }
    try await $int.save()
    #expect(
      try decryptedStoreValue(Int.self, key: "int", store: store, crypto: secureCrypto) == 1729)

    try writeEncryptedStoreValue(123, key: "int", store: store, crypto: secureCrypto)
    try await $int.load()
    #expect(int == 123)
  }

  @Test func double() async throws {
    @Shared(.secureAppStorage("double")) var double = 1.2
    #expect(store.data(forKey: secureStoreKey("double")) == nil)

    $double.withLock { $0 = 3.4 }
    try await $double.save()
    #expect(
      try decryptedStoreValue(Double.self, key: "double", store: store, crypto: secureCrypto) == 3.4
    )

    try writeEncryptedStoreValue(5.6, key: "double", store: store, crypto: secureCrypto)
    try await $double.load()
    #expect(double == 5.6)
  }

  @Test func string() async throws {
    @Shared(.secureAppStorage("string")) var string = "Blob"
    #expect(store.data(forKey: secureStoreKey("string")) == nil)

    $string.withLock { $0 = "Blob, Jr." }
    try await $string.save()
    #expect(
      try decryptedStoreValue(String.self, key: "string", store: store, crypto: secureCrypto)
        == "Blob, Jr.")

    try writeEncryptedStoreValue("Blob III", key: "string", store: store, crypto: secureCrypto)
    try await $string.load()
    #expect(string == "Blob III")
  }

  @Test func stringArray() async throws {
    @Shared(.secureAppStorage("string-array")) var stringArray = ["Blob"]
    #expect(store.data(forKey: secureStoreKey("string-array")) == nil)

    $stringArray.withLock { $0 = ["Blob", "Blob, Jr."] }
    try await $stringArray.save()
    #expect(
      try decryptedStoreValue(
        [String].self, key: "string-array", store: store, crypto: secureCrypto)
        == ["Blob", "Blob, Jr."]
    )

    try writeEncryptedStoreValue(
      ["Blob III"], key: "string-array", store: store, crypto: secureCrypto)
    try await $stringArray.load()
    #expect(stringArray == ["Blob III"])
  }

  @Test func url() async throws {
    @Shared(.secureAppStorage("url")) var url = URL(fileURLWithPath: "/dev")
    #expect(store.data(forKey: secureStoreKey("url")) == nil)

    let tmpURL = URL(fileURLWithPath: "/tmp")
    $url.withLock { $0 = tmpURL }
    try await $url.save()
    #expect(
      try decryptedStoreValue(URL.self, key: "url", store: store, crypto: secureCrypto) == tmpURL)

    let usrURL = URL(fileURLWithPath: "/usr")
    try writeEncryptedStoreValue(usrURL, key: "url", store: store, crypto: secureCrypto)
    try await $url.load()
    #expect(url == usrURL)
  }

  @Test func optionalURL() async throws {
    @Shared(.secureAppStorage("optional-url")) var url: URL? = URL(fileURLWithPath: "/dev")
    #expect(store.data(forKey: secureStoreKey("optional-url")) == nil)

    let tmpURL = URL(fileURLWithPath: "/tmp")
    $url.withLock { $0 = tmpURL }
    try await $url.save()
    #expect(
      try decryptedStoreValue(URL.self, key: "optional-url", store: store, crypto: secureCrypto)
        == tmpURL)

    $url.withLock { $0 = nil }
    try await $url.save()
    #expect(url == nil)
    #expect(store.data(forKey: secureStoreKey("optional-url")) == nil)
  }

  @Test func data() async throws {
    @Shared(.secureAppStorage("data")) var data = Data([4, 2])
    #expect(store.data(forKey: secureStoreKey("data")) == nil)

    $data.withLock { $0 = Data([1, 7, 2, 9]) }
    try await $data.save()
    #expect(
      try decryptedStoreValue(Data.self, key: "data", store: store, crypto: secureCrypto)
        == Data([1, 7, 2, 9]))

    try writeEncryptedStoreValue(Data([9, 9]), key: "data", store: store, crypto: secureCrypto)
    try await $data.load()
    #expect(data == Data([9, 9]))
  }

  @Test func date() async throws {
    @Shared(.secureAppStorage("date")) var date = Date(timeIntervalSinceReferenceDate: 0)
    #expect(store.data(forKey: secureStoreKey("date")) == nil)

    let newDate = Date(timeIntervalSince1970: 0)
    $date.withLock { $0 = newDate }
    try await $date.save()
    #expect(
      try decryptedStoreValue(Date.self, key: "date", store: store, crypto: secureCrypto) == newDate
    )

    let futureDate = Date(timeIntervalSince1970: 86_400)
    try writeEncryptedStoreValue(futureDate, key: "date", store: store, crypto: secureCrypto)
    try await $date.load()
    #expect(date == futureDate)
  }

  @Test func codable() async throws {
    struct Item: Codable, Equatable, Sendable {
      var id: Int
    }

    @Shared(.secureAppStorage("codable")) var item = Item(id: 42)
    #expect(store.data(forKey: secureStoreKey("codable")) == nil)

    $item.withLock { $0 = Item(id: 1729) }
    try await $item.save()
    #expect(
      try decryptedStoreValue(Item.self, key: "codable", store: store, crypto: secureCrypto)
        == Item(id: 1729))

    try writeEncryptedStoreValue(Item(id: 99), key: "codable", store: store, crypto: secureCrypto)
    try await $item.load()
    #expect(item == Item(id: 99))
  }

  @Test func rawRepresentableInt() async throws {
    struct ID: RawRepresentable, Equatable, Sendable {
      var rawValue: Int
    }

    @Shared(.secureAppStorage("raw-int")) var id = ID(rawValue: 42)
    #expect(store.data(forKey: secureStoreKey("raw-int")) == nil)

    $id.withLock { $0 = ID(rawValue: 1729) }
    try await $id.save()
    #expect(
      try decryptedStoreValue(Int.self, key: "raw-int", store: store, crypto: secureCrypto) == 1729)

    try writeEncryptedStoreValue(123, key: "raw-int", store: store, crypto: secureCrypto)
    try await $id.load()
    #expect(id == ID(rawValue: 123))
  }

  @Test func rawRepresentableString() async throws {
    struct ID: RawRepresentable, Equatable, Sendable {
      var rawValue: String
    }

    @Shared(.secureAppStorage("raw-string")) var id = ID(rawValue: "Blob")
    #expect(store.data(forKey: secureStoreKey("raw-string")) == nil)

    $id.withLock { $0 = ID(rawValue: "Blob, Jr.") }
    try await $id.save()
    #expect(
      try decryptedStoreValue(String.self, key: "raw-string", store: store, crypto: secureCrypto)
        == "Blob, Jr.")

    try writeEncryptedStoreValue("Blob III", key: "raw-string", store: store, crypto: secureCrypto)
    try await $id.load()
    #expect(id == ID(rawValue: "Blob III"))
  }

  @Test func rawRepresentableCodableString() async throws {
    struct ID: Codable, RawRepresentable, Equatable, Sendable {
      var rawValue: String
    }

    @Shared(.secureAppStorage("raw-codable-string")) var id = ID(rawValue: "Blob")
    #expect(store.data(forKey: secureStoreKey("raw-codable-string")) == nil)

    $id.withLock { $0 = ID(rawValue: "Blob, Jr.") }
    try await $id.save()
    #expect(
      try decryptedStoreValue(
        String.self, key: "raw-codable-string", store: store, crypto: secureCrypto)
        == "Blob, Jr."
    )

    try writeEncryptedStoreValue(
      "Blob III", key: "raw-codable-string", store: store, crypto: secureCrypto)
    try await $id.load()
    #expect(id == ID(rawValue: "Blob III"))
  }

  @Test func optionalRawRepresentableCodableString() async throws {
    struct ID: Codable, RawRepresentable, Equatable, Sendable {
      var rawValue: String
    }

    @Shared(.secureAppStorage("optional-raw-codable-string")) var id: ID?
    #expect(store.data(forKey: secureStoreKey("optional-raw-codable-string")) == nil)

    $id.withLock { $0 = ID(rawValue: "Blob") }
    try await $id.save()
    #expect(
      try decryptedStoreValue(
        String.self, key: "optional-raw-codable-string", store: store, crypto: secureCrypto)
        == "Blob"
    )

    try writeEncryptedStoreValue(
      "Blob, Jr.", key: "optional-raw-codable-string", store: store, crypto: secureCrypto)
    try await $id.load()
    #expect(id == ID(rawValue: "Blob, Jr."))

    $id.withLock { $0 = nil }
    try await $id.save()
    #expect(store.data(forKey: secureStoreKey("optional-raw-codable-string")) == nil)
  }

  @Test func optional() async throws {
    @Shared(.secureAppStorage("optional-bool")) var bool: Bool?
    #expect(store.data(forKey: secureStoreKey("optional-bool")) == nil)

    try writeEncryptedStoreValue(false, key: "optional-bool", store: store, crypto: secureCrypto)
    try await $bool.load()
    #expect(bool == false)

    $bool.withLock { $0 = nil }
    try await $bool.save()
    #expect(store.data(forKey: secureStoreKey("optional-bool")) == nil)
  }

  @Test func optionalDefault() async throws {
    @Shared(.secureAppStorage("optional-default-bool")) var bool: Bool? = true

    #expect(bool == true)
    #expect(store.data(forKey: secureStoreKey("optional-default-bool")) == nil)
    let (updates, yieldUpdate) = AsyncStream.makeStream(of: Bool?.self)
    var iterator = updates.makeAsyncIterator()
    let cancellable = $bool.publisher.dropFirst().sink { yieldUpdate.yield($0) }
    defer { cancellable.cancel() }

    try writeEncryptedStoreValue(
      false, key: "optional-default-bool", store: store, crypto: secureCrypto)
    _ = await iterator.next()
    #expect(bool == false)

    store.removeObject(forKey: secureStoreKey("optional-default-bool"))
    _ = await iterator.next()
    #expect(bool == true)

    $bool.withLock { $0 = nil }
    try await $bool.save()
    #expect(bool == nil)
    #expect(store.data(forKey: secureStoreKey("optional-default-bool")) == nil)
  }

  @Test("Load does not mutate UserDefaults")
  func loadDoesNotMutateUserDefaults() async throws {
    let store = RecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    @Shared(.secureAppStorage("missing", store: store)) var missing = 123
    try await $missing.load()
    #expect(missing == 123)
    #expect(store.writeCount.value == 0)

    try writeEncryptedStoreValue(42, key: "existing", store: store, crypto: secureCrypto)
    store.writeCount.setValue(0)
    @Shared(.secureAppStorage("existing", store: store)) var existing = 0
    try await $existing.load()
    #expect(existing == 42)
    #expect(store.writeCount.value == 0)
  }

  @Test("Corrupt ciphertext reports an error without overwriting it")
  func corruptCiphertextDoesNotGetOverwritten() async {
    let ciphertext = Data([1, 2, 3])
    store.set(ciphertext, forKey: secureStoreKey("corrupt"))
    @Shared(.secureAppStorage("corrupt")) var count = 0

    await #expect(throws: SecureStorageError.decryptionFailed) { try await $count.load() }
    #expect(count == 0)
    #expect(store.data(forKey: secureStoreKey("corrupt")) == ciphertext)
  }

  @Test("A non-Data stored value cannot be loaded, replaced, or removed")
  func invalidStoredValueIsNotTreatedAsMissing() async {
    let store = RecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    store.set("unexpected", forKey: secureStoreKey("invalid"))
    store.writeCount.setValue(0)
    @Shared(.secureAppStorage("invalid", store: store)) var value: Int? = 42

    await #expect(throws: SecureStorageError.invalidStoredValue) { try await $value.load() }
    for replacement: Int? in [1, nil] {
      $value.withLock { $0 = replacement }
      await #expect(throws: SecureStorageError.invalidStoredValue) { try await $value.save() }
    }
    #expect(store.object(forKey: secureStoreKey("invalid")) as? String == "unexpected")
    #expect(store.writeCount.value == 0)
  }

  @Test("Authenticated but undecodable ciphertext cannot be replaced or removed")
  func undecodableCiphertextIsNotOverwritten() async throws {
    let store = RecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    let ciphertext = try secureCrypto.encrypt(Data("not-json".utf8), Data("undecodable".utf8))
    store.set(ciphertext, forKey: secureStoreKey("undecodable"))
    store.writeCount.setValue(0)
    @Shared(.secureAppStorage("undecodable", store: store)) var value: Int? = 42

    await #expect(throws: SecureStorageError.decodingFailed) { try await $value.load() }
    for replacement: Int? in [1, nil] {
      $value.withLock { $0 = replacement }
      await #expect(throws: SecureStorageError.decodingFailed) { try await $value.save() }
    }
    #expect(store.data(forKey: secureStoreKey("undecodable")) == ciphertext)
    #expect(store.writeCount.value == 0)
  }

  @Test("An unavailable encryption key does not replace stored ciphertext")
  func unavailableKeyDoesNotOverwriteCiphertext() throws {
    let store = RecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    let available = LockIsolated(true)
    let crypto = availabilityControlledCrypto(available: available)
    let ciphertext = try encryptedPayload(42, key: "transition", crypto: crypto)
    store.set(ciphertext, forKey: secureStoreKey("transition"))
    store.writeCount.setValue(0)
    available.setValue(false)

    let existing: SecureAppStorageKey<Int> = .secureAppStorage(
      "transition", store: store, crypto: crypto)
    let missing: SecureAppStorageKey<Int> = .secureAppStorage("new", store: store, crypto: crypto)
    #expect(throws: SecureStorageError.keychainInteractionNotAllowed) {
      try existing.loadResult(context: .initialValue(0)).get()
    }
    #expect(throws: SecureStorageError.keychainInteractionNotAllowed) {
      try existing.saveResult(99).get()
    }
    #expect(try missing.loadResult(context: .initialValue(0)).get() == 0)
    #expect(throws: SecureStorageError.keychainInteractionNotAllowed) {
      try missing.saveResult(99).get()
    }
    #expect(store.data(forKey: secureStoreKey("transition")) == ciphertext)
    #expect(store.data(forKey: secureStoreKey("new")) == nil)
    #expect(store.writeCount.value == 0)
  }

  @Test("A failed initial load blocks saves until the shared value is reloaded")
  func failedLoadRequiresReloadBeforeSave() async throws {
    let store = UserDefaults.inMemory
    let available = LockIsolated(true)
    let crypto = availabilityControlledCrypto(available: available)
    let ciphertext = try encryptedPayload(42, key: "stale", crypto: crypto)
    store.set(ciphertext, forKey: secureStoreKey("stale"))
    available.setValue(false)

    try await withDependencies {
      $0.secureAppStorageCrypto = crypto
    } operation: {
      @Shared(.secureAppStorage("stale", store: store)) var count = 0
      await #expect(throws: SecureStorageError.keychainInteractionNotAllowed) {
        try await $count.load()
      }

      available.setValue(true)
      $count.withLock { $0 = 1 }
      await #expect(throws: SecureStorageError.saveBlockedUntilSuccessfulLoad) {
        try await $count.save()
      }
      #expect(store.data(forKey: secureStoreKey("stale")) == ciphertext)

      try await $count.load()
      #expect(count == 42)
      #expect(store.data(forKey: secureStoreKey("stale")) == ciphertext)
    }
  }

  @Test("An explicit load of a missing optional value clears it")
  func missingOptionalValueClearsOnExplicitLoad() async throws {
    @Shared(.secureAppStorage("deleted")) var note: String?
    $note.withLock { $0 = "old-note" }
    try await $note.save()
    store.removeObject(forKey: secureStoreKey("deleted"))

    try await $note.load()
    #expect(note == nil)
  }

  @Test("A successful load permits a save from its continuation")
  func successfulLoadUnblocksBeforeDelivery() throws {
    let available = LockIsolated(true)
    let crypto = availabilityControlledCrypto(available: available)
    try writeEncryptedStoreValue(1, key: "callback", store: store, crypto: crypto)
    let key: SecureAppStorageKey<Int> = .secureAppStorage("callback", crypto: crypto)
    available.setValue(false)
    #expect(throws: SecureStorageError.keychainInteractionNotAllowed) {
      try key.loadResult(context: .initialValue(0)).get()
    }

    available.setValue(true)
    let loadResult = LockIsolated<Result<Int?, any Error>?>(nil)
    let saveResult = LockIsolated<Result<Never?, any Error>?>(nil)
    key.load(context: .initialValue(0), continuation: LoadContinuation { result in
      loadResult.setValue(result)
      key.save(
        42, context: .didSet,
        continuation: SaveContinuation { saveResult.setValue($0) }
      )
    })
    #expect(try #require(loadResult.value).get() == 1)
    _ = try #require(saveResult.value).get()
    #expect(
      try decryptedStoreValue(Int.self, key: "callback", store: store, crypto: crypto)
        == 42)
  }

  @Test("Saved value is not plaintext JSON")
  func savedValueIsNotPlaintextJSON() async throws {
    let store = RecordingUserDefaults(suiteName: "test.\(UUID().uuidString)")!
    @Shared(.secureAppStorage("token", store: store)) var token = "seed"
    let (writes, signalWrite) = AsyncStream.makeStream(of: String.self)
    store.onWrite.setValue { signalWrite.yield($0) }
    var iterator = writes.makeAsyncIterator()

    $token.withLock { $0 = "super-secret-token" }
    #expect(await iterator.next() == secureStoreKey("token"))

    let encrypted = try #require(store.data(forKey: secureStoreKey("token")))
    let plaintext = try JSONEncoder().encode("super-secret-token")
    #expect(encrypted != plaintext)
    #expect(
      try decryptedStoreValue(String.self, key: "token", store: store, crypto: secureCrypto)
        == token)
  }

  @Test func invalidKeyWarning() async {
    await expectReportsIssue {
      @Shared(.secureAppStorage("co.pointfree.isEnabled")) var isEnabled = false
      let (updates, yieldUpdate) = AsyncStream.makeStream(of: Bool.self)
      var iterator = updates.makeAsyncIterator()
      let cancellable = $isEnabled.publisher.dropFirst().sink { yieldUpdate.yield($0) }
      defer { cancellable.cancel() }
      let encrypted = try! encryptedPayload(
        true, key: "co.pointfree.isEnabled", crypto: secureCrypto)
      store.set(encrypted, forKey: secureStoreKey("co.pointfree.isEnabled"))
      _ = await iterator.next()
      #expect(isEnabled)
    } matching: {
      $0.description.contains(
        #"A Shared secure app storage key ("co.pointfree.isEnabled") contains an invalid character (".")"#
      )
    }

    await expectReportsIssue {
      @Shared(.secureAppStorage("@count")) var count = 0
      let (updates, yieldUpdate) = AsyncStream.makeStream(of: Int.self)
      var iterator = updates.makeAsyncIterator()
      let cancellable = $count.publisher.dropFirst().sink { yieldUpdate.yield($0) }
      defer { cancellable.cancel() }
      let encrypted = try! encryptedPayload(42, key: "@count", crypto: secureCrypto)
      store.set(encrypted, forKey: secureStoreKey("@count"))
      _ = await iterator.next()
      #expect(count == 42)
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
    let changes = LockIsolated<[Int]>([])
    let (updates, yieldUpdate) = AsyncStream.makeStream(of: Int.self)
    var iterator = updates.makeAsyncIterator()
    let subscription = persistenceKey.subscribe(
      context: .userInitiated,
      subscriber: SharedSubscriber { result in
        if case .success(.some(let value)) = result {
          changes.withValue { $0.append(value) }
          yieldUpdate.yield(value)
        }
      }
    )
    defer { subscription.cancel() }

    try writeEncryptedStoreValue(1, key: "shared", store: store, crypto: secureCrypto)
    let first = await iterator.next()
    #expect(first == 1)

    try writeEncryptedStoreValue(42, key: "shared", store: store, crypto: secureCrypto)
    let second = await iterator.next()
    #expect(second == 42)

    subscription.cancel()
    try writeEncryptedStoreValue(123, key: "shared", store: store, crypto: secureCrypto)
    #expect(
      try decryptedStoreValue(Int.self, key: "shared", store: store, crypto: secureCrypto) == 123
    )

    #expect(changes.value == [1, 42])

    let loadResult = persistenceKey.loadResult(context: .userInitiated)
    #expect(try loadResult.get() == 123)
    #expect(changes.value == [1, 42])
  }

  @Test("An unlock notification retries the actual key and unblocks saves")
  func unlockNotificationReloadsValueAndUnblocksSaves() async throws {
    let available = LockIsolated(true)
    let crypto = availabilityControlledCrypto(available: available)
    let key: SecureAppStorageKey<Int> = .secureAppStorage("transition-count", crypto: crypto)
    let notificationName = Notification.Name("test.protected-data-became-available")
    let capturedResults = LockIsolated<[Result<Int?, any Error>]>([])

    try writeEncryptedStoreValue(42, key: "transition-count", store: store, crypto: crypto)
    available.setValue(false)
    try await withDependencies {
      $0.protectedDataDidBecomeAvailableNotification = notificationName
    } operation: {
      let originalEncrypted = store.data(forKey: secureStoreKey("transition-count"))
      #expect(capturedResults.value.isEmpty)

      let blockedLoad = key.loadResult(context: .initialValue(0))
      #expect(throws: SecureStorageError.keychainInteractionNotAllowed) {
        try blockedLoad.get()
      }

      let (updates, yieldUpdate) = AsyncStream.makeStream(of: Result<Int?, any Error>.self)
      var iterator = updates.makeAsyncIterator()
      let subscription = key.subscribe(
        context: .initialValue(0),
        subscriber: SharedSubscriber { result in
          capturedResults.withValue { $0.append(result) }
          yieldUpdate.yield(result)
        }
      )
      defer { subscription.cancel() }

      available.setValue(true)
      NotificationCenter.default.post(name: notificationName, object: nil)
      let recoveredValue = try await iterator.next()?.get()
      #expect(recoveredValue == 42)

      let capturedValues = try capturedResults.value.map { try $0.get() }
      #expect(capturedValues.contains(42))
      #expect(store.data(forKey: secureStoreKey("transition-count")) == originalEncrypted)

      let saveResult = key.saveResult(43)
      _ = try saveResult.get()
      #expect(
        try decryptedStoreValue(Int.self, key: "transition-count", store: store, crypto: crypto)
          == 43
      )
    }
  }

  @Test("Load and save continuations complete synchronously")
  func synchronousLoadAndSave() throws {
    let key: SecureAppStorageKey<Int> = .secureAppStorage("synchronous")
    try StorageTaskLocal.$isSet.withValue(true) {
      let loadResult = LockIsolated<Result<Int?, any Error>?>(nil)
      key.load(
        context: .initialValue(0),
        continuation: LoadContinuation {
          #expect(StorageTaskLocal.isSet)
          loadResult.setValue($0)
        }
      )
      #expect(try #require(loadResult.value).get() == 0)

      let saveResult = LockIsolated<Result<Never?, any Error>?>(nil)
      key.save(
        2, context: .didSet,
        continuation: SaveContinuation {
          #expect(StorageTaskLocal.isSet)
          saveResult.setValue($0)
        }
      )
      _ = try #require(saveResult.value).get()
    }
    #expect(
      try decryptedStoreValue(Int.self, key: "synchronous", store: store, crypto: secureCrypto) == 2
    )
  }
}

private extension SecureAppStorageKey {
  func loadResult(context: LoadContext<Value>) -> Result<Value?, any Error> {
    let result = LockIsolated<Result<Value?, any Error>?>(nil)
    load(context: context, continuation: LoadContinuation { result.setValue($0) })
    guard let result = result.value else { fatalError("Load did not finish synchronously") }
    return result
  }

  func saveResult(_ value: Value) -> Result<Never?, any Error> {
    let result = LockIsolated<Result<Never?, any Error>?>(nil)
    save(value, context: .didSet, continuation: SaveContinuation { result.setValue($0) })
    guard let result = result.value else { fatalError("Save did not finish synchronously") }
    return result
  }
}

private enum StorageTaskLocal {
  @TaskLocal static var isSet = false
}

private func availabilityControlledCrypto(available: LockIsolated<Bool>) -> SecureCryptoClient {
  let key = SymmetricKey(data: Data(repeating: 0x42, count: 32))
  return AES.GCM.secureAppStorage(
    keyStore: SecureKeyStoreClient(
      id: SecureKeyStoreID(service: "test.service", account: UUID().uuidString),
      loadSymmetricKey: {
        guard available.value else { throw SecureStorageError.keychainInteractionNotAllowed }
        return key
      },
      loadOrCreateSymmetricKey: {
        guard available.value else { throw SecureStorageError.keychainInteractionNotAllowed }
        return key
      }
    )
  )
}

extension SharedKey where Self == SecureAppStorageKey<[String]>.Default {
  fileprivate static var defaultPrivateNotes: Self {
    Self[.secureAppStorage("default-private-notes"), default: []]
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

private func secureStoreKey(_ key: String) -> String {
  "secure_\(key)"
}

private final class RecordingUserDefaults: UserDefaults {
  let writeCount = LockIsolated(0)
  let onWrite = LockIsolated<(@Sendable (String) -> Void)?>(nil)

  override func set(_ value: Any?, forKey defaultName: String) {
    writeCount.withValue { $0 += 1 }
    super.set(value, forKey: defaultName)
    onWrite.value?(defaultName)
  }

  override func removeObject(forKey defaultName: String) {
    writeCount.withValue { $0 += 1 }
    super.removeObject(forKey: defaultName)
  }
}

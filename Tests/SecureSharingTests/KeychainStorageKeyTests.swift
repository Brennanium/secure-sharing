import Dependencies
import DependenciesTestSupport
import Foundation
import Sharing
import Security
import Testing
@testable import SecureSharing

@Suite("Keychain Storage Key", .dependencies)
struct KeychainStorageKeyTests {
  @Dependency(\.keychainStorageClient) var client

  private let service = "SecureSharing.tests"
  private let accessGroup = "test.group"

  @Test("A missing item uses the initial value without writing it")
  func missingItemDoesNotPersistDefault() throws {
    let item = KeychainStorageItem(service: service, account: "count", accessGroup: accessGroup)
    @Shared(.keychainStorage("count", service: service, accessGroup: accessGroup)) var count = 42

    #expect(count == 42)
    #expect(try client.read(item) == nil)

    $count.withLock { $0 = 43 }
    let storedData = try client.read(item)
    let data = try #require(storedData)
    #expect(try JSONDecoder().decode(Int.self, from: data) == 43)
  }

  @Test("A type-safe default is not stored until the value changes")
  func typeSafeDefault() async throws {
    let item = KeychainStorageItem(
      service: service, account: "default-count", accessGroup: accessGroup)
    @Shared(.defaultCount) var count

    #expect(count == 42)
    #expect(try client.read(item) == nil)

    try await $count.load()
    #expect(count == 42)
    #expect(try client.read(item) == nil)

    $count.withLock { $0 = 43 }
    let data = try #require(try client.read(item))
    #expect(try JSONDecoder().decode(Int.self, from: data) == 43)

    try client.delete(item)
    try await $count.load()
    #expect(count == 43)
  }

  @Test("A stored value takes precedence over a type-safe default")
  func storedValueOverridesTypeSafeDefault() throws {
    let item = KeychainStorageItem(
      service: service, account: "default-count", accessGroup: accessGroup)
    try client.write(JSONEncoder().encode(99), item)

    @Shared(.defaultCount) var count
    #expect(count == 99)
  }

  @Test("Empty Keychain identifiers fail before accessing storage")
  func emptyIdentifiers() {
    let accesses = LockIsolated(0)
    let storage = KeychainStorageClient(
      read: { _ in
        accesses.withValue { $0 += 1 }
        return nil
      },
      write: { _, _ in accesses.withValue { $0 += 1 } },
      delete: { _ in accesses.withValue { $0 += 1 } }
    )
    let invalidItems: [(KeychainStorageItem, SecureStorageError.KeychainField)] = [
      (KeychainStorageItem(service: "", account: "token", accessGroup: accessGroup), .service),
      (KeychainStorageItem(service: service, account: "", accessGroup: accessGroup), .account),
      (KeychainStorageItem(service: service, account: "token", accessGroup: ""), .accessGroup),
    ]

    for (item, field) in invalidItems {
      let expectedError = SecureStorageError.invalidKeychainConfiguration(field: field)
      withDependencies {
        $0.keychainStorageClient = storage
      } operation: {
        let key: KeychainStorageKey<String?> = .keychainStorage(
          item.account, service: item.service, accessGroup: item.accessGroup)

        let loadResult = LockIsolated<Result<String??, any Error>?>(nil)
        key.load(
          context: .initialValue(nil),
          continuation: LoadContinuation { loadResult.setValue($0) }
        )
        #expect(throws: expectedError) { try #require(loadResult.value).get() }

        let saveResult = LockIsolated<Result<Never?, any Error>?>(nil)
        key.save(
          "secret", context: .didSet,
          continuation: SaveContinuation { saveResult.setValue($0) }
        )
        #expect(throws: expectedError) { try #require(saveResult.value).get() }
      }

      let liveClient = KeychainStorageClient.liveValue
      #expect(throws: expectedError) { try liveClient.read(item) }
      #expect(throws: expectedError) { try liveClient.write(Data("secret".utf8), item) }
      #expect(throws: expectedError) { try liveClient.delete(item) }
    }
    #expect(accesses.value == 0)
  }

  @Test("An optional value is removed from Keychain when set to nil")
  func optionalValueCanBeRemoved() throws {
    let item = KeychainStorageItem(service: service, account: "token", accessGroup: accessGroup)
    @Shared(.keychainStorage("token", service: service, accessGroup: accessGroup))
    var token: String?

    #expect(token == nil)
    #expect(try client.read(item) == nil)

    $token.withLock { $0 = "secret-token" }
    let storedData = try client.read(item)
    let data = try #require(storedData)
    #expect(try JSONDecoder().decode(String.self, from: data) == "secret-token")
    #expect(String(decoding: data, as: UTF8.self) == "\"secret-token\"")

    $token.withLock { $0 = nil }
    #expect(try client.read(item) == nil)
  }

  @Test("Codable values use the same keychain item")
  func codableValue() throws {
    struct Credentials: Codable, Equatable, Sendable {
      var username: String
      var token: String
    }
    let item = KeychainStorageItem(
      service: service, account: "credentials", accessGroup: accessGroup)
    @Shared(.keychainStorage("credentials", service: service, accessGroup: accessGroup))
    var credentials = Credentials(username: "Blob", token: "first")
    $credentials.withLock { $0.token = "second" }

    let storedData = try client.read(item)
    let data = try #require(storedData)
    #expect(
      try JSONDecoder().decode(Credentials.self, from: data)
        == Credentials(username: "Blob", token: "second")
    )
  }

  @Test("A locked Keychain blocks a stale save until an explicit successful load")
  func failedLoadBlocksSave() async throws {
    let item = KeychainStorageItem(service: service, account: "stale", accessGroup: accessGroup)
    let storedData = try JSONEncoder().encode("stored")
    let ready = LockIsolated(false)
    let writes = LockIsolated(0)
    let storage = KeychainStorageClient(
      read: { _ in
        guard ready.value else { throw SecureStorageError.keychainInteractionNotAllowed }
        return storedData
      },
      write: { _, _ in writes.withValue { $0 += 1 } },
      delete: { _ in writes.withValue { $0 += 1 } }
    )

    try await withDependencies {
      $0.keychainStorageClient = storage
    } operation: {
      @Shared(.keychainStorage(item.account, service: item.service, accessGroup: item.accessGroup))
      var token = "default"
      #expect($token.loadError as? SecureStorageError == .keychainInteractionNotAllowed)

      ready.setValue(true)
      $token.withLock { $0 = "stale-value" }
      #expect($token.saveError as? SecureStorageError == .saveBlockedUntilSuccessfulLoad)
      #expect(writes.value == 0)

      try await $token.load()
      #expect(token == "stored")
      $token.withLock { $0 = "new-value" }
      #expect(writes.value == 1)
    }
  }

  @Test("Undecodable data cannot be replaced or removed")
  func undecodableDataIsNotOverwritten() async throws {
    let item = KeychainStorageItem(
      service: service, account: "undecodable", accessGroup: accessGroup)
    let invalidData = Data("not-json".utf8)
    try client.write(invalidData, item)
    @Shared(.keychainStorage(item.account, service: item.service, accessGroup: item.accessGroup))
    var value: String?

    await #expect(throws: SecureStorageError.decodingFailed) { try await $value.load() }
    for replacement: String? in ["replacement", nil] {
      $value.withLock { $0 = replacement }
      await #expect(throws: SecureStorageError.decodingFailed) { try await $value.save() }
    }
    #expect(try client.read(item) == invalidData)
  }

  @Test("External changes require an explicit load")
  func externalChangesRequireLoad() async throws {
    let item = KeychainStorageItem(service: service, account: "external", accessGroup: accessGroup)
    @Shared(.keychainStorage("external", service: service, accessGroup: accessGroup))
    var token: String?

    try client.write(JSONEncoder().encode("from-extension"), item)
    #expect(token == nil)

    try await $token.load()
    #expect(token == "from-extension")
  }

  @Test("An external deletion clears an optional value on reload")
  func externalDeletionClearsOptionalValue() async throws {
    let item = KeychainStorageItem(service: service, account: "deleted", accessGroup: accessGroup)
    @Shared(.keychainStorage("deleted", service: service, accessGroup: accessGroup))
    var token: String?

    $token.withLock { $0 = "old-token" }
    try client.delete(item)
    #expect(token == "old-token")

    try await $token.load()
    #expect(token == nil)
  }

  @Test("A successful load permits a save from its continuation")
  func successfulLoadUnblocksBeforeDelivery() {
    let available = LockIsolated(false)
    let writes = LockIsolated(0)
    let storage = KeychainStorageClient(
      read: { _ in
        guard available.value else { throw SecureStorageError.keychainInteractionNotAllowed }
        return nil
      },
      write: { _, _ in writes.withValue { $0 += 1 } },
      delete: { _ in }
    )

    withDependencies {
      $0.keychainStorageClient = storage
    } operation: {
      let key: KeychainStorageKey<String> = .keychainStorage(
        "callback", service: service, accessGroup: accessGroup)
      key.load(
        context: .initialValue(""),
        continuation: LoadContinuation { result in
          #expect(throws: SecureStorageError.keychainInteractionNotAllowed) { try result.get() }
        }
      )
      available.setValue(true)
      key.load(
        context: .initialValue(""),
        continuation: LoadContinuation { result in
          #expect((try? result.get()) == "")
          key.save(
            "new-token", context: .didSet,
            continuation: SaveContinuation { saveResult in
              if case .failure(let error) = saveResult { Issue.record(error) }
            }
          )
        }
      )
    }
    #expect(writes.value == 1)
  }

  @Test("Failed Keychain writes and deletes surface as save errors")
  func mutationFailuresSurfaceAsSaveErrors() {
    let failure = SecureStorageError.keychainFailure(status: -34018)
    let client = KeychainStorageClient(
      read: { _ in nil },
      write: { _, _ in throw failure },
      delete: { _ in throw failure }
    )

    withDependencies {
      $0.keychainStorageClient = client
    } operation: {
      @Shared(.keychainStorage("failure", service: service, accessGroup: accessGroup))
      var token: String?
      $token.withLock { $0 = "secret" }
      #expect($token.saveError as? SecureStorageError == failure)

      $token.withLock { $0 = nil }
      #expect($token.saveError as? SecureStorageError == failure)
    }
  }

  @Test("The shared key identity tracks the physical item and client")
  func keyIdentity() {
    let first: KeychainStorageKey<String?> = .keychainStorage(
      "token", service: service, accessGroup: accessGroup)
    let otherAccount: KeychainStorageKey<String?> = .keychainStorage(
      "other", service: service, accessGroup: accessGroup)
    let otherGroup: KeychainStorageKey<String?> = .keychainStorage(
      "token", service: service, accessGroup: "other.group")
    let otherPolicy: KeychainStorageKey<String?> = .keychainStorage(
      "token", service: service, accessGroup: accessGroup,
      accessibility: .whenUnlockedThisDeviceOnly)

    let same: KeychainStorageKey<String?> = .keychainStorage(
      "token", service: service, accessGroup: accessGroup)
    #expect(first.id == same.id)
    #expect(first.id != otherAccount.id)
    #expect(first.id != otherGroup.id)
    #expect(first.id == otherPolicy.id)

    let otherClient = withDependencies {
      $0.keychainStorageClient = .testValue
    } operation: {
      KeychainStorageKey<String?>.keychainStorage(
        "token", service: service, accessGroup: accessGroup)
    }
    #expect(first.id != otherClient.id)
  }

  @Test("Keychain statuses retain their meaning and underlying code")
  func keychainErrors() {
    let interactionError = keychainStorageError(errSecInteractionNotAllowed)
    #expect(interactionError == .keychainInteractionNotAllowed)
    #expect(interactionError.keychainStatus == errSecInteractionNotAllowed)

    let entitlementError = keychainStorageError(errSecMissingEntitlement)
    #expect(entitlementError == .keychainMissingEntitlement)
    #expect(entitlementError.keychainStatus == errSecMissingEntitlement)

    let otherError = keychainStorageError(errSecNotAvailable)
    #expect(otherError == .keychainFailure(status: errSecNotAvailable))
    #expect(otherError.keychainStatus == errSecNotAvailable)
    #expect(SecureStorageError.decodingFailed.keychainStatus == nil)
  }
}

extension SharedKey where Self == KeychainStorageKey<Int>.Default {
  fileprivate static var defaultCount: Self {
    Self[
      .keychainStorage(
        "default-count", service: "SecureSharing.tests", accessGroup: "test.group"),
      default: 42
    ]
  }
}

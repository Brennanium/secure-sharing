import Dependencies
import DependenciesTestSupport
import Foundation
import Sharing
import Security
import Testing
@testable import SecureSharing

@Suite("Keychain Storage Key", .dependency(\.keychainStorageClient, .testValue))
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

  @Test("Empty Keychain identifiers fail before accessing storage")
  func emptyIdentifiers() async {
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
      await withDependencies {
        $0.keychainStorageClient = storage
      } operation: {
        let key: KeychainStorageKey<String?> = .keychainStorage(
          item.account, service: item.service, accessGroup: item.accessGroup)

        await confirmation { confirm in
          key.load(
            context: .initialValue(nil),
            continuation: LoadContinuation { result in
              #expect(throws: expectedError) { try result.get() }
              confirm()
            }
          )
        }
        await confirmation { confirm in
          key.save(
            "secret", context: .didSet,
            continuation: SaveContinuation { result in
              #expect(throws: expectedError) { try result.get() }
              confirm()
            }
          )
        }
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
  func undecodableDataIsNotOverwritten() throws {
    let item = KeychainStorageItem(
      service: service, account: "undecodable", accessGroup: accessGroup)
    let invalidData = Data("not-json".utf8)
    try client.write(invalidData, item)
    let key: KeychainStorageKey<String?> = .keychainStorage(
      item.account, service: item.service, accessGroup: item.accessGroup)

    key.load(
      context: .initialValue(nil),
      continuation: LoadContinuation { result in
        #expect(throws: SecureStorageError.decodingFailed) { try result.get() }
      }
    )
    for value: String? in ["replacement", nil] {
      key.save(
        value,
        context: .didSet,
        continuation: SaveContinuation { result in
          #expect(throws: SecureStorageError.decodingFailed) { try result.get() }
        }
      )
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
    #expect(interactionError != .protectedDataUnavailable)

    let entitlementError = keychainStorageError(errSecMissingEntitlement)
    #expect(entitlementError == .keychainMissingEntitlement)
    #expect(entitlementError.keychainStatus == errSecMissingEntitlement)

    let otherError = keychainStorageError(errSecNotAvailable)
    #expect(otherError == .keychainFailure(status: errSecNotAvailable))
    #expect(otherError.keychainStatus == errSecNotAvailable)
    #expect(SecureStorageError.decodingFailed.keychainStatus == nil)
  }
}

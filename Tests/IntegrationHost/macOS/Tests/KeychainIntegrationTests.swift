import ConcurrencyExtras
import Foundation
import SecureSharing
import Security
import Testing

@Suite("Signed Keychain Integration")
struct KeychainIntegrationTests {
  private let service = "com.brennanium.secure-sharing.integration-tests"

  @Test("A generic-password item can be created, updated, inspected, and deleted")
  func genericPasswordRoundTrip() throws {
    let group = try accessGroup()
    let account = UUID().uuidString
    let item = KeychainStorageItem(
      service: service,
      account: account,
      accessGroup: group,
      accessibility: .whenUnlockedThisDeviceOnly
    )
    let client = KeychainStorageClient.liveValue
    defer { try? client.delete(item) }

    #expect(try client.read(item) == nil)
    try client.write(Data("first".utf8), item)
    #expect(try client.read(item) == Data("first".utf8))

    let differentCreationPolicy = KeychainStorageItem(
      service: service,
      account: account,
      accessGroup: group,
      accessibility: .afterFirstUnlockThisDeviceOnly
    )
    try client.write(Data("second".utf8), differentCreationPolicy)
    #expect(try client.read(item) == Data("second".utf8))

    let attributes = try itemAttributes(service: service, account: account, accessGroup: group)
    #expect(attributes[kSecAttrAccessGroup as String] as? String == group)
    #expect(
      attributes[kSecAttrAccessible as String] as? String
        == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
    )

    try client.delete(item)
    #expect(try client.read(item) == nil)
  }

  @Test("An encryption key is created once and reloaded by a new client")
  func encryptionKeyPersistsWithoutCaching() throws {
    let group = try accessGroup()
    let account = UUID().uuidString
    let keyStore = SecureKeyStoreClient.keychain(
      service: service,
      account: account,
      accessGroup: group,
      accessibility: .whenUnlockedThisDeviceOnly
    )
    let item = KeychainStorageItem(service: service, account: account, accessGroup: group)
    defer { try? KeychainStorageClient.liveValue.delete(item) }

    #expect(throws: SecureStorageError.keyUnavailable) {
      try keyStore.loadSymmetricKey()
    }
    let created = try keyStore.loadOrCreateSymmetricKey()
    let reloaded = try SecureKeyStoreClient.keychain(
      service: service, account: account, accessGroup: group
    ).loadSymmetricKey()
    #expect(created.withUnsafeBytes { Data($0) } == reloaded.withUnsafeBytes { Data($0) })

    let attributes = try itemAttributes(service: service, account: account, accessGroup: group)
    #expect(attributes[kSecAttrAccessGroup as String] as? String == group)
    #expect(
      attributes[kSecAttrAccessible as String] as? String
        == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
    )

    try KeychainStorageClient.liveValue.delete(item)
    #expect(throws: SecureStorageError.keyUnavailable) {
      try keyStore.loadSymmetricKey()
    }
  }

  @Test("An XPC service can read and update the host's Keychain item")
  func xpcServiceSharesKeychainItem() async throws {
    let group = try accessGroup()
    let account = UUID().uuidString
    let item = KeychainStorageItem(service: service, account: account, accessGroup: group)
    let client = KeychainStorageClient.liveValue
    defer { try? client.delete(item) }

    try client.write(JSONEncoder().encode("host-value"), item)
    let attributes = try itemAttributes(service: service, account: account, accessGroup: group)
    #expect(
      attributes[kSecAttrAccessible as String] as? String
        == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
    )

    let connection = NSXPCConnection(
      serviceName: "com.brennanium.SecureSharingTestHost.KeychainProbeService"
    )
    connection.remoteObjectInterface = NSXPCInterface(with: KeychainProbeProtocol.self)
    connection.resume()
    defer { connection.invalidate() }

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
      let completed = LockIsolated(false)
      let finish: @Sendable (Result<Void, any Error>) -> Void = { result in
        let shouldResume = completed.withValue { completed in
          guard !completed else { return false }
          completed = true
          return true
        }
        if shouldResume { continuation.resume(with: result) }
      }

      let proxy = connection.remoteObjectProxyWithErrorHandler { error in
        finish(.failure(error))
      } as! KeychainProbeProtocol
      proxy.replaceValue(
        account: account,
        accessGroup: group,
        expected: "host-value",
        replacement: "service-value"
      ) { success, processID, message in
        if success && processID.int32Value != ProcessInfo.processInfo.processIdentifier {
          finish(.success(()))
        } else {
          finish(.failure(KeychainProbeFailure(message.map(String.init) ?? "XPC ran in host process")))
        }
      }

      Task.detached {
        try? await Task.sleep(for: .seconds(10))
        finish(.failure(KeychainProbeFailure("XPC service did not reply within 10 seconds")))
      }
    }

    let storedData = try client.read(item)
    let data = try #require(storedData)
    #expect(try JSONDecoder().decode(String.self, from: data) == "service-value")
  }

  private func accessGroup() throws -> String {
    let group = try #require(
      Bundle.main.object(forInfoDictionaryKey: "SecureSharingTestAccessGroup") as? String
    )
    try #require(
      group != "com.brennanium.SecureSharingTestHost",
      "Select an Apple Development team so the host's access group receives a Team ID prefix."
    )
    return group
  }

  private func itemAttributes(service: String, account: String, accessGroup: String) throws
    -> [String: Any]
  {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup,
      kSecUseDataProtectionKeychain as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnAttributes as String: true,
    ]
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    #expect(status == errSecSuccess)
    return try #require(result as? [String: Any])
  }
}

private struct KeychainProbeFailure: Error {
  let message: String

  init(_ message: String) {
    self.message = message
  }
}

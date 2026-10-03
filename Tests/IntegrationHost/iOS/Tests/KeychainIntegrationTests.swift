import Foundation
import SecureSharing
import Sharing
import Testing

@Suite("iOS signed storage fixture")
struct KeychainIntegrationTests {
  @Test("The host can use the access group configured for its embedded extension")
  func signedHost() throws {
    let group = try #require(KeychainFixture.accessGroup)
    #expect(group.hasSuffix(".com.brennanium.SecureSharingIOSTestHost"))
    let plugIns = try #require(Bundle.main.builtInPlugInsURL)
    let actionExtension = plugIns.appendingPathComponent("SecureSharingKeychainAction.appex")
    let extensionBundle = try #require(Bundle(url: actionExtension))
    #expect(
      extensionBundle.object(forInfoDictionaryKey: "SecureSharingTestAccessGroup") as? String
        == group
    )
    #expect(
      extensionBundle.object(forInfoDictionaryKey: "SecureSharingTestAppGroup") as? String
        == KeychainFixture.appGroup
    )
    let extensionInfo = try #require(
      extensionBundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any]
    )
    #expect(extensionInfo["NSExtensionPointIdentifier"] as? String == "com.apple.ui-services")

    let item = KeychainStorageItem(
      service: KeychainFixture.service,
      account: UUID().uuidString,
      accessGroup: group
    )
    let client = KeychainStorageClient.liveValue
    defer { try? client.delete(item) }
    try client.write(Data("host-test".utf8), item)
    #expect(try client.read(item) == Data("host-test".utf8))
  }

  @Test("The signed host can encrypt values in the shared App Group suite")
  func signedSharedSuite() throws {
    let appGroup = try #require(KeychainFixture.appGroup)
    #expect(
      FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil
    )
    let store = KeychainFixture.secureStore
    let key = "hostTest" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    defer { store.removeObject(forKey: "secure_" + key) }

    @Shared(.secureAppStorage(key, store: store, crypto: KeychainFixture.secureCrypto))
    var value: String?
    $value.withLock { $0 = "host-secret" }
    #expect($value.saveError == nil)
    let ciphertext = try #require(store.data(forKey: "secure_" + key))
    #expect(!String(decoding: ciphertext, as: UTF8.self).contains("host-secret"))
  }
}

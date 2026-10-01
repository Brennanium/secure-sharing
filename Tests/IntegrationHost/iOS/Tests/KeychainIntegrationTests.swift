import Foundation
import SecureSharing
import Testing

@Suite("iOS signed Keychain fixture")
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
}

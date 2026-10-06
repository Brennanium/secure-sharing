import Foundation
import Security
import Testing
@testable import SecureSharing

@Suite("Keychain requests")
struct KeychainRequestTests {
  @Test("Reads request one value from the data-protection keychain")
  func read() throws {
    let query = try genericPasswordReadQuery(
      service: "example.service", account: "token", accessGroup: "TEAM.shared")

    #expect(query[kSecClass as String] as? String == kSecClassGenericPassword as String)
    #expect(query[kSecAttrService as String] as? String == "example.service")
    #expect(query[kSecAttrAccount as String] as? String == "token")
    #expect(query[kSecAttrAccessGroup as String] as? String == "TEAM.shared")
    #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
    #expect(query[kSecMatchLimit as String] as? String == kSecMatchLimitOne as String)
    #expect(query[kSecReturnData as String] as? Bool == true)
    #expect(query[kSecAttrAccessible as String] == nil)
  }

  @Test("Creation supplies accessibility and data without read flags")
  func add() throws {
    let data = Data("secret".utf8)
    let attributes = try genericPasswordAddAttributes(
      service: "example.service", account: "token", accessGroup: "TEAM.shared",
      accessibility: .whenUnlockedThisDeviceOnly, data: data)

    #expect(attributes[kSecUseDataProtectionKeychain as String] as? Bool == true)
    #expect(attributes[kSecAttrAccessGroup as String] as? String == "TEAM.shared")
    #expect(
      attributes[kSecAttrAccessible as String] as? String
        == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
    #expect(attributes[kSecValueData as String] as? Data == data)
    #expect(attributes[kSecMatchLimit as String] == nil)
    #expect(attributes[kSecReturnData as String] == nil)
  }

  @Test("Mutation queries omit read and creation attributes")
  func updateAndDelete() throws {
    let query = try genericPasswordQuery(
      service: "example.service", account: "token", accessGroup: "TEAM.shared")

    #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
    #expect(query[kSecAttrAccessGroup as String] as? String == "TEAM.shared")
    #expect(query[kSecAttrAccessible as String] == nil)
    #expect(query[kSecValueData as String] == nil)
    #expect(query[kSecMatchLimit as String] == nil)
    #expect(query[kSecReturnData as String] == nil)
  }

  @Test("An unspecified access group is omitted")
  func unspecifiedAccessGroup() throws {
    let query = try genericPasswordReadQuery(
      service: "example.service", account: "key", accessGroup: nil)
    #expect(query[kSecAttrAccessGroup as String] == nil)
  }
}

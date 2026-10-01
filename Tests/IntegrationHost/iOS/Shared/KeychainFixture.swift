import Foundation

enum KeychainFixture {
  static let service = "com.brennanium.secure-sharing.ios-integration"
  static let account = "manual-token"
  static let appValue = "app-value"
  static let extensionValue = "extension-value"

  static var accessGroup: String? {
    Bundle.main.object(forInfoDictionaryKey: "SecureSharingTestAccessGroup") as? String
  }
}

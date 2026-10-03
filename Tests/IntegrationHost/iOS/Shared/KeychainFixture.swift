import Foundation
import SecureSharing
import Sharing

enum KeychainFixture {
  static let service = "com.brennanium.secure-sharing.ios-integration"
  static let account = "manual-token"
  static let appValue = "app-value"
  static let extensionValue = "extension-value"
  static let secureKey = "sharedNote"
  static let secureService = "com.brennanium.secure-sharing.ios-integration.crypto"

  static var accessGroup: String? {
    Bundle.main.object(forInfoDictionaryKey: "SecureSharingTestAccessGroup") as? String
  }

  static var appGroup: String? {
    Bundle.main.object(forInfoDictionaryKey: "SecureSharingTestAppGroup") as? String
  }

  nonisolated(unsafe) static let secureStore: UserDefaults = {
    guard let appGroup, let store = UserDefaults(suiteName: appGroup) else {
      preconditionFailure("The signed target needs the shared App Group")
    }
    return store
  }()

  static let secureCrypto: SecureCryptoClient = {
    guard let accessGroup else {
      preconditionFailure("The signed target needs the shared Keychain access group")
    }
    return .keychain(
      service: secureService,
      account: "shared-app-storage-key",
      accessGroup: accessGroup
    )
  }()
}

extension SharedKey where Self == SecureAppStorageKey<String?> {
  static var sharedNote: Self {
    .secureAppStorage(
      KeychainFixture.secureKey,
      store: KeychainFixture.secureStore,
      crypto: KeychainFixture.secureCrypto
    )
  }
}

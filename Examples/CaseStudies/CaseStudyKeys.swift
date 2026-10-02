import Foundation
import SecureSharing
import Sharing

struct DemoSession: Codable, Sendable {
  let accessToken: String
}

struct AuthenticatedCheckRecord: Codable, Equatable, Sendable {
  enum Source: String, Codable, Sendable {
    case foregroundButton
    case backgroundTask
  }

  enum ApplicationState: String, Codable, Sendable {
    case active
    case inactive
    case background
  }

  let source: Source
  let observedApplicationState: ApplicationState
  let result: String
  let startedAt: Date
  let completedAt: Date?
}

private enum DemoStorage {
  static let keychainService = "com.brennanium.SecureSharingCaseStudies.auth"
  static let keychainAccount = "accessToken"
  static let accessGroup: String = {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "DemoKeychainAccessGroup") as? String
    else { preconditionFailure("Missing DemoKeychainAccessGroup in the app's Info.plist") }
    return group
  }()
}

extension SecureCryptoClient {
  static var caseStudies: Self {
    .keychain(
      service: "com.brennanium.SecureSharingCaseStudies",
      account: "app-storage-key"
    )
  }
}

extension SharedKey where Self == KeychainStorageKey<DemoSession?> {
  static var demoSession: Self {
    .keychainStorage(
      DemoStorage.keychainAccount,
      service: DemoStorage.keychainService,
      accessGroup: DemoStorage.accessGroup
    )
  }
}

extension SharedKey where Self == SecureAppStorageKey<String>.Default {
  static var privateNote: Self {
    Self[.secureAppStorage("privateNote"), default: ""]
  }
}

extension SharedKey where Self == AppStorageKey<AuthenticatedCheckRecord?> {
  static var lastForegroundCheck: Self {
    .appStorage("lastForegroundCheck")
  }

  static var lastBackgroundCheck: Self {
    .appStorage("lastBackgroundCheck")
  }
}

import Foundation
import Security

/// An error encountered by a secure persistence strategy.
public enum SecureStorageError: Error, Equatable {
  /// An empty attribute in a Keychain item configuration.
  public enum KeychainField: Equatable, Sendable {
    case service
    case account
    case accessGroup
  }

  case saveBlockedUntilSuccessfulLoad
  /// No default encryption client or per-key override was provided.
  case cryptoNotConfigured
  case keyUnavailable
  /// Keychain disallowed an interaction; this does not prove protected data is unavailable.
  case keychainInteractionNotAllowed
  /// The caller lacks an entitlement required by the Keychain operation.
  case keychainMissingEntitlement
  case keychainFailure(status: OSStatus)
  case invalidKeychainConfiguration(field: KeychainField)
  case invalidStoredValue
  case encodingFailed
  case decodingFailed
  case invalidRawRepresentable
  case encryptionFailed
  case decryptionFailed
}

extension SecureStorageError {
  /// The underlying Security framework status, when this error came from Keychain.
  public var keychainStatus: OSStatus? {
    switch self {
    case .keychainInteractionNotAllowed:
      errSecInteractionNotAllowed
    case .keychainMissingEntitlement:
      errSecMissingEntitlement
    case let .keychainFailure(status):
      status
    default:
      nil
    }
  }
}

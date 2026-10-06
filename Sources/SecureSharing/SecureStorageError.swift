import Foundation
import Security

/// An error encountered by a secure persistence strategy.
public enum SecureStorageError: Error, Equatable, LocalizedError, CustomStringConvertible {
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

  /// A diagnostic description that retains the original Keychain status when available.
  public var description: String {
    switch self {
    case .keychainInteractionNotAllowed:
      return keychainErrorDescription(errSecInteractionNotAllowed)
    case .keychainMissingEntitlement:
      return keychainErrorDescription(errSecMissingEntitlement)
    case .keychainFailure(let status):
      return keychainErrorDescription(status)
    case .saveBlockedUntilSuccessfulLoad:
      return "Saving is blocked until the secure value loads successfully."
    case .cryptoNotConfigured:
      return "Secure app storage encryption is not configured."
    case .keyUnavailable:
      return "The encryption key is missing or invalid."
    case .invalidKeychainConfiguration(let field):
      return "The Keychain \(field) must not be empty."
    case .invalidStoredValue:
      return "The stored value has an unexpected type."
    case .encodingFailed:
      return "The value could not be encoded."
    case .decodingFailed:
      return "The stored value could not be decoded."
    case .invalidRawRepresentable:
      return "The value has an invalid raw representation."
    case .encryptionFailed:
      return "The value could not be encrypted."
    case .decryptionFailed:
      return "The stored value could not be decrypted."
    }
  }

  public var errorDescription: String? { description }
}

private func keychainErrorDescription(_ status: OSStatus) -> String {
  if let message = SecCopyErrorMessageString(status, nil) {
    return "\(message) (OSStatus \(status))"
  }
  return "Keychain operation failed (OSStatus \(status))"
}

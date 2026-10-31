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

extension SecureStorageError {
  /// Whether the stored value can never be read again, however long the app waits.
  ///
  /// This is the case for ciphertext that cannot be decrypted or decoded, a value of the wrong
  /// type, and an encryption key that no longer exists, for example after a restore to a new
  /// device. Discarding the value is the only way to save to the key again.
  ///
  /// Transient Keychain failures, such as a locked device, are never unrecoverable. Neither are
  /// configuration errors, which discarding data cannot fix.
  public var isUnrecoverable: Bool {
    switch self {
    case .keyUnavailable, .invalidStoredValue, .decodingFailed, .decryptionFailed:
      true
    default:
      false
    }
  }

  /// Whether the failure can resolve by itself, such as a Keychain that is locked until the
  /// device is unlocked. Retry these; do not discard data because of them.
  public var isTransient: Bool {
    switch self {
    case .keychainInteractionNotAllowed, .keychainFailure:
      true
    default:
      false
    }
  }
}

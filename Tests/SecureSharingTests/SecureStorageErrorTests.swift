import Foundation
import Security
import Testing
@testable import SecureSharing

@Suite("Secure storage errors")
struct SecureStorageErrorTests {
  @Test(arguments: [
    errSecInteractionNotAllowed, errSecMissingEntitlement, errSecNotAvailable, -99_999,
  ])
  func keychainDescriptionsRetainStatus(_ status: OSStatus) {
    let error = keychainStorageError(status)
    #expect(error.keychainStatus == status)
    #expect(error.localizedDescription.contains("OSStatus \(status)"))
    #expect(String(describing: error) == error.localizedDescription)
    if let message = SecCopyErrorMessageString(status, nil) {
      #expect(error.localizedDescription.contains(message as String))
    }
  }

  @Test func otherFailuresHaveDescriptions() {
    #expect(
      SecureStorageError.cryptoNotConfigured.localizedDescription
        == "Secure app storage encryption is not configured.")
    #expect(
      SecureStorageError.invalidKeychainConfiguration(field: .service).localizedDescription
        == "The Keychain service must not be empty.")
  }
}

# ``SecureSharing``

Persist shared values in Keychain or encrypted `UserDefaults`.

## Overview

SecureSharing adds two persistence strategies to
[Sharing](https://github.com/pointfreeco/swift-sharing). Start with ``SecureAppStorageKey`` for
encrypted shared values that need `UserDefaults` observation. Its recommended crypto client uses
a Keychain-backed AES-GCM key. With an App Group suite and shared Keychain access group, an app and
extension can use the same encrypted value.

Configure the default crypto client before creating a secure app-storage key:

```swift
prepareDependencies {
  $0.secureAppStorageCrypto = .keychain(
    service: "com.example.my-app.secure-sharing",
    account: "encryption-key"
  )
}

@Shared(.secureAppStorage("privateNotes")) var privateNotes = [String]()
```

After this one-time setup, ordinary keys need only a name and, for non-optional values, an initial
value.

For a small, targeted secret that does not need observation, ``KeychainStorageKey`` stores the
value directly in Keychain:

```swift
@Shared(.keychainStorage(
  "recoveryCode",
  service: "com.example.my-app.recovery",
  accessGroup: "TEAMID.com.example.shared"
)) var recoveryCode: String?
```

Start with <doc:GettingStarted>, then see <doc:SecureAppStorage> or <doc:KeychainStorage> for
storage and observation details.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:TypeSafeSecureKeys>
- <doc:SecureAppStorage>
- <doc:KeychainStorage>
- <doc:SharingAcrossProcesses>
- <doc:AvailabilityAndFailures>
- <doc:TestingSecureAppStorage>
- <doc:ChangingSecureStorage>

### Encrypted app storage API

- ``SecureAppStorageKey``
- ``SecureCryptoClient``
- ``SecureKeyStoreClient``
- ``SecureKeyStoreID``
- ``SecureKeyStoreAccessibility``
- ``SecureStorageError``

### Keychain storage API

- ``KeychainStorageKey``
- ``KeychainStorageKeyID``
- ``KeychainStorageItem``
- ``KeychainStorageClient``

# ``SecureSharing``

Persist shared values in Keychain or encrypted `UserDefaults`.

## Overview

SecureSharing adds two persistence strategies to
[Sharing](https://github.com/pointfreeco/swift-sharing). Use ``KeychainStorageKey`` for a small
value stored directly in Keychain, including a value shared with an app extension. Use
``SecureAppStorageKey`` when a value needs `UserDefaults` observation but must be encrypted before
it reaches that store. Its recommended crypto client uses a Keychain-backed AES-GCM key.

```swift
@Shared(.keychainStorage(
  "accessToken",
  service: "com.example.my-app.tokens",
  accessGroup: "TEAMID.com.example.shared"
)) var accessToken: String?
```

For encrypted app storage, configure the default crypto client before creating a shared key:

```swift
prepareDependencies {
  $0.secureAppStorageCrypto = .keychain(
    service: "com.example.my-app.secure-sharing",
    account: "encryption-key"
  )
}

@Shared(.secureAppStorage("privateNotes")) var privateNotes = [String]()
```

Start with <doc:GettingStarted>, then see <doc:KeychainStorage> or <doc:SecureAppStorage> for the
respective storage and observation behavior.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:TypeSafeSecureKeys>
- <doc:KeychainStorage>
- <doc:SecureAppStorage>
- <doc:AvailabilityAndFailures>
- <doc:TestingSecureAppStorage>
- <doc:ChangingSecureStorage>

### Keychain storage API

- ``KeychainStorageKey``
- ``KeychainStorageKeyID``
- ``KeychainStorageItem``
- ``KeychainStorageClient``

### Encrypted app storage API

- ``SecureAppStorageKey``
- ``SecureCryptoClient``
- ``SecureKeyStoreClient``
- ``SecureKeyStoreID``
- ``SecureKeyStoreAccessibility``
- ``SecureStorageError``

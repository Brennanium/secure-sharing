# Reusable, type-safe keys

Define secure storage once and reuse it throughout your app.

## Overview

Storage identifiers are easy to mistype when they appear throughout an app. A
[type-safe key](https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/typesafekeys)
collects those details in one place and fixes the value's Swift type.

### Encrypted app storage

For most encrypted shared values, name the app's encryption client once and install it at
startup. Keys can then use that default without repeating the configuration:

```swift
import Dependencies
import SecureSharing
import Sharing

extension SecureCryptoClient {
  static let appEncryption: Self = .keychain(
    service: "com.example.my-app.secure-sharing",
    account: "encryption-key",
    accessibility: .afterFirstUnlockThisDeviceOnly
  )
}
```

Install it in your app's initializer, as shown in <doc:GettingStarted>:

```swift
prepareDependencies {
  $0.secureAppStorageCrypto = .appEncryption
}
```

Then define the shared key:

```swift
extension SharedKey where Self == SecureAppStorageKey<[String]>.Default {
  static var privateNotes: Self {
    Self[.secureAppStorage("privateNotes"), default: []]
  }
}
```

Now each use has the same value type and storage key, while the app-wide dependency supplies the
encryption client:

```swift
@Shared(.privateNotes) var privateNotes
```

A key that needs a different client can pass `crypto:` explicitly.
For an App Group suite, pass a shared static `UserDefaults` instance through `store:` on the
type-safe key rather than changing the app-wide `defaultAppStorage`; see
<doc:SharingAcrossProcesses>.

### Direct Keychain storage

For a small, targeted secret that does not need `UserDefaults` observation, give its Keychain item
a type-safe name:

```swift
import SecureSharing
import Sharing

extension SharedKey where Self == KeychainStorageKey<String?> {
  static var recoveryCode: Self {
    .keychainStorage(
      "recoveryCode",
      service: "com.example.my-app.recovery",
      accessGroup: "TEAMID.com.example.shared",
      accessibility: .afterFirstUnlockThisDeviceOnly
    )
  }
}
```

Use that name wherever the value is needed:

```swift
@Shared(.recoveryCode) var recoveryCode: String?
```

Share the definition with any extension that needs the item, and give both targets the same
Keychain access-group entitlement. See <doc:KeychainStorage> for cross-process reload behavior.

### Defaults

Wrapping a key in `.Default` puts its initial value alongside its storage configuration.
The pattern works for Keychain storage too:

```swift
extension SharedKey where Self == KeychainStorageKey<[String]>.Default {
  static var recoveryCodes: Self {
    Self[
      .keychainStorage(
        "recoveryCodes",
        service: "com.example.my-app.tokens",
        accessGroup: "TEAMID.com.example.shared"
      ),
      default: []
    ]
  }
}

@Shared(.recoveryCodes) var recoveryCodes
```

The default is only an in-memory starting value: a stored value takes precedence, and loading an
absent value does not write the default to storage. It does not affect key identity, so avoid
defining different defaults for the same stored item. A default does not conceal load failures;
check the shared value's `loadError` and reload successfully before saving after a failure. An
explicit reload of a missing non-optional value leaves the current in-memory value unchanged;
an optional value reloads as `nil`.

Treat key definitions as part of your stored-data format. Changing an identifier or encryption
configuration after release may require a migration; see <doc:ChangingSecureStorage>.

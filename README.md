# SecureSharing

Secure persistence for [Sharing] with Keychain and encrypted `UserDefaults` storage.

[Sharing]: https://github.com/pointfreeco/swift-sharing

For setup and behavior details, see the [DocC guides](Sources/SecureSharing/Documentation.docc/SecureSharing.md).

## Overview

SecureSharing adds two persistence strategies to Sharing's `@Shared` property wrapper. Use
`keychainStorage` to keep a small value in Keychain, or `secureAppStorage` to keep an encrypted value
in `UserDefaults` while its encryption key stays in Keychain.
Define [type-safe secure keys](Sources/SecureSharing/Documentation.docc/Articles/TypeSafeSecureKeys.md)
to keep storage identifiers and value types together.

### Keychain storage

Store a small value, such as an access token, directly in Keychain:

```swift
import SecureSharing
import Sharing

@Shared(.keychainStorage(
  "accessToken",
  service: "com.example.my-app.tokens",
  accessGroup: "TEAMID.com.example.shared"
))
var accessToken: String?
```

The value is JSON-encoded. To share it with an extension, both targets must have the same Keychain
access group. Keychain does not notify other processes of changes, so call `$accessToken.load()` to
refresh the value after another process may have changed it. The default accessibility allows access
after the first unlock and keeps the item on this device; changing this policy does not change an
existing item.

### Encrypted app storage

Use encrypted app storage when a value should participate in `UserDefaults` observation without
being stored there as plaintext. Configure the Keychain-backed encryption client at app startup:

```swift
import Dependencies
import SecureSharing
import Sharing

prepareDependencies {
  $0.secureAppStorageCrypto = .keychain(
    service: "com.example.my-app.secure-sharing",
    account: "encryption-key"
  )
}

@Shared(.secureAppStorage("privateNotes")) var privateNotes = [String]()
```

`secureAppStorage` encrypts each value with AES-GCM before writing it to `UserDefaults`. It observes
storage changes like Sharing's `appStorage`, but refuses to load or save while protected data is
unavailable. Without an encryption client, loads and saves fail rather than storing plaintext. Use
`keychainStorage` for values that must be shared with an app extension. The encryption key's
accessibility also applies only when it is first created.

## Testing

Run the dependency-injected tests with `swift test`. Signed cross-process tests live in
`Tests/IntegrationHost.xcodeproj`; see the [iOS test steps](Tests/IntegrationHost/iOS/README.md).

## Alternatives

There are other libraries for working with Keychain directly. Unlike SecureSharing, they do not
provide persistence strategies for Sharing's `@Shared` property wrapper:

  * [SwiftSecurity](https://github.com/dm-zharov/swift-security)
  * [Valet](https://github.com/square/Valet)

## License

SecureSharing is available under the MIT license. See [LICENSE](LICENSE) for details.

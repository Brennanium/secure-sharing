# SecureSharing

Secure persistence for [Sharing] with Keychain and encrypted `UserDefaults` storage.

[Sharing]: https://github.com/pointfreeco/swift-sharing

## Overview

SecureSharing adds two persistence strategies to Sharing's `@Shared` property wrapper. Start with
`secureAppStorage` for encrypted shared values: it keeps ciphertext in `UserDefaults`, the
encryption key in Keychain, and observes changes like Sharing's `appStorage`. Use
`keychainStorage` for a small, targeted secret that should live directly in Keychain and does not
need `UserDefaults` observation.
Define [type-safe secure keys](Sources/SecureSharing/Documentation.docc/Articles/TypeSafeSecureKeys.md)
to keep storage identifiers and value types together.

### Encrypted app storage

Configure the Keychain-backed encryption client once at app startup, then use `secureAppStorage`
like Sharing's `appStorage`:

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

After that one-time setup, ordinary keys need only a name and, for non-optional values, an initial
value. The strategy supports `Codable` values and reports Keychain failures rather than replacing
unreadable data. With an App Group `UserDefaults` suite and shared Keychain access group, an app and
extension can use the same encrypted value. See
[sharing across processes](Sources/SecureSharing/Documentation.docc/Articles/SharingAcrossProcesses.md).

### Direct Keychain storage

For a small secret that does not need observation, store it directly in Keychain:

```swift
@Shared(.keychainStorage(
  "recoveryCode",
  service: "com.example.my-app.recovery",
  accessGroup: "TEAMID.com.example.shared"
)) var recoveryCode: String?
```

There is no `UserDefaults` entry or encryption client to configure, but another process's write
requires an explicit `$recoveryCode.load()` to refresh this value.

## Testing

Run the dependency-injected tests with `swift test`. Signed cross-process tests live in
`Tests/IntegrationHost.xcodeproj`. The macOS XPC test verifies encrypted cross-process observation;
see the [iOS test steps](Tests/IntegrationHost/iOS/README.md) for the Action-extension flow.

## Documentation

The documentation for `main` is available here:

* [`main`](https://swiftpackageindex.com/brennanium/secure-sharing/main/documentation/securesharing/)

## Examples

The [case-study app](Examples/README.md) demonstrates encrypted notes and an authenticated
background refresh with an encrypted session.

## Alternatives

There are other libraries for working with Keychain directly. Unlike SecureSharing, they do not
provide persistence strategies for Sharing's `@Shared` property wrapper:

  * [SwiftSecurity](https://github.com/dm-zharov/swift-security)
  * [Valet](https://github.com/square/Valet)

## License

SecureSharing is available under the MIT license. See [LICENSE](LICENSE) for details.

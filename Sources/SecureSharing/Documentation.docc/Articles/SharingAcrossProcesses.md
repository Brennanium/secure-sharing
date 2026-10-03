# Sharing across processes

Use encrypted app storage from an app and its extension.

## Overview

`secureAppStorage` can use App Group `UserDefaults` while its AES-GCM key lives in a Keychain
access group. The app and extension need entitlements for both groups and must use the same key
name, suite, and crypto configuration.

### Define shared storage

Put the configuration in source compiled into both targets:

```swift
import Foundation
import SecureSharing
import Sharing

private extension UserDefaults {
  nonisolated(unsafe) static let secureAppGroup = UserDefaults(suiteName: "group.com.example.my-app")!
}

private extension SecureCryptoClient {
  static let sharedStorage: Self = .keychain(
    service: "com.example.my-app.secure-sharing",
    account: "encryption-key",
    accessGroup: "TEAMID.com.example.shared"
  )
}
```

Keep one `UserDefaults` instance per process, and pass it through `store:` rather than changing
`defaultAppStorage` for unrelated keys. Do not fall back to `UserDefaults.standard` if the suite
is unavailable: that would split the two processes' data.

### Define the key

In the same source file, define the type-safe key used by the app and extension:

```swift
extension SharedKey where Self == SecureAppStorageKey<String?> {
  static var accessToken: Self {
    .secureAppStorage(
      "accessToken",
      store: .secureAppGroup,
      crypto: .sharedStorage
    )
  }
}

@Shared(.accessToken) var accessToken: String?
```

On macOS, the App Group identifier and Keychain access group can be distinct.

### Observation

An active shared value can observe another process's write to the App Group suite. An app may be
suspended while its extension runs, so do not rely on receiving every intermediate change. Reload
on activation when you need the latest value:

```swift
try await $accessToken.load()
```

Concurrent writers are not coordinated by this key.

### Choose a strategy

Prefer `secureAppStorage` for encrypted shared values, especially when an extension's write should
be observed through the App Group suite. Use <doc:KeychainStorage> for a small, targeted secret
that should live directly in Keychain; another process's write then requires an explicit reload.
Both strategies can fail when their Keychain item is inaccessible; see
<doc:AvailabilityAndFailures>. With `secureAppStorage`, the UserDefaults key name and presence are
not encrypted.

# Getting started

Choose a secure storage strategy and share your first persisted value.

## Overview

Add the SecureSharing and Sharing library products to your app target. Add Dependencies too if you
use encrypted app storage's default crypto configuration. Import the modules where you use them.

### Store a value in Keychain

For a small value such as a token, use `keychainStorage` with a stable service, account, and
explicit Keychain access group:

```swift
import SecureSharing
import Sharing

@Shared(.keychainStorage(
  "accessToken",
  service: "com.example.my-app.tokens",
  accessGroup: "TEAMID.com.example.shared"
)) var accessToken: String?
```

Every target that uses the item needs the matching Keychain access-group entitlement. No crypto
client is needed. See <doc:KeychainStorage> for reload and accessibility behavior, and
[type-safe keys](<doc:TypeSafeSecureKeys>) for a reusable definition.

### Configure the encryption client

For `secureAppStorage`, set the default `secureAppStorageCrypto` before creating keys that rely on
it. The Keychain-backed client uses AES-GCM and keeps the symmetric key out of `UserDefaults`:

```swift
import Dependencies
import SecureSharing
import Sharing
import SwiftUI

@main
struct MyApp: App {
  init() {
    prepareDependencies {
      $0.secureAppStorageCrypto = .keychain(
        service: "com.example.my-app.secure-sharing",
        account: "encryption-key"
      )
    }
  }

  var body: some Scene {
    WindowGroup { ContentView() }
  }
}
```

Choose a stable service and account owned by your app. The optional `accessGroup` selects a
Keychain access group. By default, a newly created Keychain key uses
`afterFirstUnlockThisDeviceOnly`; changing accessibility later does not update an existing item.

### Share an encrypted app-storage value

Use `secureAppStorage` as a Sharing key. An optional value starts as `nil` when nothing has been
saved:

```swift
@Shared(.secureAppStorage("accessToken")) var accessToken: String?

$accessToken.withLock { $0 = "example-token" }
```

For a non-optional value, provide an initial value:

```swift
@Shared(.secureAppStorage("launchCount")) var launchCount = 0
```

Loading an absent value does not write the initial value to `UserDefaults`. The first non-`nil`
save creates an encryption key if needed. See <doc:SecureAppStorage> for storage and observation,
and [type-safe keys](<doc:TypeSafeSecureKeys>) for reusable definitions.

### Override one key

The default client is preferred for most keys. When a key needs a different configuration, pass
`crypto:`; pass `store:` to choose a different UserDefaults store:

```swift
@Shared(
  .secureAppStorage(
    "separateToken",
    crypto: .keychain(service: "com.example.my-app.separate", account: "encryption-key")
  )
)
var separateToken: String?
```

A live app needs either a default or a per-key crypto client. Without one, SecureSharing reports
an issue and fails loads and saves with `SecureStorageError.cryptoNotConfigured`; it never writes
plaintext instead. See <doc:AvailabilityAndFailures> for other failures and
<doc:TestingSecureAppStorage> for testing without Keychain.

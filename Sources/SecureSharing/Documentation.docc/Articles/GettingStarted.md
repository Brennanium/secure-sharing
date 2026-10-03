# Getting started

Start with encrypted app storage, then use direct Keychain storage where it fits.

## Overview

Add the SecureSharing and Sharing library products to your app target. Add Dependencies to
configure the default encryption client. Import the modules where you use them.

### Configure the encryption client

For most encrypted shared values, use `secureAppStorage`. Set the default
`secureAppStorageCrypto` in your app's initializer before creating keys that rely on it. The
Keychain-backed client uses AES-GCM and keeps its symmetric key out of `UserDefaults`:

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
@Shared(.secureAppStorage("privateNote")) var privateNote: String?

$privateNote.withLock { $0 = "A private note" }
```

For a non-optional value, provide an initial value:

```swift
@Shared(.secureAppStorage("launchCount")) var launchCount = 0
```

Loading an absent value does not write the initial value to `UserDefaults`. The first non-`nil`
save creates an encryption key if needed. See <doc:SecureAppStorage> for storage and observation,
and [type-safe keys](<doc:TypeSafeSecureKeys>) for reusable definitions.
To share encrypted values with an extension, see <doc:SharingAcrossProcesses>.

### Override one key

The default client is preferred for most keys. When a key needs a different configuration, pass
`crypto:`; pass `store:` to choose a different UserDefaults store:

```swift
@Shared(
  .secureAppStorage(
    "separateNote",
    crypto: .keychain(service: "com.example.my-app.separate", account: "encryption-key")
  )
)
var separateNote: String?
```

A live app needs either a default or a per-key crypto client. Without one, SecureSharing reports
an issue and fails loads and saves with `SecureStorageError.cryptoNotConfigured`; it never writes
plaintext instead. See <doc:AvailabilityAndFailures> for other failures and
<doc:TestingSecureAppStorage> for testing without Keychain.

### Store a small value directly in Keychain

Use `keychainStorage` for a targeted secret that does not need `UserDefaults` observation, such as
a recovery code:

```swift
import SecureSharing
import Sharing

@Shared(.keychainStorage(
  "recoveryCode",
  service: "com.example.my-app.recovery",
  accessGroup: "TEAMID.com.example.shared"
)) var recoveryCode: String?
```

No encryption client is needed. Both the app and any extension that uses this item need the
matching Keychain access-group entitlement. Unlike `secureAppStorage`, another process's write
requires an explicit reload. See <doc:KeychainStorage> for details and
[type-safe keys](<doc:TypeSafeSecureKeys>) for a reusable definition.

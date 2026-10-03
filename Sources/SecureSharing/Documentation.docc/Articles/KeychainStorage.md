# Keychain storage

Persist a small shared value directly in a generic-password Keychain item.

## Overview

Use `keychainStorage` for a small, targeted `Codable` and `Sendable` secret that should live
directly in Keychain and does not need `UserDefaults` observation. For general encrypted shared
state, start with <doc:SecureAppStorage> instead.

```swift
@Shared(.keychainStorage(
  "recoveryCode",
  service: "com.example.my-app.recovery",
  accessGroup: "TEAMID.com.example.shared"
)) var recoveryCode: String?
```

The service, account, and access group identify the item. Both the app and any extension that
uses it need the matching Keychain access-group entitlement. Define these identifiers once with
a [type-safe key](<doc:TypeSafeSecureKeys>).

### Save and delete

Values are JSON-encoded before being written to Keychain. Loading an absent item returns the
initial value without writing it. Set an optional value to `nil` to delete its item:

```swift
$recoveryCode.withLock { $0 = nil }
```

Keychain reads and writes are synchronous and may block the calling thread.

### Choose accessibility

The default is `afterFirstUnlockThisDeviceOnly`: an item created with this policy is available
after the first unlock following a restart and does not migrate to another device. Pass
`accessibility:` to choose a different policy for new items; changing it does not update an
existing item. The strategy attempts Keychain access rather than preflighting protected-data
readiness. See <doc:AvailabilityAndFailures>.

### Refresh after another process writes

Keychain does not provide this strategy with change notifications. Shared references in one
process update each other, but an app does not automatically see an extension's write. Reload at a
point when another process may have changed the item:

```swift
try await $recoveryCode.load()
```

Reload after Keychain access becomes available following a failed load, too. A missing optional
item reloads as `nil`; a missing non-optional item keeps its current in-memory value. A failed
load blocks saves until a successful reload. Concurrent writers need their own coordination.

### Test without Keychain

Tests automatically use ``KeychainStorageClient/testValue``, which stores items in memory. Use the
`.dependencies` trait to isolate shared state across repeated or parameterized tests:

```swift
import DependenciesTestSupport
import SecureSharing
import Sharing
import Testing

@Test(.dependencies)
func storesRecoveryCode() {
  @Shared(.keychainStorage(
    "recoveryCode",
    service: "example.tests",
    accessGroup: "example.tests"
  )) var recoveryCode: String?

  $recoveryCode.withLock { $0 = "test-code" }
  #expect(recoveryCode == "test-code")
}
```

Override ``Dependencies/DependencyValues/keychainStorageClient`` only when a test needs to
simulate a particular Keychain response or failure.

This tests sharing, not live Keychain access. Signed integration tests must opt into
``KeychainStorageClient/liveValue`` and give both targets the same access-group entitlement.
Use a device to test first-unlock and other accessibility conditions.

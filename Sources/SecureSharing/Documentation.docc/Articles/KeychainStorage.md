# Keychain storage

Persist a small shared value directly in a generic-password Keychain item.

## Overview

Use `keychainStorage` for a `Codable` and `Sendable` value that belongs in Keychain, such as a
token. Unlike `secureAppStorage`, it does not write to `UserDefaults` or require a crypto client.

```swift
@Shared(.keychainStorage(
  "accessToken",
  service: "com.example.my-app.tokens",
  accessGroup: "TEAMID.com.example.shared"
)) var accessToken: String?
```

The account, service, and access group identify the item and must be nonempty. Specify a Keychain
access group authorized by the app's signed entitlements. An extension can use the same item only
if its entitlements authorize that group too. Passing the same account and service without the
same access group is not sufficient. Use a [type-safe key](<doc:TypeSafeSecureKeys>) to define
these identifiers once.

### Values and availability

The strategy JSON-encodes values before writing them to Keychain. Loading an absent item returns
the initial value without writing it. Setting an optional shared value to `nil` deletes the item.
Reads and writes are synchronous and may block the calling thread.

The default accessibility is `afterFirstUnlockThisDeviceOnly`: the item is available after the
first unlock following a restart and does not migrate to another device. Pass `accessibility:` to
choose a different creation policy. Changing it on an existing item does not update that item's
accessibility. The strategy does not preflight protected-data readiness; it reports Keychain
failures from the attempted operation. See <doc:AvailabilityAndFailures>.

### Refresh after another process writes

Keychain does not provide this strategy with change notifications. Shared references in one
process update each other, but an app does not automatically see an extension's write. Reload at a
point when another process may have changed the item:

```swift
try await $accessToken.load()
```

The same applies after Keychain access becomes available following a failed load. A missing
optional item reloads as `nil`; a missing non-optional item leaves its current in-memory value
unchanged. A failed load blocks saves on that shared key until a successful reload. There is no
cross-process transaction or conflict resolution; coordinate concurrent writers if that matters.

### Test without Keychain

Tests automatically use ``KeychainStorageClient/testValue``, which stores items in memory. Use the
`.dependencies` trait to isolate shared state across repeated or parameterized tests:

```swift
import DependenciesTestSupport
import SecureSharing
import Sharing
import Testing

@Test(.dependencies)
func storesToken() {
  @Shared(.keychainStorage(
    "accessToken",
    service: "example.tests",
    accessGroup: "example.tests"
  )) var accessToken: String?

  $accessToken.withLock { $0 = "test-token" }
  #expect(accessToken == "test-token")
}
```

Override ``Dependencies/DependencyValues/keychainStorageClient`` only when a test needs to
simulate a particular Keychain response or failure.

This tests sharing, not encoding, signing, or cross-process access. A signed integration test
must opt into ``KeychainStorageClient/liveValue`` to exercise the real Keychain; the test context
otherwise uses the in-memory client. Give the host and extension the same access-group
entitlement, and verify that an explicit reload observes the other process's write. Use a device
to check behavior around first unlock and other accessibility conditions.

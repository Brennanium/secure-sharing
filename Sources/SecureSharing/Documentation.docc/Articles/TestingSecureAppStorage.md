# Testing secure app storage

Test shared values without writing to app UserDefaults or Keychain.

## Overview

In tests, the default crypto client uses an in-memory key, and Sharing provides an isolated
UserDefaults store. Feature tests can usually work with a secure shared value as they would with
any other `@Shared` value:

```swift
import DependenciesTestSupport
import SecureSharing
import Sharing
import Testing

@Test(.dependencies)
func noteIsShared() {
  @Shared(.secureAppStorage("privateNote")) var privateNote: String?
  @Shared(.secureAppStorage("privateNote")) var anotherNote: String?

  $privateNote.withLock { $0 = "test-note" }
  #expect(anotherNote == "test-note")
}
```

Use the `.dependencies` trait for repeated or parameterized tests to isolate shared state between
runs, as recommended by Sharing.

### Override storage and crypto

Explicit `store:` and `crypto:` arguments bypass these test defaults. Prefer dependency-backed
keys for isolated feature tests.

Override `defaultAppStorage` to inspect the stored ciphertext. To test with a custom key source,
pass a ``SecureKeyStoreClient`` to
[`AES.GCM.secureAppStorage(keyStore:)`](<doc:CryptoKit/AES/GCM/secureAppStorage(keyStore:)>),
then set `secureAppStorageCrypto` or pass the client to one key. Override
``Dependencies/DependencyValues/protectedDataDidBecomeAvailableNotification`` to trigger a reload
in a test; use a custom key store to simulate an inaccessible encryption key.

In a live app, an unconfigured default reports an issue and rejects load and save before accessing
UserDefaults. Tests use an in-memory client by default, so they do not exercise that live failure
unless explicitly configured to do so.

These in-memory tests do not prove that Keychain entitlements, protected-data transitions on a
device, or app-extension access work. Those behaviors need signed integration tests and, for
locked-device behavior, device testing. For direct Keychain storage testing, see
<doc:KeychainStorage>.

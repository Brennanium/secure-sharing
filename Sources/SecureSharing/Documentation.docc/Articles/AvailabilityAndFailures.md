# Availability and failures

Handle Keychain failures without replacing stored data.

## Overview

Both strategies distinguish an absent value from an unreadable one. Neither writes an initial
value during load. A failed load blocks subsequent saves on that shared key until a successful
reload, protecting a stored value from an in-memory default or stale value.

### Keychain availability

With the built-in crypto client, `secureAppStorage` attempts the actual Keychain operation when
decrypting an existing value or encrypting a new one. An inaccessible key fails the operation; it
never falls back to plaintext.
When no ciphertext exists, a load returns the initial value without accessing Keychain or writing
to UserDefaults. Saves of `nil` remove an existing value only after it has been decrypted.

Loads and saves complete synchronously and Keychain access can block the calling thread, including
the main thread. The projected shared value's throwing methods expose failures, but do not move
the underlying Keychain call to a background thread.

An active `secureAppStorage` subscription retries loading when protected data becomes available.
This notification often accompanies an unlock, but does not prove that a particular Keychain item
can be read. The retry leaves ciphertext untouched. In an app extension or other context without
this notification, call `$value.load()` when access may have changed.

`keychainStorage` also attempts the actual Keychain operation, but does not subscribe to this
notification. Its default `afterFirstUnlockThisDeviceOnly` accessibility does not allow access
before the first unlock after a restart. See <doc:KeychainStorage>.

### Inspect errors explicitly

Use the projected shared value's throwing methods when a feature needs to react to a persistence
failure:

```swift
do {
  try await $accessToken.load()
} catch {
  // Keep the stored value intact and decide when to retry or surface the error.
}

do {
  try await $accessToken.save()
} catch {
  // The value in memory may not have been persisted.
}
```

For an implicit load or save, inspect `$accessToken.loadError` or `$accessToken.saveError` instead
of assuming the in-memory value was persisted.

Common errors include:

| Error | Meaning |
| --- | --- |
| `cryptoNotConfigured` | `secureAppStorage` has no default or per-key encryption client. |
| `keychainInteractionNotAllowed` | A Keychain operation received `errSecInteractionNotAllowed`; this status alone does not establish why access was denied. |
| `keychainMissingEntitlement` | A Keychain operation lacks a required entitlement. |
| `keyUnavailable` | An encryption key is missing or invalid. The built-in AES-GCM decrypt operation preserves key-loading errors before it attempts decryption. |
| `invalidStoredValue` | A `UserDefaults` entry or Keychain result has an unexpected type. |
| `decryptionFailed` or `decodingFailed` | Stored bytes could not be authenticated or decoded. |
| `saveBlockedUntilSuccessfulLoad` | A prior load failed and no successful reload has cleared the save block. |

Both strategies may also return `keychainFailure(status:)`. The built-in AES-GCM client maps an
authentication failure to `decryptionFailed`; it does not wrap errors thrown while loading its
Keychain key. Do not assume every Keychain failure means protected data is unavailable.

### Preserve stored values

Before replacing an existing value, both strategies read and decode it; `secureAppStorage` also
decrypts it. If that fails, the save leaves the stored bytes intact, even when saving `nil`.
Investigate the failure or migrate the value rather than treating it as absent.

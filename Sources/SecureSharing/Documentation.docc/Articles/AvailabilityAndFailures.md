# Availability and failures

Handle Keychain and protected-data failures without replacing stored data.

## Overview

Both strategies distinguish an absent value from an unreadable one. Neither writes an initial
value during load. A failed load blocks subsequent saves on that shared key until a successful
reload, protecting a stored value from an in-memory default or stale value.

### Protected data

With a configured crypto client, `secureAppStorage` checks protected-data availability before
accessing UserDefaults. If it is unavailable, load and save fail with
`SecureStorageError.protectedDataUnavailable`; neither operation falls back to unencrypted
persistence. An active subscription listens for protected data becoming available and reloads the
stored value without writing it back.

The built-in readiness check uses app protected-data APIs. Do not assume `secureAppStorage` is
suitable for an app extension or for work that must proceed before the first device unlock.

`keychainStorage` does not use this readiness check or subscribe to a protected-data notification.
It attempts the Keychain operation and reports the resulting error. Accessibility controls when an
item can be accessed; choosing `afterFirstUnlockThisDeviceOnly` does not make it accessible before
the first unlock after a restart. Retry with an explicit `$value.load()` when access may have
become available. See <doc:KeychainStorage>.

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
| `protectedDataUnavailable` | `secureAppStorage` failed its readiness check, or its built-in Keychain key store received `errSecInteractionNotAllowed`. |
| `keychainInteractionNotAllowed` | A direct `keychainStorage` operation received `errSecInteractionNotAllowed`; this status alone does not establish why access was denied. |
| `keychainMissingEntitlement` | A direct `keychainStorage` operation lacks a required entitlement. |
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

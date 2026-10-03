# Secure app storage

Persist and observe encrypted values in UserDefaults.

## Overview

For most encrypted shared values, start with `secureAppStorage`. After configuring an encryption
client in <doc:GettingStarted>, use it like a Sharing app-storage key:

```swift
@Shared(.secureAppStorage("privateNote")) var privateNote: String?

$privateNote.withLock { $0 = "A private note" }
```

An optional value starts as `nil`. Give a non-optional value an initial value:

```swift
@Shared(.secureAppStorage("launchCount")) var launchCount = 0
```

The key supports the same value types as Sharing's `appStorage`, including `Codable` and
`RawRepresentable` types.

### What gets stored

The value is JSON-encoded, encrypted, and stored as `Data` under `secure_` followed by the key
name. The built-in AES-GCM client keeps its encryption key in Keychain and authenticates the key
name, so ciphertext cannot be moved to another key.

Loading a missing value returns the initial value without writing it. With the built-in Keychain
client, the first non-`nil` save creates an encryption key if needed; a load never does. A
successful save of `nil` removes the stored value.

### Observation

An active `@Shared` value observes changes to its UserDefaults key. Sharing's
[app-storage key-name caveat][app-storage-key-names] also applies here. After an unlock
notification, the key retries a failed load without rewriting the stored value. See
<doc:AvailabilityAndFailures> for failure and recovery behavior.

### Choose a store

By default, the key uses Sharing's `defaultAppStorage` dependency. Pass `store:` for an individual
key's UserDefaults store and `crypto:` for a different encryption client. For an App Group, keep
the shared store on the keys that need it rather than changing the default for every key; see
<doc:SharingAcrossProcesses>.

The key name, store, and crypto client form the Sharing reference's identity. Define stable
[type-safe keys](<doc:TypeSafeSecureKeys>) for these choices, and see
<doc:ChangingSecureStorage> before changing them. For a small, targeted secret that should live
directly in Keychain without `UserDefaults` observation, see <doc:KeychainStorage>.

[app-storage-key-names]: https://github.com/pointfreeco/swift-sharing/blob/main/Sources/Sharing/Documentation.docc/Extensions/AppStorageKey.md#special-characters-in-keys

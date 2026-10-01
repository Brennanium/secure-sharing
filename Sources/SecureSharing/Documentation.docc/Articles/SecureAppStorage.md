# Secure app storage

Understand how `secureAppStorage` stores and observes a shared value.

## Overview

`secureAppStorage` follows Sharing's app-storage API for booleans, numbers, strings, arrays of
strings, URLs, data, dates, `Codable` values, and integer- or string-backed `RawRepresentable`
values. Optional values are supported. Non-optional shared values need an initial value, while an
optional value can start as `nil`.

See <doc:GettingStarted> to configure a default encryption client and create your first key.
For a small value that must be accessible from an app extension, consider <doc:KeychainStorage>
instead; this strategy's readiness check uses app protected-data APIs.

### Stored format

The strategy JSON-encodes the value and stores the crypto client's output as `Data` in UserDefaults
under `secure_` followed by the logical key. The built-in Keychain client uses AES-GCM and keeps
its symmetric key in Keychain. It authenticates the logical key as associated data, so its
ciphertext cannot simply be copied to another key. Custom clients must provide their own
encryption and authentication guarantees.

An absent stored value loads the initial value without writing anything. A successful save persists
the new value, or removes the stored value for `nil`. The built-in client creates its encryption key
on the first non-`nil` save if needed, but a load never creates a missing encryption key.

### Observation

For keys without `.` and not starting with `@`, the strategy observes UserDefaults changes with
key-value observation. Keys containing `.` or starting with `@` use a notification fallback and
produce a runtime issue unless `appStorageKeyFormatWarningEnabled` is disabled. Prefer keys without
those formats for more precise observation.

The strategy also listens for protected data becoming available so an active shared value can
reload after an unavailable period. It does not rewrite the value during that reload. See
<doc:AvailabilityAndFailures> for the failure and recovery rules.

### Configuration and identity

The default UserDefaults store is Sharing's `defaultAppStorage` dependency. Pass `store:` to choose
a store for an individual key, or `crypto:` to override the default encryption client. The logical
key, store, and crypto client together identify an in-memory Sharing reference. This identity does
not migrate data. See [type-safe keys](<doc:TypeSafeSecureKeys>) to reuse a configuration and
<doc:ChangingSecureStorage> before changing it.

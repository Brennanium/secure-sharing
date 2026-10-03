# Changing secure storage configuration

Plan migrations when a key starts pointing at different stored data.

## Overview

Changing a key's storage configuration does not move or re-encrypt its value. For example, these
two keys read different `UserDefaults` entries:

```swift
@Shared(.secureAppStorage("privateNote")) var privateNote: String?
@Shared(.secureAppStorage("archivedNote")) var archivedNote: String?
```

The first uses `secure_privateNote`; the second uses `secure_archivedNote`. Copying ciphertext
between them will not work with the built-in AES-GCM client because it authenticates the logical
key name.

### What changes an item

`keychainStorage` identifies an item by service, account, and access group. Changing any of these
selects a different item. The app needs entitlements for both access groups while migrating
between them.

For `secureAppStorage`, changing the key name or `UserDefaults` store changes where the ciphertext
lives. Changing the crypto format or the Keychain service, account, or access group can make that
ciphertext unreadable. Changing a value's JSON representation can also require a migration.

Changing Keychain accessibility does **not** update an existing item; the new policy applies only
when an item is created. Accessibility is not part of `keychainStorage`'s shared-key identity.

### Sharing identity is not storage migration

Sharing identifies an in-memory `secureAppStorage` reference by its logical key, store, and
crypto-client identity. Two crypto clients can therefore create separate references to the
**same** UserDefaults entry. That does not re-encrypt the stored bytes: one client may be unable
to read what the other wrote.

### Move data deliberately

1. Read with the old configuration.
2. Write under a new key or store, then load it back to verify the result.
3. Only then remove the old value.

Do not switch crypto clients on an existing `secureAppStorage` entry: a save first validates its
existing ciphertext, so the new client may be unable to overwrite it. If the old value cannot be
read, preserve it rather than writing an initial value. Migration from another library's format
belongs in the app and may require a custom ``SecureCryptoClient``.

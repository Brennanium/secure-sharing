# Changing secure storage configuration

Plan migrations when changing a Keychain item or encrypted app-storage configuration.

## Overview

SecureSharing does not migrate values when you change a Keychain item identity, app-storage key,
`UserDefaults` store, or encryption client. The app that owns the data must migrate it.

### Keychain items

`keychainStorage` identifies an item by service, account, and access group. Changing any of these
selects a different item; it does not move the old one. Changing accessibility does not update an
existing item, and accessibility is not part of the shared key's identity. Changing a value's JSON
representation also requires a migration. Read with the old configuration, write and verify the
new item, then delete the old one if appropriate. The app must have entitlements for both access
groups during such a migration.

### Separate encrypted app-storage identity from stored bytes

Sharing uses the logical key, UserDefaults store, and crypto-client identity to identify an
in-memory reference. Distinct crypto identities do not share a reference. This identity is not
persisted and does not re-encrypt or move stored bytes.

Two keys with distinct crypto identities can still point to the same UserDefaults entry. Their
references are separate, but one client's ciphertext may be unreadable to the other. Do not use
both configurations against the same stored key without a migration plan.

### Know what changes the stored data

`secureAppStorage("privateNote")` stores ciphertext as `Data` at the UserDefaults key
`secure_privateNote`. The logical key is passed to the crypto client as associated data. The
built-in AES-GCM client authenticates it, so renaming the key changes both the storage location and
the authenticated data. Copying its ciphertext to a new key is not enough.

Changing the UserDefaults store moves the location. Changing the crypto format or the Keychain
service, account, or access group may make existing ciphertext undecryptable. Changing Keychain
accessibility alone does not update an existing item; it only controls newly created items.

### Migrate deliberately

Read the value with the old configuration, write it under a new key or store, and verify the new
value before removing the old one. A save validates any existing ciphertext with its own crypto
client, so switching clients on the same UserDefaults entry cannot overwrite that entry directly.
If the old value cannot be decrypted or decoded, preserve it rather than writing an initial value.
Migration from another library's format belongs in the app and may require a custom
``SecureCryptoClient``.

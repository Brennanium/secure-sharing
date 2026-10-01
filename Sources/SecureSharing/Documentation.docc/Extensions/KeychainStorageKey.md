# ``KeychainStorageKey``

Persist a small `Codable` value in a generic-password Keychain item.

Create this key with `@Shared(.keychainStorage("account", service: "...", accessGroup: "..."))`.
The access group must be authorized for every signed target that uses the item. See
<doc:KeychainStorage> for accessibility, cross-process reloads, and testing. See
[type-safe keys](<doc:TypeSafeSecureKeys>) to define a reusable key.

## Topics

### Storage configuration

- ``KeychainStorageItem``
- ``Dependencies/DependencyValues/keychainStorageClient``
- ``SecureKeyStoreAccessibility``

### Identity

- ``KeychainStorageKeyID``

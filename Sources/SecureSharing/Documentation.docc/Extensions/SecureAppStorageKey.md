# ``SecureAppStorageKey``

Persist a shared value as encrypted UserDefaults data.

Create this key using `@Shared(.secureAppStorage("key"))` after configuring
``Dependencies/DependencyValues/secureAppStorageCrypto``. See <doc:GettingStarted> for setup,
<doc:SecureAppStorage> for storage behavior, and <doc:AvailabilityAndFailures> for failures.
See [type-safe keys](<doc:TypeSafeSecureKeys>) to reuse a name and configuration.

## Topics

### Configuration

- ``Dependencies/DependencyValues/secureAppStorageCrypto``
- ``Dependencies/DependencyValues/secureStorageStatus``

### Identifying storage

- ``SecureAppStorageKeyID``

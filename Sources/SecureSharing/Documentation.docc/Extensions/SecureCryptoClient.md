# ``SecureCryptoClient``

Choose how secure app storage encrypts and decrypts values.

For the common case, use ``keychain(service:account:accessGroup:accessibility:)`` in
`prepareDependencies`. It uses AES-GCM with a Keychain-backed symmetric key. For a different
symmetric-key source, use
[`AES.GCM.secureAppStorage(keyStore:)`](<doc:CryptoKit/AES/GCM/secureAppStorage(keyStore:)>)
with a ``SecureKeyStoreClient``.

Custom clients can use ``init(id:encrypt:decrypt:)``. They must encrypt the value and authenticate
the associated data passed to them. Their identity participates in Sharing's in-memory reference
lookup, so clients with the same identity must use compatible ciphertext formats and key material.
Changing that identity does not migrate persisted values; see <doc:ChangingSecureStorage>.

## Topics

### Built-in encryption

- ``keychain(service:account:accessGroup:accessibility:)``
- ``CryptoKit/AES/GCM/secureAppStorage(keyStore:)``

### Custom encryption

- ``init(id:encrypt:decrypt:)``

# iOS Keychain extension test

Run the `SecureSharingIOSTestHost` scheme from `Tests/IntegrationHost.xcodeproj` on an iOS device or
simulator. The app and its Action extension must use the same Keychain access group.

To check cross-process access:

1. Tap **Seed app-value** and confirm the status.
2. Tap **Open Safari** and share the page. Choose **SecureSharing Keychain Probe** from the actions list.
3. Confirm `Read: app-value`, tap **Replace with extension-value**, and then tap **Done**.
4. Return to the app and tap **Reload Keychain**. Confirm `extension-value`.

The `SecureSharingIOSIntegrationTests` scheme checks the host's Keychain access and extension
configuration, but does not invoke the extension. Repeat the manual flow on a device to verify
device-specific behavior.

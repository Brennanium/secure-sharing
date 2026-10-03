# iOS storage extension test

Run the `SecureSharingIOSTestHost` scheme from `Tests/IntegrationHost.xcodeproj` on an iOS device or
simulator. The app and its Action extension must use the same Keychain access group and App Group.

To check cross-process access:

1. Tap **Seed app-value** and **Seed encrypted app-value**. Confirm both statuses.
2. Tap **Open Safari** and share the page. Choose **SecureSharing Storage Probe** from the actions list.
3. Confirm `Read: app-value` and `Encrypted read: app-value`. Tap **Replace with extension-value**
   and **Replace encrypted value**, then **Done**.
4. Return to the app. Before reloading anything, confirm `Encrypted value: extension-value` and
   `Encrypted observation: Observed extension-value without reload`.
5. Tap **Reload Keychain** and confirm `extension-value`.

The `SecureSharingIOSIntegrationTests` scheme checks the signed host's Keychain and App Group
access, but does not invoke the extension. Repeat the manual flow on a device to verify
device-specific behavior. If the host was terminated while the extension ran, automatic observation
cannot be assessed from that run.

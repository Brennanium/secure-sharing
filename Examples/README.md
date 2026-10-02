# Examples

Open [Examples.xcodeproj](Examples.xcodeproj) and run the CaseStudies scheme on an iPhone or iOS Simulator running iOS 17 or later. Select your development team if Xcode requests one.

- **Encrypted note** stores ciphertext in UserDefaults and the encryption key in Keychain.
- **Authenticated refresh** signs in to DummyJSON with its public demo account, saves the access token in Keychain, and uses it for an authenticated request. The foreground button and system background callback save separate non-secret check records with their execution context.

## Try a background refresh

1. Sign in, then tap **Schedule background check**. The app shows the pending request's earliest eligible time.
2. Leave the app with the Home gesture. Do not swipe it away in the app switcher: that force-quits it.
3. Reopen the app later. **Last system background check** changes only when the `BGTask` callback runs. Its record includes the entry point, observed app state, and start time. A completion time appears once the request finishes.

**Check now (foreground)** only tests the authenticated request; it cannot prove background execution. The earliest eligible time is a lower bound, not a promised launch time. [Apple notes](https://developer.apple.com/documentation/backgroundtasks/starting-and-terminating-tasks-during-development) that a natural launch can take many hours. For a deterministic callback test on a physical device, set a breakpoint after `BGTaskScheduler.shared.submit`, then run this Apple-documented command in LLDB and resume:

```text
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.brennanium.SecureSharingCaseStudies.refresh"]
```

This debugger command is for development only and does not belong in shipped code. The callback record proves which handler ran; its observed app state may differ during debugger simulation. The demo account is public and must not be used for real data.

Storage identifiers and defaults live in `CaseStudyKeys.swift`. The authenticated refresh screen uses an observable model, and its tests run from the CaseStudies scheme with in-memory storage and stubbed network calls.

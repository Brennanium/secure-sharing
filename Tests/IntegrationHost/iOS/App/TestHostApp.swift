import SecureSharing
import Sharing
import SwiftUI
import UIKit

@main
struct SecureSharingIOSTestHost: App {
  var body: some Scene {
    WindowGroup {
      KeychainTestView()
    }
  }
}

private struct KeychainTestView: View {
  @State private var status = "Not checked"
  @State private var secureStatus = "Not checked"
  @Shared(.sharedNote) private var sharedNote: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Extension storage test")
        .font(.title.bold())
      Text("Seed both values, open Safari, and run SecureSharing Keychain Probe from a webpage's share sheet.")
      Text("App process: \(ProcessInfo.processInfo.processIdentifier)")
        .font(.caption.monospaced())
      Button("Seed app-value") {
        Task { await seed() }
      }
      Button("Seed encrypted app-value") {
        $sharedNote.withLock { $0 = KeychainFixture.appValue }
        secureStatus = $sharedNote.saveError.map { "Save failed: \($0)" } ?? "Seeded app-value"
      }
      Button("Open Safari") {
        if let url = URL(string: "https://example.com") {
          UIApplication.shared.open(url)
        }
      }
      Button("Reload Keychain") {
        Task { await reload() }
      }
      Text("Keychain: \(status)")
        .font(.callout.monospaced())
      Text("Encrypted value: \(sharedNote ?? "No value")")
        .font(.callout.monospaced())
      Text("Encrypted observation: \(secureStatus)")
        .font(.callout.monospaced())
      Spacer()
    }
    .padding(24)
    .frame(maxWidth: .infinity, alignment: .leading)
    .onChange(of: sharedNote) { newValue in
      if newValue == KeychainFixture.extensionValue {
        secureStatus = "Observed extension-value without reload"
      }
    }
  }

  private func seed() async {
    guard let group = KeychainFixture.accessGroup else {
      status = "Missing Keychain access group"
      return
    }
    @Shared(.keychainStorage(
      KeychainFixture.account,
      service: KeychainFixture.service,
      accessGroup: group
    )) var token: String?
    do {
      try await $token.load()
      $token.withLock { $0 = KeychainFixture.appValue }
      try await $token.save()
      status = "Seeded app-value"
    } catch {
      status = "Seed failed: \(error)"
    }
  }

  private func reload() async {
    guard let group = KeychainFixture.accessGroup else {
      status = "Missing Keychain access group"
      return
    }
    @Shared(.keychainStorage(
      KeychainFixture.account,
      service: KeychainFixture.service,
      accessGroup: group
    )) var token: String?
    do {
      try await $token.load()
      status = token ?? "No value"
    } catch {
      status = "Load failed: \(error)"
    }
  }
}

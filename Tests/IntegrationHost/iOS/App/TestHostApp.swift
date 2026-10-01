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

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Keychain extension test")
        .font(.title.bold())
      Text("Seed a value, open Safari, and run SecureSharing Keychain Probe from a webpage's share sheet. Return here and reload.")
      Text("App process: \(ProcessInfo.processInfo.processIdentifier)")
        .font(.caption.monospaced())
      Button("Seed app-value") {
        Task { await seed() }
      }
      Button("Open Safari") {
        if let url = URL(string: "https://example.com") {
          UIApplication.shared.open(url)
        }
      }
      Button("Reload Keychain") {
        Task { await reload() }
      }
      Text("Status: \(status)")
        .font(.callout.monospaced())
      Spacer()
    }
    .padding(24)
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

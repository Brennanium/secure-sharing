import SecureSharing
import Sharing
import UIKit

final class ActionViewController: UIViewController {
  private let statusLabel = UILabel()
  private let secureStatusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    statusLabel.numberOfLines = 0
    statusLabel.text = "Extension process: \(ProcessInfo.processInfo.processIdentifier)"
    secureStatusLabel.numberOfLines = 0
    secureStatusLabel.text = "Encrypted value: Not checked"

    let replaceButton = UIButton(type: .system)
    replaceButton.configuration = .filled()
    replaceButton.configuration?.title = "Replace with extension-value"
    replaceButton.addTarget(self, action: #selector(replaceValue), for: .touchUpInside)

    let replaceSecureButton = UIButton(type: .system)
    replaceSecureButton.configuration = .filled()
    replaceSecureButton.configuration?.title = "Replace encrypted value"
    replaceSecureButton.addTarget(self, action: #selector(replaceSecureValue), for: .touchUpInside)

    let doneButton = UIButton(type: .system)
    doneButton.configuration = .tinted()
    doneButton.configuration?.title = "Done"
    doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)

    let stack = UIStackView(arrangedSubviews: [
      statusLabel, replaceButton, secureStatusLabel, replaceSecureButton, doneButton,
    ])
    stack.axis = .vertical
    stack.spacing = 20
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    Task { await readValue() }
    readSecureValue()
  }

  private func readSecureValue() {
    @Shared(.sharedNote) var sharedNote: String?
    if let error = $sharedNote.loadError {
      secureStatusLabel.text = "Encrypted load failed: \(error)"
    } else {
      secureStatusLabel.text = "Encrypted read: \(sharedNote ?? "No value")"
    }
  }

  private func readValue() async {
    guard let group = KeychainFixture.accessGroup else {
      statusLabel.text = "Missing Keychain access group"
      return
    }
    @Shared(.keychainStorage(
      KeychainFixture.account,
      service: KeychainFixture.service,
      accessGroup: group
    )) var token: String?
    do {
      try await $token.load()
      statusLabel.text = "Extension process: \(ProcessInfo.processInfo.processIdentifier)\nRead: \(token ?? "No value")"
    } catch {
      statusLabel.text = "Extension load failed: \(error)"
    }
  }

  @objc private func replaceValue() {
    Task { await replaceStoredValue() }
  }

  @objc private func replaceSecureValue() {
    @Shared(.sharedNote) var sharedNote: String?
    guard sharedNote == KeychainFixture.appValue else {
      secureStatusLabel.text = $sharedNote.loadError.map { "Encrypted load failed: \($0)" }
        ?? "Expected app-value, found \(sharedNote ?? "No value")"
      return
    }
    $sharedNote.withLock { $0 = KeychainFixture.extensionValue }
    secureStatusLabel.text = $sharedNote.saveError.map { "Encrypted save failed: \($0)" }
      ?? "Replaced encrypted value"
  }

  private func replaceStoredValue() async {
    guard let group = KeychainFixture.accessGroup else {
      statusLabel.text = "Missing Keychain access group"
      return
    }
    @Shared(.keychainStorage(
      KeychainFixture.account,
      service: KeychainFixture.service,
      accessGroup: group
    )) var token: String?
    do {
      try await $token.load()
      guard token == KeychainFixture.appValue else {
        statusLabel.text = "Expected app-value, found \(token ?? "No value")"
        return
      }
      $token.withLock { $0 = KeychainFixture.extensionValue }
      try await $token.save()
      statusLabel.text = "Replaced with extension-value"
    } catch {
      statusLabel.text = "Extension save failed: \(error)"
    }
  }

  @objc private func done() {
    extensionContext?.completeRequest(returningItems: nil)
  }
}

import SecureSharing
import Sharing
import UIKit

final class ActionViewController: UIViewController {
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    statusLabel.numberOfLines = 0
    statusLabel.text = "Extension process: \(ProcessInfo.processInfo.processIdentifier)"

    let replaceButton = UIButton(type: .system)
    replaceButton.configuration = .filled()
    replaceButton.configuration?.title = "Replace with extension-value"
    replaceButton.addTarget(self, action: #selector(replaceValue), for: .touchUpInside)

    let doneButton = UIButton(type: .system)
    doneButton.configuration = .tinted()
    doneButton.configuration?.title = "Done"
    doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)

    let stack = UIStackView(arrangedSubviews: [statusLabel, replaceButton, doneButton])
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

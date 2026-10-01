import Foundation
import SecureSharing
import Sharing

private let service = "com.brennanium.secure-sharing.integration-tests"

private final class KeychainProbe: NSObject, KeychainProbeProtocol {
  func replaceValue(
    account: String,
    accessGroup: String,
    expected: String,
    replacement: String,
    reply: @escaping (Bool, NSNumber, NSString?) -> Void
  ) {
    let processID = NSNumber(value: ProcessInfo.processInfo.processIdentifier)
    @Shared(.keychainStorage(account, service: service, accessGroup: accessGroup))
    var storedValue: String?
    guard storedValue == expected else {
      let message = $storedValue.loadError.map(String.init(describing:))
        ?? "The XPC service could not read the host's value."
      reply(false, processID, message as NSString)
      return
    }
    $storedValue.withLock { $0 = replacement }
    if let error = $storedValue.saveError {
      reply(false, processID, String(describing: error) as NSString)
    } else {
      reply(true, processID, nil)
    }
  }
}

private final class KeychainProbeListener: NSObject, NSXPCListenerDelegate {
  private let probe = KeychainProbe()

  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection)
    -> Bool
  {
    connection.exportedInterface = NSXPCInterface(with: KeychainProbeProtocol.self)
    connection.exportedObject = probe
    connection.resume()
    return true
  }
}

@main
private enum KeychainProbeService {
  static func main() {
    let listenerDelegate = KeychainProbeListener()
    let listener = NSXPCListener.service()
    listener.delegate = listenerDelegate
    listener.resume()
    RunLoop.current.run()
  }
}

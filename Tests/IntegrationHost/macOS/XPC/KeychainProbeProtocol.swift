import Foundation

@objc protocol KeychainProbeProtocol {
  func replaceValue(
    account: String,
    accessGroup: String,
    expected: String,
    replacement: String,
    reply: @escaping (Bool, NSNumber, NSString?) -> Void
  )
}

import Sharing

private protocol OptionalValue {
  static var nilValue: Self { get }
}

extension Optional: OptionalValue {
  static var nilValue: Self { nil }
}

func missingStoredValue<Value>(for context: LoadContext<Value>) -> Value? {
  if let initialValue = context.initialValue {
    return initialValue
  }
  guard let optionalType = Value.self as? any OptionalValue.Type else { return nil }
  return optionalType.nilValue as? Value
}

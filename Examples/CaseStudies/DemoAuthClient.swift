import Dependencies
import DependenciesMacros
import Foundation

private struct UserResponse: Decodable {
  let username: String
}

@DependencyClient
struct DemoAuthClient: Sendable {
  var signIn: @Sendable () async throws -> DemoSession
  var currentUser: @Sendable (_ accessToken: String) async throws -> String
}

extension DemoAuthClient: DependencyKey {
  static var liveValue: Self {
    Self(signIn: LiveDemoAuthClient.signIn, currentUser: LiveDemoAuthClient.currentUser)
  }

  static var testValue: Self {
    Self()
  }
}

extension DependencyValues {
  var demoAuthClient: DemoAuthClient {
    get { self[DemoAuthClient.self] }
    set { self[DemoAuthClient.self] = newValue }
  }
}

private enum LiveDemoAuthClient {
  private static let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.httpShouldSetCookies = false
    return URLSession(configuration: configuration)
  }()

  static func signIn() async throws -> DemoSession {
    var request = URLRequest(url: URL(string: "https://dummyjson.com/auth/login")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode([
      "username": "emilys",
      "password": "emilyspass",
    ])
    return try await send(request)
  }

  static func currentUser(accessToken: String) async throws -> String {
    var request = URLRequest(url: URL(string: "https://dummyjson.com/auth/me")!)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    let response: UserResponse = try await send(request)
    return response.username
  }

  private static func send<Value: Decodable>(_ request: URLRequest) async throws -> Value {
    let (data, response) = try await session.data(for: request)
    guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
      throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode(Value.self, from: data)
  }
}

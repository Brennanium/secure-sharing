import DependenciesTestSupport
import Foundation
import Sharing
import Testing
@testable import CaseStudies

@MainActor
struct AuthenticatedRefreshModelTests {
  @Test(
    .dependencies {
      $0.date.now = Date(timeIntervalSince1970: 1_000)
      $0.demoAuthClient = DemoAuthClient(
        signIn: { DemoSession(accessToken: "test-token") },
        currentUser: { token in
          #expect(token == "test-token")
          return "emilys"
        }
      )
      $0.demoBackgroundRefresh = DemoBackgroundRefreshClient(
        schedule: {},
        cancel: {},
        pendingEarliestBeginDate: { Date(timeIntervalSince1970: 1_900) }
      )
    }
  )
  func signInRefreshAndSignOut() async {
    let model = AuthenticatedRefreshModel()

    await model.signInButtonTapped()
    #expect(model.session?.accessToken == "test-token")
    #expect(model.message == "Signed in. Background refresh requested.")
    #expect(model.pendingEarliestBeginDate == Date(timeIntervalSince1970: 1_900))

    await model.runNowButtonTapped()
    #expect(model.lastForegroundCheck?.result == "Authenticated request succeeded")
    #expect(model.lastForegroundCheck?.completedAt == Date(timeIntervalSince1970: 1_000))
    #expect(model.lastForegroundCheck?.source == .foregroundButton)
    #expect(model.lastBackgroundCheck == nil)
    #expect(model.message == nil)

    await model.signOutButtonTapped()
    #expect(model.session == nil)
    #expect(model.message == "Signed out.")
    #expect(model.pendingEarliestBeginDate == nil)
  }

  @Test(
    .dependencies {
      $0.date.now = Date(timeIntervalSince1970: 2_000)
      $0.demoAuthClient = DemoAuthClient(
        signIn: { DemoSession(accessToken: "test-token") },
        currentUser: { _ in throw URLError(.badServerResponse) }
      )
      $0.demoBackgroundRefresh = DemoBackgroundRefreshClient(
        schedule: {}, cancel: {}, pendingEarliestBeginDate: { nil }
      )
    }
  )
  func failedRequestStoresOnlyGenericStatus() async {
    let model = AuthenticatedRefreshModel()
    await model.signInButtonTapped()

    await model.runNowButtonTapped()

    #expect(model.lastForegroundCheck?.result == "Check failed")
    #expect(model.lastForegroundCheck?.completedAt == Date(timeIntervalSince1970: 2_000))
    #expect(model.lastBackgroundCheck == nil)
    #expect(model.message != nil)
  }

  @Test(
    .dependencies {
      $0.date.now = Date(timeIntervalSince1970: 3_000)
      $0.demoAuthClient = DemoAuthClient(
        signIn: { DemoSession(accessToken: "test-token") },
        currentUser: { _ in
          @Shared(.lastBackgroundCheck) var lastBackgroundCheck
          #expect(lastBackgroundCheck?.result == "Started")
          #expect(lastBackgroundCheck?.completedAt == nil)
          return "emilys"
        }
      )
      $0.demoBackgroundRefresh = DemoBackgroundRefreshClient(
        schedule: {}, cancel: {}, pendingEarliestBeginDate: { nil }
      )
    }
  )
  func backgroundCallbackWritesSeparateRecord() async throws {
    let model = AuthenticatedRefreshModel()
    await model.signInButtonTapped()

    try await AuthenticatedRefresh.run(source: .backgroundTask)

    #expect(model.lastBackgroundCheck?.source == .backgroundTask)
    #expect(model.lastBackgroundCheck?.result == "Authenticated request succeeded")
    #expect(model.lastBackgroundCheck?.startedAt == Date(timeIntervalSince1970: 3_000))
    #expect(model.lastBackgroundCheck?.completedAt == Date(timeIntervalSince1970: 3_000))
    #expect(model.lastForegroundCheck == nil)
  }
}

import Dependencies
import Foundation
import Observation
import Sharing

@MainActor
@Observable
final class AuthenticatedRefreshModel {
  @ObservationIgnored @Dependency(\.demoAuthClient) private var authClient
  @ObservationIgnored @Dependency(\.demoBackgroundRefresh) private var backgroundRefresh
  @ObservationIgnored @Shared(.demoSession) var session
  @ObservationIgnored @Shared(.lastForegroundCheck) var lastForegroundCheck
  @ObservationIgnored @Shared(.lastBackgroundCheck) var lastBackgroundCheck

  var isWorking = false
  var message: String?
  var pendingEarliestBeginDate: Date?

  func viewAppeared() async {
    var failures: [String] = []
    do {
      try await $session.load()
    } catch {
      failures.append("Session: \(error.localizedDescription)")
    }
    do {
      try await $lastForegroundCheck.load()
    } catch {
      failures.append("Foreground check: \(error.localizedDescription)")
    }
    do {
      try await $lastBackgroundCheck.load()
    } catch {
      failures.append("Background check: \(error.localizedDescription)")
    }
    message = failures.isEmpty ? nil : failures.joined(separator: "\n")
    pendingEarliestBeginDate = await backgroundRefresh.pendingEarliestBeginDate()
  }

  func signInButtonTapped() async {
    isWorking = true
    defer { isWorking = false }
    do {
      let newSession = try await authClient.signIn()
      $session.withLock { $0 = newSession }
      try await $session.save()
      do {
        try backgroundRefresh.schedule()
        pendingEarliestBeginDate = await backgroundRefresh.pendingEarliestBeginDate()
        message = "Signed in. Background refresh requested."
      } catch {
        message = "Signed in, but background refresh could not be scheduled: \(error.localizedDescription)"
      }
    } catch {
      message = error.localizedDescription
    }
  }

  func signOutButtonTapped() async {
    isWorking = true
    defer { isWorking = false }
    do {
      $session.withLock { $0 = nil }
      try await $session.save()
      backgroundRefresh.cancel()
      pendingEarliestBeginDate = nil
      message = "Signed out."
    } catch {
      message = error.localizedDescription
    }
  }

  func scheduleButtonTapped() async {
    do {
      try backgroundRefresh.schedule()
      pendingEarliestBeginDate = await backgroundRefresh.pendingEarliestBeginDate()
      message = "Background refresh requested."
    } catch {
      message = error.localizedDescription
    }
  }

  func runNowButtonTapped() async {
    isWorking = true
    defer { isWorking = false }
    do {
      try await AuthenticatedRefresh.run(source: .foregroundButton)
      message = nil
    } catch {
      message = error.localizedDescription
    }
  }
}

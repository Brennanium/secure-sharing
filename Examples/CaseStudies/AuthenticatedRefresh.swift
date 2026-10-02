import BackgroundTasks
import Dependencies
import Foundation
import Sharing
import UIKit

struct DemoBackgroundRefreshClient: Sendable {
  var schedule: @Sendable () throws -> Void
  var cancel: @Sendable () -> Void
  var pendingEarliestBeginDate: @Sendable () async -> Date?
}

extension DemoBackgroundRefreshClient: DependencyKey {
  static var liveValue: Self {
    Self(
      schedule: {
        @Dependency(\.date.now) var now
        let request = BGAppRefreshTaskRequest(identifier: AuthenticatedRefresh.taskIdentifier)
        request.earliestBeginDate = now.addingTimeInterval(15 * 60)
        try BGTaskScheduler.shared.submit(request)
      },
      cancel: {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: AuthenticatedRefresh.taskIdentifier)
      },
      pendingEarliestBeginDate: {
        await withCheckedContinuation { continuation in
          BGTaskScheduler.shared.getPendingTaskRequests { requests in
            continuation.resume(
              returning: requests.first { $0.identifier == AuthenticatedRefresh.taskIdentifier }?
                .earliestBeginDate
            )
          }
        }
      }
    )
  }

  static var testValue: Self {
    Self(
      schedule: unimplemented("DemoBackgroundRefreshClient.schedule"),
      cancel: unimplemented("DemoBackgroundRefreshClient.cancel"),
      pendingEarliestBeginDate: unimplemented(
        "DemoBackgroundRefreshClient.pendingEarliestBeginDate", placeholder: nil as Date?
      )
    )
  }
}

extension DependencyValues {
  var demoBackgroundRefresh: DemoBackgroundRefreshClient {
    get { self[DemoBackgroundRefreshClient.self] }
    set { self[DemoBackgroundRefreshClient.self] = newValue }
  }
}

enum AuthenticatedRefresh {
  static let taskIdentifier = "com.brennanium.SecureSharingCaseStudies.refresh"

  static func schedule() throws {
    @Dependency(\.demoBackgroundRefresh) var backgroundRefresh
    try backgroundRefresh.schedule()
  }

  static func run(source: AuthenticatedCheckRecord.Source) async throws {
    @Dependency(\.demoAuthClient) var authClient
    @Dependency(\.date) var date
    let observedApplicationState = await applicationState()
    let startedAt = date.now
    try await record(
      "Started", source: source, observedApplicationState: observedApplicationState,
      startedAt: startedAt, completedAt: nil
    )
    @Shared(.demoSession) var session
    do {
      try await $session.load()
    } catch {
      try await record(
        "Session load failed", source: source, observedApplicationState: observedApplicationState,
        startedAt: startedAt, completedAt: date.now
      )
      throw error
    }
    guard let session else {
      try await record(
        "No saved session", source: source, observedApplicationState: observedApplicationState,
        startedAt: startedAt, completedAt: date.now
      )
      return
    }
    do {
      _ = try await authClient.currentUser(accessToken: session.accessToken)
    } catch {
      try await record(
        "Check failed", source: source, observedApplicationState: observedApplicationState,
        startedAt: startedAt, completedAt: date.now
      )
      throw error
    }
    try await record(
      "Authenticated request succeeded", source: source,
      observedApplicationState: observedApplicationState, startedAt: startedAt,
      completedAt: date.now
    )
  }

  private static func record(
    _ result: String,
    source: AuthenticatedCheckRecord.Source,
    observedApplicationState: AuthenticatedCheckRecord.ApplicationState,
    startedAt: Date,
    completedAt: Date?
  ) async throws {
    let record = AuthenticatedCheckRecord(
      source: source,
      observedApplicationState: observedApplicationState,
      result: result,
      startedAt: startedAt,
      completedAt: completedAt
    )
    switch source {
    case .foregroundButton:
      @Shared(.lastForegroundCheck) var lastForegroundCheck
      $lastForegroundCheck.withLock { $0 = record }
      try await $lastForegroundCheck.save()
    case .backgroundTask:
      @Shared(.lastBackgroundCheck) var lastBackgroundCheck
      $lastBackgroundCheck.withLock { $0 = record }
      try await $lastBackgroundCheck.save()
    }
  }

  private static func applicationState() async -> AuthenticatedCheckRecord.ApplicationState {
    await MainActor.run {
      switch UIApplication.shared.applicationState {
      case .active: .active
      case .inactive: .inactive
      case .background: .background
      @unknown default: .inactive
      }
    }
  }
}

import SwiftUI

struct AuthenticatedRefreshView: View {
  @Environment(\.scenePhase) private var scenePhase
  @State private var model = AuthenticatedRefreshModel()

  var body: some View {
    Form {
      Section("Session") {
        LabeledContent("Keychain token", value: model.session == nil ? "Not signed in" : "Saved")
        Button("Sign in with demo account") {
          Task { await model.signInButtonTapped() }
        }
        .disabled(model.isWorking)
        if model.session != nil {
          Button("Sign out", role: .destructive) {
            Task { await model.signOutButtonTapped() }
          }
          .disabled(model.isWorking)
        }
      }
      Section {
        Button("Schedule background check") {
          Task { await model.scheduleButtonTapped() }
        }
        .disabled(model.isWorking || model.session == nil)
        if let pendingEarliestBeginDate = model.pendingEarliestBeginDate {
          LabeledContent("Earliest eligible", value: pendingEarliestBeginDate.formatted())
        } else {
          LabeledContent("Pending request", value: "None")
        }
      } header: {
        Text("Scheduled refresh")
      } footer: {
        Text("Leave the app with the Home gesture; don't force quit it. iOS may run the request later, but the earliest date is not a promise.")
      }
      Section {
        CheckRecordDetails(record: model.lastBackgroundCheck)
      } header: {
        Text("Last system background check")
      } footer: {
        Text("Only the system's BGTask callback can update this record. Reopen the app to inspect it after the task runs.")
      }
      Section {
        Button("Check now (foreground)") {
          Task { await model.runNowButtonTapped() }
        }
        .disabled(model.isWorking || model.session == nil)
        CheckRecordDetails(record: model.lastForegroundCheck)
        if let message = model.message {
          Text(message).foregroundStyle(.secondary)
        }
      } header: {
        Text("Foreground check")
      } footer: {
        Text("This tests the authenticated request, not background execution. Records contain no access token.")
      }
    }
    .navigationTitle("Authenticated refresh")
    .task { await model.viewAppeared() }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        Task { await model.viewAppeared() }
      }
    }
  }
}

private struct CheckRecordDetails: View {
  let record: AuthenticatedCheckRecord?

  var body: some View {
    if let record {
      LabeledContent("Result", value: record.result)
      LabeledContent("Started", value: record.startedAt.formatted())
      if let completedAt = record.completedAt {
        LabeledContent("Completed", value: completedAt.formatted())
      }
      LabeledContent(
        "Entry point",
        value: record.source == .backgroundTask ? "BGTask callback" : "Foreground button"
      )
      LabeledContent("App state at start", value: record.observedApplicationState.rawValue)
    } else {
      Text("No check recorded")
        .foregroundStyle(.secondary)
    }
  }
}

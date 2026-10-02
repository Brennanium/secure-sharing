import BackgroundTasks
import Dependencies
import SecureSharing
import SwiftUI

@main
struct CaseStudiesApp: App {
  init() {
    prepareDependencies {
      $0.secureAppStorageCrypto = .caseStudies
    }
  }

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        Form {
          Section("Persistence") {
            NavigationLink("Encrypted note") { EncryptedNoteView() }
            NavigationLink("Authenticated refresh") { AuthenticatedRefreshView() }
          }
        }
        .navigationTitle("Case studies")
      }
    }
    .backgroundTask(.appRefresh(AuthenticatedRefresh.taskIdentifier)) {
      do {
        try AuthenticatedRefresh.schedule()
      } catch {
        reportIssue(error)
      }
      do {
        try await AuthenticatedRefresh.run(source: .backgroundTask)
      } catch {
        reportIssue(error)
      }
    }
  }
}

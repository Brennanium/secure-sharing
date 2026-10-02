import SecureSharing
import Sharing
import SwiftUI

struct EncryptedNoteView: View {
  @Shared(.privateNote) private var note

  var body: some View {
    Form {
      Section {
        if let loadError = $note.loadError {
          Text("The note could not be loaded: \(loadError.localizedDescription)")
            .foregroundStyle(.red)
        } else {
          TextField("Private note", text: Binding($note), axis: .vertical)
          if let saveError = $note.saveError {
            Text("The latest edit was not saved: \(saveError.localizedDescription)")
              .foregroundStyle(.red)
          }
        }
      } footer: {
        Text("The note is encrypted in UserDefaults. Its encryption key is stored in Keychain.")
      }
    }
    .navigationTitle("Encrypted note")
  }
}

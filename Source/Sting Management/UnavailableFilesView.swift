import SwiftUI

struct UnavailableFilesView: View {
    let show: Show
    @Binding var stings: [Sting]
    
    @State var isPresentingFolderPicker = false
    
    var body: some View {
        List(stings, id: \.self) { sting in
            UnavailableStingCell(sting: sting, show: show)
        }
        .safeAreaBar(edge: .top) {
            VStack {
                Text("Sting Pad is unable to access the following files on this device. Ensure they are downloaded in the Files app and grant access to the containing folder to load your stings.")
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.bottom, 1)
                Button ("Access Folder") { isPresentingFolderPicker = true }
                    .font(.body.bold())
            }
        }
        .navigationTitle("Manage Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .sheet(isPresented: $isPresentingFolderPicker) {
            FolderAccessView(show: show)
                .presentationSizing(.fitted)
        }
    }
}

import SwiftUI

struct UnavailableFilesView: View {
    let show: Show
    @Binding var stings: [Sting]
    
    @State var isPresentingFolderPicker = false
    
    var body: some View {
        VStack {
            Text("Sting Pad is unable to access the following files on this device. Ensure they are downloaded in the Files app and grant access to the containing folder to load your stings.")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 1)
            Button ("Access Folder") { isPresentingFolderPicker = true }
            List(stings, id: \.self) { sting in
                ManageStingCell(sting: sting)
            }
            .listStyle(GroupedListStyle())
            .overlay(Divider(), alignment: .top)
        }
        .navigationBarTitle("Manage Permissions")
        .sheet(isPresented: $isPresentingFolderPicker) {
            FolderAccessView(show: show)
        }
    }
}

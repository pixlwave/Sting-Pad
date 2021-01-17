import SwiftUI

struct ManageStingsView: View {
    @State var noSuchSongStings = [Sting]()
    @State var noPermissionStings = [Sting]()
    @State var noSuchFileStings = [Sting]()
    
    let show: Show
    
    var dismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("Missing Song (\(noSuchSongStings.count))",
                               destination: Text("Missing Song"))
                    .disabled(noSuchSongStings.count == 0)
                NavigationLink("Access Denied (\(noPermissionStings.count))",
                               destination: ManagePermissionsView(show: show, stings: $noPermissionStings))
                    .disabled(noPermissionStings.count == 0)
                NavigationLink("Missing File (\(noSuchFileStings.count))",
                               destination: Text("Access Denied"))
                    .disabled(noSuchFileStings.count == 0)
            }
            .navigationBarTitle("Manage Stings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss?() }
                }
            }
        }
        .onAppear { reloadData() }
    }
    
    func reloadData() {
        noPermissionStings = show.missingStings.filter { $0.availability == .noPermission }
        noSuchFileStings = show.missingStings.filter { $0.availability == .noSuchFile }
        noSuchSongStings = show.missingStings.filter { $0.availability == .noSuchSong }
    }
}

struct ManagePermissionsView: View {
    let show: Show
    @Binding var stings: [Sting]
    
    @State var isPresentingFolderPicker = false
    
    var body: some View {
        VStack {
            Text("Sting Pad has been denied access to the following files on this device.")
            List(stings, id: \.self) { sting in
                Section(header: Text("Access denied")) {
                    Button ("Access Folder") { isPresentingFolderPicker = true }
                        .foregroundColor(.accentColor)
                    MissingStingsCell(sting: sting)
                }
            }
            .listStyle(GroupedListStyle())
        }
        .navigationBarTitle("Manage Permissions")
        .sheet(isPresented: $isPresentingFolderPicker) {
            FolderAccessView(show: show)
        }
    }
}

struct MissingStingsCell: View {
    let sting: Sting
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(sting.name ?? sting.songTitle)
                Text(sting.name == nil ? sting.songArtist : sting.songTitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button { } label: { sting.availability == .noPermission ? Image(systemName: "lock.open") : Image(systemName: "magnifyingglass") }
                .buttonStyle(BorderlessButtonStyle())
        }
    }
}

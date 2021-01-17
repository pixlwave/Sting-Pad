import SwiftUI

struct ManageStingsView: View {
    @State var noSuchSongStings = [Sting]()
    @State var noPermissionStings = [Sting]()
    @State var noSuchFileStings = [Sting]()
    
    let show: Show
    
    var dismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                NavigationLink("Missing Song (\(noSuchSongStings.count))",
                               destination: ManageSongsView(show: show, stings: $noSuchSongStings))
                    .disabled(noSuchSongStings.count == 0)
                NavigationLink("Access Denied (\(noPermissionStings.count))",
                               destination: ManagePermissionsView(show: show, stings: $noPermissionStings))
                    .disabled(noPermissionStings.count == 0)
                NavigationLink("Missing File (\(noSuchFileStings.count))",
                               destination: ManageFilesView(show: show, stings: $noSuchFileStings))
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
        noPermissionStings = show.unavailableStings.filter { $0.availability == .noPermission }
        noSuchFileStings = show.unavailableStings.filter { $0.availability == .noSuchFile }
        noSuchSongStings = show.unavailableStings.filter { $0.availability == .noSuchSong }
    }
}

struct ManageSongsView: View {
    let show: Show
    @Binding var stings: [Sting]
    
    @State var isPresentingSongPicker = false
    
    var body: some View {
        VStack {
            Text("Sting Pad is unable to locate the following songs in your music library. Ensure they have been downloaded to your device and reopen the show, or replace them manually below.")
                .font(.headline)
                .padding(.horizontal)
            List(stings, id: \.self) { sting in
                ManageStingCell(sting: sting)
            }
            .listStyle(GroupedListStyle())
            .overlay(Divider(), alignment: .top)
        }
        .navigationBarTitle("Manage Songs")
        .sheet(isPresented: $isPresentingSongPicker) {
            Text("Todo")
        }
    }
}

struct ManagePermissionsView: View {
    let show: Show
    @Binding var stings: [Sting]
    
    @State var isPresentingFolderPicker = false
    
    var body: some View {
        VStack {
            Text("Sting Pad has been denied access to the following files on this device. You can fix this by opening the containing folder, or by re-opening each sting manually.")
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

struct ManageFilesView: View {
    let show: Show
    @Binding var stings: [Sting]
    
    @State var isPresentingFilePicker = false
    
    var body: some View {
        VStack {
            Text("Sting Pad is unable to locate the following files on this device. Ensure they have been downloaded to your device and then re-open the show, or replace them manually below.")
                .font(.headline)
                .padding(.horizontal)
            List(stings, id: \.self) { sting in
                ManageStingCell(sting: sting)
            }
            .listStyle(GroupedListStyle())
            .overlay(Divider(), alignment: .top)
        }
        .navigationBarTitle("Manage Files")
        .sheet(isPresented: $isPresentingFilePicker) {
            Text("Todo")
        }
    }
}

struct ManageStingCell: View {
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

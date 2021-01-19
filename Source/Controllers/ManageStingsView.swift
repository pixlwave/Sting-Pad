import SwiftUI

struct ManageStingsView: View {
    @State var noPermissionStings = [Sting]()
    @State var missingStings = [Sting]()
    
    let show: Show
    
    var dismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Unavailable stings")) {
                    NavigationLink(destination: ManagePermissionsView(show: show, stings: $noPermissionStings)) {
                        Label {
                            Text("Access Denied (\(noPermissionStings.count))")
                        } icon: {
                            Image(systemName: "lock.square")
                                .foregroundColor(.red)
                        }
                        .font(.headline)
                    }
                    .disabled(noPermissionStings.count == 0)
                    
                    NavigationLink(destination: MissingStingsView(show: show, stings: $missingStings)) {
                        Label {
                            Text("Missing (\(missingStings.count))")
                        } icon: {
                            Image(systemName: "questionmark.square.dashed")
                                .foregroundColor(.red)
                        }
                        .font(.headline)
                    }
                    .disabled(missingStings.count == 0)
                }
            }
            .listStyle(GroupedListStyle())
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
        missingStings = show.unavailableStings.filter {
            $0.availability == .noSuchSong || $0.availability == .noSuchFile || $0.availability == .isCloudSong
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

struct MissingStingsView: View {
    let show: Show
    @Binding var stings: [Sting]
    
    var body: some View {
        VStack {
            Text("Sting Pad is unable to locate the following stings on your device. Ensure that they have been downloaded and reopen the show or replace them manually below.")
                .font(.headline)
                .padding(.horizontal)
            List(stings, id: \.self) { sting in
                ManageStingCell(sting: sting)
            }
            .listStyle(GroupedListStyle())
            .overlay(Divider(), alignment: .top)
        }
        .navigationBarTitle("Missing Stings")
    }
}

struct ManageStingCell: View {
    let sting: Sting
    
    @State var isPresentingPicker = false
    
    var body: some View {
        HStack {
            Image(systemName: sting.url.isMediaItem ? "music.note" : "doc")
            VStack(alignment: .leading) {
                Text(sting.name ?? sting.songTitle)
                Text(sting.name == nil ? sting.songArtist : sting.songTitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button { isPresentingPicker = true } label: {
                sting.availability == .noPermission ? Image(systemName: "lock.open") : Image(systemName: "magnifyingglass")
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .sheet(isPresented: $isPresentingPicker) {
            Text("Not implemented. Long press on this sting in your show and choose replace.")
        }
    }
}

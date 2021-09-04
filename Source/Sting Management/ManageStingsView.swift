import SwiftUI

struct ManageStingsView: View {
    @State var unavailableSongs = [Sting]()
    @State var unavailableFiles = [Sting]()
    
    let show: Show
    
    let dismiss: (() -> Void)
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Unavailable stings")) {
                    NavigationLink(destination: UnavailableSongsView(show: show, stings: $unavailableSongs)) {
                        Label {
                            Text("Songs (\(unavailableSongs.count))")
                        } icon: {
                            Image(systemName: "music.note")
                                .foregroundColor(.red)
                        }
                        .font(.headline)
                    }
                    .disabled(unavailableSongs.count == 0)
                    
                    NavigationLink(destination: UnavailableFilesView(show: show, stings: $unavailableFiles)) {
                        Label {
                            Text("Files (\(unavailableFiles.count))")
                        } icon: {
                            Image(systemName: "doc")
                                .foregroundColor(.red)
                        }
                        .font(.headline)
                    }
                    .disabled(unavailableFiles.count == 0)
                }
                
                Section {
                    Button("DEBUG: Remove all bookmarks") {
                        FolderBookmarks.shared.clear()
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Manage Stings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear { reloadData() }
        .onReceive(NotificationCenter.default.publisher(for: .didTryReloadingUnavailableStings)) { _ in
            reloadData()
        }
    }
    
    func reloadData() {
        unavailableSongs = show.unavailableSongs
        unavailableFiles = show.unavailableFiles
    }
}

struct ManageStingCell: View {
    @ObservedObject var sting: Sting
    
    @State var isPresentingPicker = false
    
    var body: some View {
        Button { isPresentingPicker = true } label: {
            HStack {
                Image(systemName: sting.url.isMediaItem ? "music.note" : "doc")
                
                VStack(alignment: .leading) {
                    Text(sting.name ?? sting.songTitle)
                    Text(sting.name == nil ? sting.songArtist : sting.songTitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                switch sting.availability {
                case .noPermission:
                    Image(systemName: "lock")
                case .noSuchSong, .noSuchFile:
                    Image(systemName: "questionmark.square.dashed")
                case .isCloudSong:
                    Image(systemName: "icloud")
                default:
                    Image(systemName: "exclamationmark.triangle")
                }
            }
        }
        .foregroundColor(.primary)
        .sheet(isPresented: $isPresentingPicker) {
            Text("Not implemented. Long press on this sting in your show and choose replace.")
        }
    }
}

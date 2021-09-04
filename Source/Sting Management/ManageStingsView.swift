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
        .onReceive(NotificationCenter.default.publisher(for: .unavailableStingsDidChange)) { _ in
            reloadData()
        }
    }
    
    func reloadData() {
        unavailableSongs = show.unavailableSongs
        unavailableFiles = show.unavailableFiles
    }
}

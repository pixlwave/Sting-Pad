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
                                .foregroundColor(unavailableSongs.isEmpty ? .primary : .red)
                        }
                        .font(.headline)
                    }
                    .disabled(unavailableSongs.isEmpty)
                    
                    NavigationLink(destination: UnavailableFilesView(show: show, stings: $unavailableFiles)) {
                        Label {
                            Text("Files (\(unavailableFiles.count))")
                        } icon: {
                            Image(systemName: "doc")
                                .foregroundColor(unavailableFiles.isEmpty ? .primary : .red)
                        }
                        .font(.headline)
                    }
                    .disabled(unavailableFiles.isEmpty)
                }
                
                #if DEBUG
                Section {
                    Button("DEBUG: Remove all bookmarks") {
                        FolderBookmarks.shared.clear()
                    }
                }
                #endif
            }
            .navigationBarTitle("Manage Stings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear(perform: reloadData)
        .onReceive(NotificationCenter.default.publisher(for: .unavailableStingsDidChange)) { _ in
            reloadData()
        }
    }
    
    func reloadData() {
        withAnimation {
            unavailableSongs = show.unavailableSongs
            unavailableFiles = show.unavailableFiles
        }
    }
}

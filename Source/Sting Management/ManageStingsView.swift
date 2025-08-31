import SwiftUI

struct ManageStingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let show: Show
    
    @State private var unavailableSongs = [Sting]()
    @State private var unavailableFiles = [Sting]()
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Manage Stings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
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

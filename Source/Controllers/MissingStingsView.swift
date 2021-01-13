import SwiftUI

struct MissingStingsView: View {
    let show: Show
    
    var dismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: HeaderView(title: "Access denied", description: "Sting Pad requires permission to open these files.")) {
                    Button ("Access Folder") { }
                        .foregroundColor(.accentColor)
                    ForEach(show.missingStings.filter { $0.availability == .noPermission }) { sting in
                        MissingStingsCell(sting: sting)
                    }
                }
                Section(header: HeaderView(title: "File Not Found", description: "These stings cannot be found on your device.")) {
                    ForEach(show.missingStings.filter { $0.availability == .noSuchFile }) { sting in
                        MissingStingsCell(sting: sting)
                    }
                }
                Section(header: HeaderView(title: "Song Not Found", description: "These stings cannot be found on your device.")) {
                    ForEach(show.missingStings.filter { $0.availability == .noSuchSong }) { sting in
                        MissingStingsCell(sting: sting)
                    }
                }
            }
//            .listStyle(GroupedListStyle())
            .navigationBarTitle("Missing Stings", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss?() }
                }
            }
        }
    }
}


struct HeaderView: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            Text(description)
                .font(.footnote)
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

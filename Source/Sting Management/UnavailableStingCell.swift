import SwiftUI

struct UnavailableStingCell: View {
    @ObservedObject var sting: Sting
    let show: Show
    
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
            if sting.url.isMediaItem {
                SongPicker(show: show, pickerOperation: .locate(sting))
            } else {
                FilePicker(show: show, pickerOperation: .locate(sting))
            }
        }
    }
}

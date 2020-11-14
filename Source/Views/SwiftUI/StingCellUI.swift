import SwiftUI

struct StingCellUI: View {
    @EnvironmentObject var controller: PlaybackController
    @ObservedObject var engine = Engine.shared
    @ObservedObject var sting: Sting
    
    var body: some View {
        let indicatorSymbol = sting.audioFile == nil ? "exclamationmark.octagon.fill" :
            sting == engine.playingSting ? "play.circle.fill" :
            sting == controller.cuedSting ? "smallcircle.fill.circle" : "circle"
        
        let indicatorColor = sting.audioFile == nil ? Color.white.opacity(0.8) :
            sting == engine.playingSting ? .white :
            sting == controller.cuedSting ? .white : Color("Background Color")
        
        HStack(spacing: 0) {
            Image(systemName: indicatorSymbol)
                .font(.system(size: 50, weight: .light))
                .padding()
                .frame(width: 90, height: 90)
                .foregroundColor(indicatorColor)
            Rectangle()
                .foregroundColor(Color("Background Color"))
                .overlay(
                    Text(sting.name ?? sting.songTitle)
                        .font(.title2)
                        .padding(.all, 8),
                    alignment: .leading)
                .overlay(
                    Text(sting.totalTime.formattedAsLength() ?? "")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .offset(x: -8, y: -6),
                    alignment: .bottomTrailing
                )
        }
        .frame(height: 90)
        .background(sting.color.value)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(sting.color.value, lineWidth: 4))
        .contextMenu {
            if sting.audioFile == nil {
                missingMenu
            } else {
                if sting != controller.cuedSting { playMenu }
                editMenu
                fileMenu
            }
        }
    }
    
    var playMenu: some View {
        Section {
            Button { controller.cuedSting = sting } label: {
                Label("Cue Next", systemImage: "smallcircle.fill.circle")
            }
        }
    }
    
    var editMenu: some View {
        Section {
            Button { /* self.performSegue(withIdentifier: "Edit Sting", sender: sting) */ } label: {
                Label("Edit", systemImage: "waveform")
            }
            Button { /* self.presentRenameDialog(for: sting) */ } label: {
                Label("Rename", systemImage: "square.and.pencil")
            }
            Picker(selection: $sting.color, label: Label("Color", systemImage: "paintbrush")) {
                ForEach(Sting.Color.allCases, id: \.self) { color in
                    Label {
                        Text("\(color)".capitalized)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .foregroundColor(color.value)
                            .font(Font.body.weight(.heavy))
                    }
//              self.change(sting, to: color)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    var fileMenu: some View {
        Section {
            Button { controller.duplicate(sting) } label : {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            Button { controller.insertSting(before: sting) } label: {
                Label("Insert Song Here", systemImage: "square.stack")
            }
            Button { controller.delete(sting) } label: {
                Label("Delete", systemImage: "trash")
                    .foregroundColor(.red)
            }
            .disabled(sting == controller.engine.playingSting)
        }
    }
    
    var missingMenu: some View {
        Group {
            Section {
                Button { controller.locate(sting) } label: {
                    Label("Locate", systemImage: "magnifyingglass")
                }
                Button { controller.insertSting(before: sting) } label: {
                    Label("Insert Song Here", systemImage: "square.stack")
                }
                Button { controller.delete(sting) } label: {
                    Label("Delete", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .disabled(sting == controller.engine.playingSting)
            }
            Section {
                Text("\(sting.songTitle) by \(sting.songArtist)").disabled(true)
            }
        }
    }
}

//struct StingCell_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack(spacing: 20) {
//            StingCellUI()
//            StingCellUI()
//            StingCellUI()
//        }
//        .padding(.all, 20)
//    }
//}

import SwiftUI

struct StingsGrid: View {
    let viewModel: PlaybackViewModel
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 20)], spacing: 20) {
            ForEach(viewModel.show.stings.enumerated(), id: \.element) { (index, sting) in
                StingCell(sting: sting, viewModel: viewModel)
                    .onTapGesture {
                        viewModel.engine.play(sting)
                    }
                    .contextMenu {
                        if sting.audioFile != nil, sting != viewModel.cuedSting {
                            Section { // Play section
                                Button { viewModel.cuedSting = sting } label: {
                                    Label("Cue Next", systemImage: "smallcircle.fill.circle")
                                }
                            }
                        }
                        
                        if sting.audioFile != nil {
                            Section { // Edit section
                                Button { viewModel.state.stingToEdit = sting } label: {
                                    Label("Edit", systemImage: "waveform")
                                }
                                
                                Button { viewModel.presentRenameDialog(for: sting) } label: {
                                    Label("Rename", systemImage: "square.and.pencil")
                                }
                                
                                Menu("Colour", systemImage: "paintbrush") {
                                    ForEach(Sting.Color.allCases, id: \.self) { color in
                                        Button {
                                            viewModel.change(sting, to: color)
                                        } label: {
                                            Label {
                                                Text("\(color)".capitalized)
                                            } icon: {
                                                Image(systemName: color == sting.color ? "checkmark.circle" : "circle")
                                                    .symbolVariant(.fill)
                                                    .fontWeight(.heavy)
                                                    .tint(color.value)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Section { // File section
                            if sting.audioFile != nil {
                                Button { viewModel.copy(sting, to: index + 1) } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                            } else {
                                Button {
                                    if sting.url.isMediaItem {
                                        viewModel.pickStingFromLibrary(pickerOperation: .locate(sting))
                                    } else {
                                        viewModel.pickStingFromFiles(pickerOperation: .locate(sting))
                                    }
                                } label: {
                                    Label("Locate", systemImage: "magnifyingglass")
                                }
                            }
                            Button { viewModel.pickStingFromLibrary(pickerOperation: .insert(index)) } label: {
                                Label("Insert Song Here", systemImage: "square.stack")
                            }
                            Button(role: .destructive) { viewModel.delete(sting, at: index) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .disabled(sting == viewModel.engine.playingSting)
                        }
                        
                        if sting.audioFile == nil {
                            Section { // Info section
                                Text("\(sting.songTitle) by \(sting.songArtist)")
                                    .disabled(true)
                            }
                        }
                    }
            }
//            .onMove { sourceIndexSet, destinationIndex in
//                guard let sourceIndex = sourceIndexSet.first as Int? else { return }
//                viewModel.show.moveSting(from: sourceIndex, to: destinationIndex)
//            }
        }
    }
}

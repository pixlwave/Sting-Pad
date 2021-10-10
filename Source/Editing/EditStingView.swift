import SwiftUI

struct EditStingView: View {
    @Environment(\.undoManager) var undoManager
    
    private let engine = Engine.shared
    
    let show: Show
    @ObservedObject var sting: Sting
    
    @State private var previewLength: TimeInterval = 2
    @State private var waveformHeight: CGFloat = 198
    
    let dismiss: (() -> Void)
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(sting.songTitle)
                        Text(sting.songArtist)
                            .font(.footnote)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    GeometryReader { geometry in
                        Waveform(show: show, sting: sting, previewLength: $previewLength)
                            .preference(key: SizeKey.self, value: geometry.size)
                    }
                    .onPreferenceChange(SizeKey.self) {
                        // the waveform's intrinsic size isn't passed up into SwiftUI for some reason
                        // use an aspect ratio of 56:16 for the waveform taking into account the overlaid views
                        waveformHeight = (($0.width - 40) / 56 * 16) + 123
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .frame(height: waveformHeight)
                }
                
                Section {
                    UndoProvider($sting.loops, undoManager: undoManager) { loops in
                        Toggle("Loop", isOn: loops)
                    }
                    
                    HStack {
                        Text("Preview Length")
                        Spacer()
                        Picker("Preview Length", selection: $previewLength) {
                            Text("Off").tag(0.0)
                            Text("1").tag(1.0)
                            Text("2").tag(2.0)
                            Text("5").tag(5.0)
                            Text("Full").tag(10.0)
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }
                }
                
                Section {
                    Button("Save as Preset", action: sting.setPreset)
                }
            }
            .navigationBarTitle(sting.name ?? sting.songTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if engine.playingSting != nil {
                previewLength = 0
            }
        }
    }
}

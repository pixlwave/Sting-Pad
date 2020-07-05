import SwiftUI

struct ChannelSelectionView: View {
    @State var outputConfig = Engine.shared.outputConfig
    
    var outputChannelCount = Engine.shared.outputChannelCount()
    var audioInterfaceName = Engine.shared.audioInterfaceName()
    
    var body: some View {
        List {
            if outputChannelCount == 1 {
                Section(header: Text(audioInterfaceName)) {
                    Button {
                        selectChannels(at: 0)
                    } label: {
                        OutputCell(label: "Mono output", selected: outputConfigIsDefault())
                    }
                }
            } else {
                Section(header: Text(audioInterfaceName)) {
                    ForEach(0..<outputChannelCount / 2) { index in
                        Button {
                            selectChannels(at: index)
                        } label: {
                            let cellChannels = channels(for: index)
                            let label = "Channels \(cellChannels.0 + 1) & \(cellChannels.1 + 1)"
                            let selected = outputConfig.left == cellChannels.0 && outputConfig.right == cellChannels.1
                            
                            OutputCell(label: label, selected: selected)
                        }
                    }
                }
            }
            
            if !outputConfigIsAvailable() {
                Section(header: Text("Unavailable")) {
                    HStack {
                        Text("Channels \(outputConfig.left + 1) & \(outputConfig.right + 1)")
                            .font(Font.body.monospacedDigit())
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                    .disabled(true)
                    .foregroundColor(SwiftUI.Color(.secondaryLabel))
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("Output Channels")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func outputConfigIsDefault() -> Bool {
        outputConfig.left == 0 && outputConfig.right == 1
    }
    
    func outputConfigIsAvailable() -> Bool {
        outputConfig.highestChannel < outputChannelCount
    }
    
    func channels(for index: Int) -> (Int, Int) {
        return ((2 * index), (2 * index) + 1)
    }
    
    func selectChannels(at index: Int) {
        let selectedChannels = channels(for: index)
        Engine.shared.outputConfig = outputConfig
        outputConfig.left = selectedChannels.0
        outputConfig.right = selectedChannels.1
        
    }
}

struct ChannelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ChannelSelectionView(outputConfig: OutputConfig(left: 0, right: 1), outputChannelCount: 1, audioInterfaceName: "Speakers")
            }
            NavigationView {
                ChannelSelectionView(outputConfig: OutputConfig(left: 0, right: 1), outputChannelCount: 2, audioInterfaceName: "Speakers")
            }
        }
        
    }
}

struct OutputCell: View {
    let label: String
    @State var selected: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(Font.body.monospacedDigit())
            if selected {
                Spacer()
                Image(systemName: "checkmark")
            }
        }
        .foregroundColor(SwiftUI.Color(.label))
    }
}

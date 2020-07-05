import SwiftUI

struct ChannelSelectionView: View {
    @State var outputConfig = Engine.shared.outputConfig
    
    var outputs = OutputConfig.array()
    var audioInterfaceName = Engine.shared.audioInterfaceName()
    
    var body: some View {
        List {
            Section(header: Text(audioInterfaceName)) {
                ForEach(outputs, id: \.self) { config in
                    Button {
                        Engine.shared.outputConfig = outputConfig
                        outputConfig = config
                    } label: {
                        let selected = outputConfig.left == config.left && outputConfig.right == config.right
                        OutputCell(label: config.name, selected: selected)
                    }
                }
            }
            
            if !outputs.contains(outputConfig) {
                Section(header: Text("Unavailable")) {
                    HStack {
                        Text(outputConfig.name)
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
}

struct OutputCell: View {
    let label: String
    @State var selected: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(Font.body.monospacedDigit())
                .foregroundColor(SwiftUI.Color(.label))
            if selected {
                Spacer()
                Image(systemName: "checkmark")
            }
        }
    }
}

struct ChannelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ChannelSelectionView(outputConfig: OutputConfig(left: 0, right: 1),
                                     outputs: [
                                        OutputConfig(left: 0, right: 1),
                                        OutputConfig(left: 2, right: 3),
                                        OutputConfig(left: 4, right: 5),
                                        OutputConfig(left: 6, right: 7)
                                     ],
                                     audioInterfaceName: "Sound Card")
            }
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone SE (1st generation)")
            NavigationView {
                ChannelSelectionView(outputConfig: OutputConfig(left: 2, right: 3),
                                     outputs: [
                                        OutputConfig(left: 0, right: 1)
                                     ],
                                     audioInterfaceName: "Speakers")
            }
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone SE (1st generation)")
        }
        
    }
}

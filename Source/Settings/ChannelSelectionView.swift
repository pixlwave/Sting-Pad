import SwiftUI

struct ChannelSelectionView: View {
    @State var outputConfig = Engine.shared.outputConfig
    
    var outputs = ChannelPair.array()
    var audioInterfaceName = Engine.shared.audioInterfaceName()
    
    var body: some View {
        Form {
            Section(header: Text(audioInterfaceName)) {
                ForEach(outputs, id: \.self) { config in
                    Button {
                        outputConfig = config
                        Engine.shared.outputConfig = outputConfig
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
                    .foregroundColor(.secondary)
                }
            }
        }
        .navigationBarTitle("Output Channels")
    }
}

struct OutputCell: View {
    let label: String
    let selected: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(Font.body.monospacedDigit())
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "checkmark")
                .font(Font.body.bold())
                .opacity(selected ? 1 : 0)
        }
    }
}

struct ChannelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ChannelSelectionView(outputConfig: ChannelPair(left: 0, right: 1),
                                     outputs: [
                                        ChannelPair(left: 0, right: 1),
                                        ChannelPair(left: 2, right: 3),
                                        ChannelPair(left: 4, right: 5),
                                        ChannelPair(left: 6, right: 7)
                                     ],
                                     audioInterfaceName: "Sound Card")
            }
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone SE (1st generation)")
            NavigationView {
                ChannelSelectionView(outputConfig: ChannelPair(left: 2, right: 3),
                                     outputs: [
                                        ChannelPair(left: 0, right: 1)
                                     ],
                                     audioInterfaceName: "Speakers")
            }
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone SE (1st generation)")
        }
        
    }
}

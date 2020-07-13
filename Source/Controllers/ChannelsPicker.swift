import SwiftUI

struct ChannelsPicker: View {
    @State var outputConfig = Engine.shared.outputConfig
    
    var outputs = ChannelPair.array()
    var audioInterfaceName = Engine.shared.audioInterfaceName()
    
    var body: some View {
        Picker("Output Channels", selection: $outputConfig) {
            ForEach(outputs, id: \.self) { config in
                Text(config.name).font(Font.body.monospacedDigit())
            }
            if !outputs.contains(outputConfig) {
                Text(outputConfig.name)
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(.secondary)
                    .disabled(true)
            }
        }
        .onChange(of: outputConfig) { pair in
//            Engine.shared.outputConfig = outputConfig
        }
    }
}

struct ChannelsPicker_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                Form {
                    ChannelsPicker(outputConfig: ChannelPair(left: 0, right: 1),
                                   outputs: [
                                        ChannelPair(left: 0, right: 1),
                                        ChannelPair(left: 2, right: 3),
                                        ChannelPair(left: 4, right: 5),
                                        ChannelPair(left: 6, right: 7)
                                   ],
                                   audioInterfaceName: "Speakers")
                }
            }
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone SE (1st generation)")
            NavigationView {
                Form {
                    ChannelsPicker(outputConfig: ChannelPair(left: 2, right: 3),
                                   outputs: [
                                        ChannelPair(left: 0, right: 1)
                                   ],
                                   audioInterfaceName: "Speakers")
                }
            }
            .previewLayout(.sizeThatFits)
            .previewDevice("iPhone SE (1st generation)")
        }
    }
}

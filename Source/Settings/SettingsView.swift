import SwiftUI

struct SettingsView: View {
    @State private var defaultColor: Sting.Color = .default
    
    var show: Show?
    
    let dismiss: (() -> Void)
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("I/O")) {
                    NavigationLink("Output Channels", destination: ChannelSelectionView())
                }
                Section(header: Text("Defaults")) {
                    Picker("Default Color", selection: $defaultColor) {
                        ForEach(Sting.Color.allCases, id: \.self) { color in
                            Label {
                                Text(color.rawValue.capitalized)
                            } icon: {
                                Image(systemName: "circle.fill").foregroundColor(color.value)
                            }
                        }
                    }
                    .onChange(of: defaultColor) { color in
                        Sting.Color.default = defaultColor
                    }
                }
                Section(header: Text("Presets")) {
                    Button("Save Show Stings as Presets") {
                        setAllStingPresets()
                    }
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    func setAllStingPresets() {
        show?.stings.forEach { $0.setPreset() }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(dismiss: { })
    }
}

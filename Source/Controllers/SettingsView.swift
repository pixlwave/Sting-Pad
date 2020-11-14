import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var defaultColor: Sting.Color = .default
    
    var show: Show
    
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
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func setAllStingPresets() {
        show.stings.forEach { $0.setPreset() }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(show: Show())
    }
}

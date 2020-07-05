import SwiftUI

struct SettingsView: View {
    @State private var defaultColor = Color.default
    @State private var channelPair = 0
    
    var show: Show?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("I/O")) {
                    ChannelsPicker()
                }
                Section(header: Text("Defaults")) {
                    Picker("Default Color", selection: $defaultColor) {
                        ForEach(StingPad.Color.allCases, id:\.self) { color in
                            HStack {
                                Image(systemName: "circle.fill").foregroundColor(SwiftUI.Color(color.value))
                                Text(color.rawValue.capitalized)
                            }
                        }
                    }
                    .onChange(of: defaultColor) { color in
                        Color.default = defaultColor
                    }
                }
                Section(header: Text("Presets")) {
                    Button("Save Show Stings as Presets") {
                        setAllStingPresets()
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                done()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    
    func done() {
        //dismiss(animated: true)
    }
    
    func setAllStingPresets() {
        show?.stings.forEach { $0.setPreset() }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

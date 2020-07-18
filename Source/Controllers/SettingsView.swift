import SwiftUI

struct SettingsView: View {
    @State private var defaultColor = Color.default
    
    var show: Show?
    
    var dismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("I/O")) {
                    NavigationLink("Output Channels", destination: ChannelSelectionView())
                }
                Section(header: Text("Defaults")) {
                    Picker("Default Color", selection: $defaultColor) {
                        ForEach(StingPad.Color.allCases, id: \.self) { color in
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
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { dismiss?() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
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

class SettingsViewController: UIHostingController<SettingsView> {
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder, rootView: SettingsView())
        rootView.dismiss = dismiss
    }
    
    override init?(coder decoder: NSCoder, rootView: SettingsView) {
        super.init(coder: decoder, rootView: rootView)
        self.rootView.dismiss = dismiss
    }

    func dismiss() {
        dismiss(animated: true)
    }
}

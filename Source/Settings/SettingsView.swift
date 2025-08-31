import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var defaultColor: Sting.Color = .default
    
    var show: Show?
    
    var body: some View {
        NavigationStack {
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
                    .pickerStyle(.navigationLink)
                    .onChange(of: defaultColor) { _, newColor in
                        Sting.Color.default = newColor
                    }
                }
                Section(header: Text("Presets")) {
                    Button("Save Show Stings as Presets") {
                        setAllStingPresets()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
    
    func setAllStingPresets() {
        show?.stings.forEach { $0.setPreset() }
    }
}

// MARK: - Previews

#Preview {
    SettingsView()
}

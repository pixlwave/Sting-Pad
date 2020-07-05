import SwiftUI

struct SettingsView: View {
    
    var show: Show?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("I/O")) {
                    NavigationLink(destination: ChannelSelectionView()) {
                        Text("Output Channels")
                    }
                }
                Section(header: Text("Defaults")) {
                    NavigationLink(destination: DefaultColorView()) {
                        Text("Default Color")
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

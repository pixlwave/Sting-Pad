import SwiftUI

struct PlaybackView: View {
    @State var isPresentingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 15) {
                    StingCellUI(color: Sting.Color.teal.value)
                    StingCellUI(color: Sting.Color.orange.value)
                    StingCellUI(color: Sting.Color.green.value)
                    StingCellUI(color: Sting.Color.blue.value)
                }
                .padding()
                
                HStack(spacing: 20) {
                    FooterCell(label: "Music Library")
                    FooterCell(label: "Files")
                }
                .padding()
            }
            .overlay(
                TransportViewUI(),
                alignment: .bottom
            )
            .navigationBarTitle("Show 2", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Shows") {
                        //
                    }
                }
                ToolbarItem {
                    Button {
                        isPresentingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $isPresentingSettings) {
                SettingsView()
            }
        }
    }
}

struct PlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        PlaybackView()
    }
}

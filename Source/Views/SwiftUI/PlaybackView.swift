import SwiftUI

struct PlaybackView: View {
    @EnvironmentObject var show: Show
    @ObservedObject var engine = Engine.shared
    
    @State var isPresentingSettings = false
    
    var dismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 15) {
                    ForEach(show.stings) { sting in
                        StingCellUI(sting: sting)
                    }
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
            .navigationBarTitle(show.fileName, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Shows") {
                        engine.stopSting()
                        
                        show.close { success in
                            dismiss?()
                        }
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

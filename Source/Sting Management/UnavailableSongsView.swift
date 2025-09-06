import SwiftUI

struct UnavailableSongsView: View {
    let show: Show
    @Binding var stings: [Sting]
    
    var body: some View {
        List(stings, id: \.self) { sting in
            UnavailableStingCell(sting: sting, show: show)
        }
        .safeAreaBar(edge: .top) {
            VStack {
                Text("Sting Pad is unable to locate the following songs on your device. Ensure that they are downloaded in the Music app and reload the show.")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.bottom, 1)
                Button("Reload Stings", action: show.reloadUnavailableStings)
                    .font(.body.bold())
            }
        }
        .navigationTitle("Missing Strings")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
    }
}

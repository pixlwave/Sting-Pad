import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    
    static let currentVersion = 3.0
    
    var body: some View {
        ScrollView {
            content
                .padding(20)
        }
        .safeAreaBar(edge: .bottom) {
            Button(action: dismiss.callAsFunction) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: 300)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding()
        }
    }
    
    var content: some View {
        VStack {
            Text("Getting Started")
                .font(.largeTitle.bold())
                .padding()
                .padding(.bottom)
            
            VStack(alignment: .leading, spacing: 20) {
                WelcomeItem(symbolName: "plus.circle",
                            symbolColor: .systemPurple,
                            text: "Tap + to start a new show.")
                WelcomeItem(symbolName: "folder.circle",
                            symbolColor: .systemBlue,
                            text: "Add stings from your device.")
                WelcomeItem(symbolName: "waveform.circle",
                            symbolColor: .systemYellow,
                            text: "Long tap on a sting to modify it.")
                WelcomeItem(symbolName: "arrow.up.arrow.down.circle",
                            symbolColor: .systemGreen,
                            text: "Long tap and drag to move a sting.")
            }
        }
    }
}

struct WelcomeItem: View {
    let symbolName: String
    let symbolColor: UIColor
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: symbolName)
                .font(.largeTitle.scaled(by: 1.1))
                .foregroundColor(Color(symbolColor))
                .symbolVariant(.fill)
                .padding(.trailing, 10)
            Text(text)
        }
    }
}

// MARK: - Previews

#Preview {
    WelcomeView()
}

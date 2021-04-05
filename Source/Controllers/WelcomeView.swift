import SwiftUI

struct WelcomeView: View {
    static let currentVersion = 3.0
    
    let dismiss: (() -> Void)
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Getting Started")
                .font(.title)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 25) {
                WelcomeItem(symbolName: "plus.circle.fill",
                            symbolColor: .systemPurple,
                            text: "Tap + to start a new show.")
                WelcomeItem(symbolName: "folder.circle.fill",
                            symbolColor: .systemBlue,
                            text: "Add stings from your device.")
                WelcomeItem(symbolName: "waveform.circle.fill",
                            symbolColor: .systemYellow,
                            text: "Long tap on a sting to modify it.")
                WelcomeItem(symbolName: "arrow.up.arrow.down.circle.fill",
                            symbolColor: .systemGreen,
                            text: "Long tap and drag to move a sting.")
            }
            .padding(20)
            
            Spacer()
            
            Button(action: dismiss) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 40)
                    .background(Color("Tint Color"))
                    .cornerRadius(7)
            }
            
            Spacer()
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
                .font(.system(size: 36))
                .foregroundColor(Color(symbolColor))
                .padding(.trailing, 10)
            Text(text)
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(dismiss: { })
    }
}

import SwiftUI
import VisualEffects

struct TransportViewUI: View {
    @EnvironmentObject var controller: PlaybackController
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                controller.playSting()
            } label: {
                Image(systemName: "play")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.large)
            }
            Spacer()
            Button {
                controller.stopSting()
            } label: {
                Image(systemName: "stop")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.medium)
            }
            Spacer()
            Button {
                controller.previousCue()
            } label: {
                Image(systemName: "backward")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.small)
            }
            Spacer()
            Button {
                controller.nextCue()
            } label: {
                Image(systemName: "forward")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.small)
            }
            Spacer()
        }
        .padding(.vertical)
        .overlay(
            Text("0:00 remaining")
                .font(Font.footnote.monospacedDigit())
                .foregroundColor(Color(red: 111 / 255, green: 113 / 255, blue: 121/255))
                .padding(4),
            alignment: .bottomTrailing
        )
        .overlay(
            ProgressView(value: 0.5),
            alignment: .top
        )
        .background(VisualEffectBlur(blurStyle: .prominent))
    }
}

struct TransportView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            TransportViewUI()
        }
    }
}

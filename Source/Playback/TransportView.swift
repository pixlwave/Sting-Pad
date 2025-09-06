import SwiftUI

struct TransportView: View {
    let viewModel: PlaybackViewModel
    
    var body: some View {
        controls
            .padding(.vertical)
            .overlay(alignment: .top) {
                progressIndicator
            }
            .overlay(alignment: .bottomTrailing) {
                remainingText
            }
            .background(.regularMaterial)
    }
    
    var controls: some View {
        HStack {
            Spacer()
            Button {
                viewModel.playSting()
            } label: {
                Image(systemName: "play")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.large)
            }
            Spacer()
            Button {
                viewModel.stopSting()
            } label: {
                Image(systemName: "stop")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.medium)
            }
            Spacer()
            Button {
                viewModel.previousCue()
            } label: {
                Image(systemName: "backward")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.small)
            }
            Spacer()
            Button {
                viewModel.nextCue()
            } label: {
                Image(systemName: "forward")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.small)
            }
            Spacer()
        }
    }
    
    var progressIndicator: some View {
        ProgressView(value: viewModel.progress.value)
    }
    
    var remainingText: some View {
        Text(viewModel.progress.remaining)
            .font(Font.footnote.monospacedDigit())
            .foregroundColor(Color(red: 111 / 255, green: 113 / 255, blue: 121/255))
            .padding(8)
    }
}

#Preview {
    let viewModel = PlaybackViewModel(show: Show(name: "Preview"), progress: .init(elapsed: 90, total: 225))
    
    VStack {
        Spacer()
        TransportView(viewModel: viewModel)
    }
}

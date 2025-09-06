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
        PlaybackProgressView(value: viewModel.progress.value)
    }
    
    var remainingText: some View {
        Text(viewModel.progress.remaining)
            .font(Font.footnote.monospacedDigit())
            .foregroundColor(Color(red: 111 / 255, green: 113 / 255, blue: 121/255))
            .padding(8)
    }
}

/// A custom progress bar, as `ProgressView` doesn't honour the `.animation` modifier.
struct PlaybackProgressView: View {
    let value: Double
    
    @State var renderedValue: Double = 0
    @State var isAnimated = false
    
    @State private var width: CGFloat = .zero
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.secondary.opacity(0.7))
            
            Capsule()
                .fill(Color.tint)
                .frame(width: width * renderedValue)
                .animation(isAnimated ? .linear(duration: 1) : nil, value: renderedValue)
        }
        .frame(height: 4)
        .onChange(of: value, updateRenderedValue)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
    
    /// Updates the rendered value, making sure to not animate when playback stops or loops.
    func updateRenderedValue(oldValue: Double, newValue: Double) {
        if newValue < oldValue {
            isAnimated = false
            renderedValue = 0
            DispatchQueue.main.async {
                isAnimated = true
                renderedValue = newValue
            }
        } else {
            isAnimated = true
            renderedValue = newValue
        }
    }
}

#Preview {
    let viewModel = PlaybackViewModel(show: Show(name: "Preview"), progress: .init(elapsed: 90, total: 225))
    
    VStack {
        Spacer()
        TransportView(viewModel: viewModel)
    }
}

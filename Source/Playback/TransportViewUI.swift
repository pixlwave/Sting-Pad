import SwiftUI

@Observable class TransportModel {
    var elapsed: TimeInterval
    var total: TimeInterval
    
    init(elapsed: TimeInterval, total: TimeInterval) {
        self.elapsed = elapsed
        self.total = total
    }
    
    var progress: Double {
        guard total > 0 else { return 0 }
        let progress = (elapsed / total).truncatingRemainder(dividingBy: 1) // + (1 / total)
        return max(0, min(1, progress))
        
        // Make sure not to animate the loop point 🤔
        // if progressView.progress == 1 {
        //    progressView.reset()
        // }
        // UIView.animate { progressView.progress = newValue }
    }
    
    var remaining: String {
        let timeRemaining = total - elapsed
        if timeRemaining < 0 {
            return "Looping"
        } else if let remainingString = timeRemaining.formattedAsRemaining() {
            return remainingString
        } else {
            return "0:00 remaining"
        }
    }
}

struct TransportViewUI: View {
    let model: TransportModel
    
    enum Action { case play, stop, previous, next }
    let action: (Action) -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                action(.play)
            } label: {
                Image(systemName: "play")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.large)
            }
            Spacer()
            Button {
                action(.stop)
            } label: {
                Image(systemName: "stop")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.medium)
            }
            Spacer()
            Button {
                action(.previous)
            } label: {
                Image(systemName: "backward")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.small)
            }
            Spacer()
            Button {
                action(.next)
            } label: {
                Image(systemName: "forward")
                    .font(.system(size: 52, weight: .thin))
                    .imageScale(.small)
            }
            Spacer()
        }
        .padding(.vertical)
        .overlay(alignment: .bottomTrailing) {
            Text(model.remaining)
                .font(Font.footnote.monospacedDigit())
                .foregroundColor(Color(red: 111 / 255, green: 113 / 255, blue: 121/255))
                .padding(8)
        }
        .overlay(alignment: .top) {
            ProgressView(value: model.progress)
        }
        .background(.regularMaterial)
    }
}

#Preview {
    VStack {
        Spacer()
        TransportViewUI(model: .init(elapsed: 90, total: 225)) { _ in }
    }
}

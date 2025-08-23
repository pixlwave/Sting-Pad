import SwiftUI

struct StingCell: View {
    let sting: Sting
    
    let state: State
    enum State { case idle, cued, playing, missing }
    
    init(sting: Sting, isCued: Bool, isPlaying: Bool) {
        self.sting = sting
        
        self.state = if sting.audioFile == nil {
            .missing
        } else if isPlaying {
            .playing
        } else if isCued {
            .cued
        } else {
            .idle
        }
    }
    
    let shape = RoundedRectangle(cornerRadius: 8)
    
    var indicatorImageName: String {
        switch state {
        case .idle: "circle"
        case .cued: "smallcircle.fill.circle"
        case .playing: "play.circle.fill"
        case .missing: "exclamationmark.octagon.fill"
        }
    }
    
    var indicatorColor: Color {
        switch state {
        case .idle: .background
        case .cued: .white
        case .playing: .white
        case .missing: .white.opacity(0.8)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            indictor
            details
        }
        .frame(height: 90) // TODO: Let's go dynamic!
        .background(sting.color.value, in: shape)
        .overlay { shape.inset(by: 2).stroke(sting.color.value, lineWidth: 4) }
    }
    
    var indictor: some View {
        Image(systemName: indicatorImageName)
            .font(.system(size: 50).weight(.light))
            .foregroundStyle(indicatorColor)
            .frame(width: 90)
    }
    
    var details: some View {
        ZStack {
            Color.background
            
            Text(sting.name ?? sting.songTitle)
                .font(.title2)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .padding(.leading, 4)
        }
        .overlay(alignment: .bottomTrailing) {
            statusText
                .font(.footnote)
                .foregroundStyle(.secondary)
                .offset(x: -7, y: -6)
                .dynamicTypeSize(.large) // FIXME: Let's go dynamic!
        }
    }
    
    var statusText: Text {
        if state == .missing {
            Text(sting.availability.rawValue)
        } else if sting.loops {
            Text(Image(systemName: "repeat"))
        } else {
            Text(sting.totalTime.formattedAsLength() ?? "")
        }
    }
}

//#Preview {
//    StingCell(sting: Sting, isCued: false, isPlaying: false)
//}

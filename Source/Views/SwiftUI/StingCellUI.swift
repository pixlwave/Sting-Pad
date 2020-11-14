import SwiftUI

struct StingCellUI: View {
    @EnvironmentObject var controller: PlaybackController
    @ObservedObject var engine = Engine.shared
    @ObservedObject var sting: Sting
    
    var body: some View {
        let indicatorSymbol = sting.audioFile == nil ? "exclamationmark.octagon.fill" :
            sting == engine.playingSting ? "play.circle.fill" :
            sting == controller.cuedSting ? "smallcircle.fill.circle" : "circle"
        
        let indicatorColor = sting.audioFile == nil ? Color.white.opacity(0.8) :
            sting == engine.playingSting ? .white :
            sting == controller.cuedSting ? .white : Color("Background Color")
        
        HStack(spacing: 0) {
            Image(systemName: indicatorSymbol)
                .font(.system(size: 50, weight: .light))
                .padding()
                .frame(width: 90, height: 90)
                .foregroundColor(indicatorColor)
            Rectangle()
                .foregroundColor(Color("Background Color"))
                .overlay(
                    Text(sting.name ?? sting.songTitle)
                        .font(.title2)
                        .padding(.all, 8),
                    alignment: .leading)
                .overlay(
                    Text(sting.totalTime.formattedAsLength() ?? "")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .offset(x: -8, y: -6),
                    alignment: .bottomTrailing
                )
        }
        .frame(height: 90)
        .background(sting.color.value)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(sting.color.value, lineWidth: 4))
    }
}

//struct StingCell_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack(spacing: 20) {
//            StingCellUI()
//            StingCellUI()
//            StingCellUI()
//        }
//        .padding(.all, 20)
//    }
//}

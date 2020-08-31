import SwiftUI

struct StingCellUI: View {
    @ObservedObject var sting: Sting
    
    let foregroundColor = Color.white.opacity(0.5)
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "circle")
                .font(.system(size: 50, weight: .light))
                .padding()
                .frame(width: 90, height: 90)
                .foregroundColor(foregroundColor)
            Rectangle()
                .foregroundColor(foregroundColor)
                .overlay(
                    Text(sting.name ?? sting.songTitle)
                        .font(.title2)
                        .padding(.all, 8),
                    alignment: .leading)
                .overlay(
                    Text("0:00")
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

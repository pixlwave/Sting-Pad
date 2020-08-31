import SwiftUI

struct FooterCell: View {
    let label: String
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Image(systemName: "plus")
                    .font(.title)
                    .imageScale(.large)
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 4, dash: [10])))
    }
}

struct FooterCell_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            FooterCell(label: "Music Library")
            FooterCell(label: "Files")
        }
        .padding()
    }
}

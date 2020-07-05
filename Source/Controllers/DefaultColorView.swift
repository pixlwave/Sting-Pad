import SwiftUI

struct DefaultColorView: View {
    @State private var defaultColor = Color.default
    
    var body: some View {
        List {
            ForEach(Color.allCases, id: \.self) { color in
                Button {
                    StingPad.Color.default = color
                    defaultColor = color
                } label: {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(SwiftUI.Color(color.value))
                        Text(color.rawValue.capitalized)
                            .foregroundColor(SwiftUI.Color(.label))
                        Spacer()
                        if color == self.defaultColor {
                            Image(systemName: "checkmark")
                                .foregroundColor(SwiftUI.Color(.label))
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("Default Color")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DefaultColorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DefaultColorView()
        }
    }
}

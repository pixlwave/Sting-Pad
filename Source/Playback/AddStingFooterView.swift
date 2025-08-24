import SwiftUI

struct AddStingFooterView: View {
    let viewModel: PlaybackViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button {
                viewModel.pickStingFromLibrary(pickerOperation: .normal)
            } label: {
                Label("Music Library", systemImage: "plus")
            }
            .buttonStyle(FooterButtonStyle())
            
            Button {
                viewModel.pickStingFromFiles(pickerOperation: .normal)
            } label: {
                Label("Files", systemImage: "plus")
            }
            .buttonStyle(FooterButtonStyle())
        }
    }
}

private struct FooterButtonStyle: ButtonStyle {
    let shape = RoundedRectangle(cornerRadius: 8)
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(LabelStyle())
            .padding(18)
            .frame(maxWidth: .infinity)
            .background {
                shape
                    .inset(by: 2)
                    .stroke(.secondary, style: .init(lineWidth: 4, dash: [8]))
            }
            .contentShape(shape)
    }
    
    struct LabelStyle: SwiftUI.LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            VStack {
                configuration.icon
                    .font(.title)
                    .imageScale(.large)
                configuration.title
                    .font(.footnote)
            }
            .foregroundStyle(.secondary)
        }
    }
}

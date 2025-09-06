import SwiftUI

struct StingsGrid: View {
    @Bindable var viewModel: PlaybackViewModel
    
    @State private var dragOperation: DragOperation?
    @Namespace private var sheets
    
    private var stings: [Sting] {
        viewModel.show.stings.previewing(dragOperation)
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 20)], spacing: 20) {
            ForEach(stings.enumerated(), id: \.element) { (index, sting) in
                StingCell(sting: sting, viewModel: viewModel)
                    // performDrop doesn't trigger when the destination is completely transparent…
                    .opacity(sting == dragOperation?.sting && dragOperation?.destinationIndex != nil ? 0.001 : 1)
                    .matchedTransitionSource(id: SheetID.edit(sting.id), in: sheets)
                    .onTapGesture { viewModel.engine.play(sting) }
                    .contextMenu { StingContextMenu(sting: sting, index: index, viewModel: viewModel) }
                    .onDrag {
                        dragOperation = DragOperation(sting: sting, sourceIndex: index)
                        return NSItemProvider(object: "\(sting.hashValue)" as NSString)
                    }
                    .onDrop(of: [.text], delegate: DragHandler(operation: $dragOperation,
                                                                    destinationIndex: index,
                                                                    viewModel: viewModel))
            }
        }
        .sheet(item: $viewModel.state.stingToEdit) {
            EditStingView(show: viewModel.show, sting: $0)
                .navigationTransition(.zoom(sourceID: SheetID.edit($0.id), in: sheets))
        }
    }
}

// MARK: Drag & Drop

struct DragOperation {
    let sting: Sting
    let sourceIndex: Int
    var destinationIndex: Int?
}

struct DragHandler: DropDelegate {
    let operation: Binding<DragOperation?>
    let destinationIndex: Int
    let viewModel: PlaybackViewModel
    
    func dropEntered(info: DropInfo) {
        withAnimation { operation.wrappedValue?.destinationIndex = destinationIndex }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let activeOperation = operation.wrappedValue,
              let destinationIndex = activeOperation.destinationIndex
        else { return false }
        
        viewModel.show.moveSting(from: activeOperation.sourceIndex, to: destinationIndex)
        operation.wrappedValue = nil
        
        return true
    }
}

private extension Array {
    func previewing(_ dragOperation: DragOperation?) -> Self {
        guard let sourceIndex = dragOperation?.sourceIndex,
              let destinationindex = dragOperation?.destinationIndex
        else { return self }
        
        var result = self
        let offset = destinationindex > sourceIndex ? 1 : 0
        result.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: destinationindex + offset)
        return result
    }
}

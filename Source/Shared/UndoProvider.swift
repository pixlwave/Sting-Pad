// Based on https://lostmoa.com/blog/HandlingUndoAndRedoInSwiftUI/

import SwiftUI

struct UndoProvider<WrappedView, Value>: View where WrappedView: View {
    @StateObject var handler: UndoHandler<Value> = UndoHandler()
    
    let binding: Binding<Value>
    let undoManger: UndoManager?
    let wrappedView: (Binding<Value>) -> WrappedView
    
    init(_ binding: Binding<Value>, undoManager: UndoManager?, @ViewBuilder wrappedView: @escaping (Binding<Value>) -> WrappedView) {
        self.binding = binding
        self.undoManger = undoManager
        self.wrappedView = wrappedView
    }
    
    var interceptedBinding: Binding<Value> {
        Binding {
            binding.wrappedValue
        } set: { newValue in
            handler.updateValue(from: binding.wrappedValue, to: newValue)
            binding.wrappedValue = newValue
        }
    }
    
    var body: some View {
        wrappedView(interceptedBinding)
            .onAppear {
                handler.binding = binding
                handler.undoManager = undoManger
            }
    }
}

class UndoHandler<Value>: ObservableObject {
    var binding: Binding<Value>?
    weak var undoManager: UndoManager?
    
    func updateValue(from oldValue: Value, to newValue: Value) {
        undoManager?.registerUndo(withTarget: self) {
            $0.updateValue(from: newValue, to: oldValue)
            $0.binding?.wrappedValue = oldValue
        }
    }
    
    init() { }
}

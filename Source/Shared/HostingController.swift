import UIKit
import SwiftUI

/// A subclass of `UIHostingController` that will become first responder
/// in `viewDidAppear`, in order to capture any undo/redo gestures.
///
/// The controller clears all actions in the show's undo manager on appear / disappear.
class HostingController<T: View>: UIHostingController<T> {
    let show: Show
    
    override var canBecomeFirstResponder: Bool { true }  // allow undo gestures to work
    override var undoManager: UndoManager? { show.undoManager }
    
    init?(coder decoder: NSCoder, rootView: T, show: Show) {
        self.show = show
        super.init(coder: decoder, rootView: rootView)
    }
    
    required init?(coder decoder: NSCoder) { fatalError("Not supported.") }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        undoManager?.removeAllActions()
        
        becomeFirstResponder()  // respond to undo gestures
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        undoManager?.removeAllActions()
        
        resignFirstResponder()  // finished with undo gestures
    }
}

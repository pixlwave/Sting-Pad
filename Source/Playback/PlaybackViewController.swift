import SwiftUI
import os.log

class PlaybackViewController: UIViewController {
    var viewModel: PlaybackViewModel!
    var hostingController: UIHostingController<PlaybackView>!
    
    // respond to undo gestures, forwarding them to the show's undo manager
    override var canBecomeFirstResponder: Bool { true }
    override var undoManager: UndoManager? { viewModel.show.undoManager }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hostingController = UIHostingController(rootView: PlaybackView(viewModel: viewModel) { [weak self] in
            self?.closeShow()
        })
        hostingController.view.backgroundColor = .clear
        addChild(hostingController)
        hostingController.didMove(toParent: self)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishEditing), name: .didFinishEditing, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()  // respond to undo gestures
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    func closeShow() {
        // stop listening for notifications in case a new show is opened before this gets deallocated
        NotificationCenter.default.removeObserver(self)
        
        Task {
            await viewModel.closeShow()
            (presentingViewController as? ShowBrowserViewController)?.isLoading = false
            dismiss(animated: true)
        }
    }
    
    @objc func didFinishEditing() {
        becomeFirstResponder()  // ensure undo works again
    }
}

import UIKit

class ShowBrowserViewController: UIDocumentBrowserViewController {
    
    var transitionController: UIDocumentBrowserTransitionController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if targetEnvironment(simulator)
        presentCurrentShow(animated: false)
        #endif
    }
    
    func presentCurrentShow(animated: Bool = true) {
        guard
            let storyboard = storyboard,
            let rootVC = storyboard.instantiateViewController(withIdentifier: "Root View Controller") as? UINavigationController,
            let playbackVC = rootVC.topViewController as? PlaybackViewController
        else { return }
        
        rootVC.transitioningDelegate = self
        transitionController = transitionController(forDocumentAt: Show.shared.fileURL)
        transitionController?.targetView = playbackVC.view
        
        present(rootVC, animated: animated)
    }
}


// MARK: UIDocumentBrowserViewControllerDelegate
extension ShowBrowserViewController: UIDocumentBrowserViewControllerDelegate {
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        guard
            let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        else {
            importHandler(nil, .none)
            return
        }
        
        let show = Show(fileURL: cacheURL.appendingPathComponent("Show.stkshow"))
        importHandler(show.fileURL, .move)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let url = documentURLs.first, url.isFileURL else { return }
            
        Show.shared = Show(fileURL: url)
        self.presentCurrentShow()
    }
}


//
extension ShowBrowserViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
}

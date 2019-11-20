import UIKit

class ShowBrowserViewController: UIDocumentBrowserViewController {
    
    var hasRestored = false
    var isLoading = false
    
    var transitionController: UIDocumentBrowserTransitionController?
    var presentedPlaybackViewController: PlaybackViewController? {
        presentedViewController?.children.first as? PlaybackViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if targetEnvironment(simulator)
        if !hasRestored {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                let show = Show(name: Show.defaultName)
                if !show.fileExists {
                    show.save(to: show.fileURL, for: .forCreating) { sucess in
                        self.openShow(at: show.fileURL, animated: false)
                    }
                } else {
                    self.openShow(at: show.fileURL, animated: false)
                }
            }
        }
        #endif
        
        if UserDefaults.standard.double(forKey: "WelcomeVersionSeen") < WelcomeViewController.currentVersion, children.count == 0 {
            showWelcomeScreen()
        }
    }
    
    func showWelcomeScreen() {
        // present the whole screen
        performSegue(withIdentifier: "WelcomeSegue", sender: nil)
        
        // record the version being seen to allow ui updates to be shown in future versions
        UserDefaults.standard.set(WelcomeViewController.currentVersion, forKey: "WelcomeVersionSeen")
    }
    
    func openShow(at url: URL, animated: Bool = true) {
        guard !isLoading else { return }    // prevent double tap opening a show twice
        
        isLoading = true
        let show = Show(fileURL: url)
        
        show.open { success in
            guard success else {
                self.displayOpenError(for: show)
                self.isLoading = false
                return
            }
            
            self.present(show, animated: animated)
        }
    }
    
    func present(_ show: Show, animated: Bool) {
        guard
            let storyboard = storyboard,
            let rootVC = storyboard.instantiateViewController(withIdentifier: "Root View Controller") as? UINavigationController,
            let playbackVC = rootVC.topViewController as? PlaybackViewController
        else {
            isLoading = false
            return
        }
        
        playbackVC.show = show
        
        rootVC.transitioningDelegate = self
        transitionController = transitionController(forDocumentAt: show.fileURL)
        transitionController?.targetView = playbackVC.view
        
        present(rootVC, animated: animated)
        
        playbackVC.applySnapshot()
        playbackVC.navigationItem.title = show.fileName
        playbackVC.stopUpdatingProgress()   // update time remaining label
    }
    
    func displayOpenError(for show: Show) {
        DispatchQueue.main.async {
            let showName = show.fileURL.deletingPathExtension().lastPathComponent
            let alertController = UIAlertController(title: "Error", message: "Unable to open \(showName)", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alertController, animated: true)
        }
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        if presentedViewController != nil {
            if let showURL = presentedPlaybackViewController?.show?.fileURL {
                let didStartAccessing = showURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing { showURL.stopAccessingSecurityScopedResource() }
                }
                
                if let bookmarkData = try? showURL.bookmarkData() {
                    coder.encode(bookmarkData, forKey: "showBookmarkData")
                }
            }
        }
        
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        if let bookmarkData = coder.decodeObject(forKey: "showBookmarkData") as? Data {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale), url.isFileURL {
                hasRestored = true
                openShow(at: url, animated: false)
            }
        }
        
        super.decodeRestorableState(with: coder)
    }
}


// MARK: UIDocumentBrowserViewControllerDelegate
extension ShowBrowserViewController: UIDocumentBrowserViewControllerDelegate {
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        let showNameAlert = UIAlertController(title: "Show Name", message: nil, preferredStyle: .alert)
        
        showNameAlert.addTextField { textField in
            textField.placeholder = Show.defaultName
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .always
        }
        showNameAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            importHandler(nil, .none)
        }))
        showNameAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
            let show = Show(name: showNameAlert.textFields?.first?.text)
            
            // dismiss alert controller in order to present playback view controller
            self.dismiss(animated: true)
            
            if show.fileExists {
                importHandler(show.fileURL, .move)
            } else {
                show.save(to: show.fileURL, for: .forCreating) { success in
                    guard success else { importHandler(nil, .none); return }
                    importHandler(show.fileURL, .move)
                }
            }
        }))
        
        present(showNameAlert, animated: true)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let url = documentURLs.first, url.isFileURL else { return }
        openShow(at: url)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        guard destinationURL.isFileURL else { return }
        openShow(at: destinationURL)
    }
}


// MARK: UIViewControllerTransitioningDelegate
extension ShowBrowserViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }
}

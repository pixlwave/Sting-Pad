import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var showBrowser: ShowBrowserViewController? {
        window?.rootViewController as? ShowBrowserViewController
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        #if targetEnvironment(macCatalyst)
        window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 320, height: 568)
        #endif
        
        if let fileURL = connectionOptions.urlContexts.first?.url {
            openShow(at: fileURL)
        } else if let restorationActivity = session.stateRestorationActivity {
            restoreState(from: restorationActivity)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        guard let fileURL = urlContexts.first?.url else { return }
        openShow(at: fileURL)
    }
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        guard let showURL = showBrowser?.presentedPlaybackViewController?.viewModel?.show.fileURL else { return nil }
        
        let didStartAccessing = showURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { showURL.stopAccessingSecurityScopedResource() }
        }
        
        guard let bookmarkData = try? showURL.bookmarkData() else { return nil }
        
        let activity = NSUserActivity(activityType: "uk.pixlwave.StingPad.StateRestoration")
        activity.addUserInfoEntries(from: ["showBookmarkData": bookmarkData])
        return activity
    }
    
    private func restoreState(from restorationActivity: NSUserActivity) {
        guard let bookmarkData = restorationActivity.userInfo?["showBookmarkData"] as? Data else { return }
        
        var isStale = false
        if let url = try? URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale), url.isFileURL {
            openShow(at: url)
        }
    }
    
    #warning("Needs testing on device")
    private func openShow(at url: URL) {
        guard url.isFileURL, let showBrowser else { return }
        
        if showBrowser.presentedPlaybackViewController != nil {
            showBrowser.dismiss(animated: true)
            #warning("Should really await closeShow or for !isLoading")
        }
        
        if url.isFileInsideInbox {
            showBrowser.revealDocument(at: url, importIfNeeded: true) { importedURL, error in
                guard let importedURL = importedURL else { return }
                showBrowser.openShow(at: importedURL, animated: false)
            }
        } else {
            showBrowser.openShow(at: url, animated: false)
        }
    }
}

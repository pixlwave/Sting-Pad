import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // prevent device from going to sleep
        application.isIdleTimerDisabled = true
        
        // applies the included tint colour to UIAlertController (and presumably others)
        window?.tintColor = .tintColor
        
        // migrate sting defaults to presets for testflight users
        #warning("Delete old preferences once all devices have migrated")
        if let oldSuite = UserDefaults(suiteName: "uk.pixlwave.StingPad.StingDefaults") {
            oldSuite.dictionaryRepresentation().forEach { UserDefaults.presets.set($0.value, forKey: $0.key) }
            oldSuite.removePersistentDomain(forName: "uk.pixlwave.StingPad.StingDefaults")
        }
        
        return true
    }
    
    #warning("Needs testing on device")
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard
            url.isFileURL,
            let showBrowser = window?.rootViewController as? ShowBrowserViewController
        else { return false }
        
        if let playbackVC = showBrowser.presentedPlaybackViewController {
            playbackVC.closeShow()
        }
        
        if url.isFileInsideInbox {
            showBrowser.revealDocument(at: url, importIfNeeded: true) { importedURL, error in
                guard let importedURL = importedURL else { return }
                showBrowser.openShow(at: importedURL)
            }
            return false
        } else {
            showBrowser.openShow(at: url)
            return true
        }
    }
    
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        Engine.shared.isInBackground = true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Engine.shared.isInBackground = false
    }
    
}

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // prevent device from going to sleep
        application.isIdleTimerDisabled = true
        
        Engine.shared.enableMultiRoutes()
        
        // customise appearance
        if let exoFont = UIFont(name: "Exo2-Regular", size: 18), let exoBoldFont = UIFont(name: "Exo2-SemiBold", size: 18) {
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.font: exoFont]
            UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: exoBoldFont], for: UIControl.State())
        }
        
        return true
    }
    
}

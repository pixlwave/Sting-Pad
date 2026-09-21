import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // prevent device from going to sleep
        application.isIdleTimerDisabled = true
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        Engine.shared.isInBackground = true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Engine.shared.isInBackground = false
    }
    
}

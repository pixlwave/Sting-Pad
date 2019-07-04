import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // prevent device from going to sleep
        application.isIdleTimerDisabled = true
        
        // applies the included tint colour to UIAlertController (and presumably others)
        window?.tintColor = UIColor(named: "Tint Color")
        
        return true
    }
    
}

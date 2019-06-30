import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // prevent device from going to sleep
        application.isIdleTimerDisabled = true
        
        #if targetEnvironment(simulator)
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path)
        #endif
        
        return true
    }
    
}

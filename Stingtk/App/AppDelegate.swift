import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // prevent device from going to sleep
        application.isIdleTimerDisabled = true
        
        // allow music to play whilst muted with playback category
        // prevent app launch from killing iPod by allowing mixing
        setMixingState(true)
        
        // customise appearance
        if let exoFont = UIFont(name: "Exo2-Regular", size: 18), let exoBoldFont = UIFont(name: "Exo2-SemiBold", size: 18) {
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.font: exoFont]
            UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: exoBoldFont], for: UIControl.State())
        }
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // disables mixing so that if a sting is playing and the user chooses to play something else, stingtk is faded out
        if Engine.sharedClient.ipod.isPlaying == false { setMixingState(false) }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // re-enables mixing so app launch doesn't kill iPod music
        setMixingState(true)
    }
    
    func setMixingState(_ state: Bool) {
        // TODO: Test this is correct?
        let session = AVAudioSession.sharedInstance()
        if state {
            do {
                try session.setCategory(.playback, mode: .default, options: .mixWithOthers)
            } catch {}
        } else {
            do {
                try session.setCategory(.playback, mode: .default)
            } catch {}
        }
    }


}

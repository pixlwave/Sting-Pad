import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // prevent device from going to sleep
        application.idleTimerDisabled = true
        
        // allow music to play whilst muted with playback category
        // prevent app launch from killing iPod by allowing mixing
        setMixingState(true)
        
        // customise appearance
        if let exoFont = UIFont(name: "Exo2-Regular", size: 18), exoBoldFont = UIFont(name: "Exo2-SemiBold", size: 18) {
            UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: exoFont]
            UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: exoBoldFont], forState: UIControlState.Normal)
        }
        
        return true
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // disables mixing so that if a sting is playing and the user chooses to play something else, stingtk is faded out
        if Engine.sharedClient.ipod.isPlaying == false { setMixingState(false) }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // re-enables mixing so app launch doesn't kill iPod music
        setMixingState(true)
    }
    
    func setMixingState(state: Bool) {
        // TODO: Test this is correct?
        let session = AVAudioSession.sharedInstance()
        if state {
            do {
                try session.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
            } catch {}
        } else {
            do {
                try session.setCategory(AVAudioSessionCategoryPlayback)
            } catch {}
        }
    }


}


import UIKit

class AddStingFooterView: UICollectionReusableView {
    
    @IBAction func addFromLibrary() {
        #warning("Is this necessary or an SDK bug workaround")
        // send a notification as wiring up an action on the file's owner only worked once
        NotificationCenter.default.post(Notification(name: .addStingFromLibrary))
    }
}

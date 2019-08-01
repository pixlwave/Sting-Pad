import UIKit

class SettingsViewController: UITableViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Left Channel Selection", let channelSelectionVC = segue.destination as? ChannelSelectionViewController {
            channelSelectionVC.playbackChannel = .left
            channelSelectionVC.navigationItem.title = "Left Channel"
        } else if segue.identifier == "Right Channel Selection", let channelSelectionVC = segue.destination as? ChannelSelectionViewController {
            channelSelectionVC.playbackChannel = .right
            channelSelectionVC.navigationItem.title = "Right Channel"
        }
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

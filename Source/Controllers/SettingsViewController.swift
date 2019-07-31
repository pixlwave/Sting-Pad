import UIKit

class SettingsViewController: UITableViewController {
    
    var settings = Settings.shared
    
    @IBOutlet weak var launchModeControl: UISegmentedControl!
    @IBOutlet weak var showsTransportBarSwitch: UISwitch!
    @IBOutlet weak var autoCueSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        launchModeControl.selectedSegmentIndex = settings.launchMode.rawValue
        showsTransportBarSwitch.isOn = settings.showsTransportBar
        autoCueSwitch.isOn = settings.autoCue
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func launchModeDidChange(_ sender: UISegmentedControl) {
        settings.launchMode = sender.selectedSegmentIndex == 0 ? .toggle : .trigger
    }
    
    @IBAction func showsTransportBarDidChange(_ sender: UISwitch) {
        settings.showsTransportBar = sender.isOn
    }
    
    @IBAction func autoCueDidChange(_ sender: UISwitch) {
        settings.autoCue = sender.isOn
    }
}

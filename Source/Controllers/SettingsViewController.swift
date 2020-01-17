import UIKit

class SettingsViewController: UITableViewController {
    
    var show: Show?
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    func setAllStingPresets() {
        show?.stings.forEach { $0.setPreset() }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (1, 1):
            setAllStingPresets()
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
}

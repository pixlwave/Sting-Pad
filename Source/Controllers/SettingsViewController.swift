import UIKit

class SettingsViewController: UITableViewController {
    
    var show: Show?
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    func storeAllStingDefaults() {
        show?.stings.forEach { $0.storeDefaults() }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (1, 1):
            storeAllStingDefaults()
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
}

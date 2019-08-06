import UIKit

class SettingsViewController: UITableViewController {
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    func importMusic() {
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { super.tableView(tableView, didSelectRowAt: indexPath); return }
        
        importMusic()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

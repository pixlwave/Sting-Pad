import UIKit

class ShowViewController: UITableViewController {
    
    private let engine = Engine.shared
    private var editedIndexPath: IndexPath?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let editedIndexPath = editedIndexPath {
            tableView.reloadRows(at: [editedIndexPath], with: .automatic)
            self.editedIndexPath = nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Edit Sting", let stingVC = segue.destination as? StingViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                editedIndexPath = indexPath
                stingVC.stingIndex = indexPath.row
            }
        }
    }
    
    @IBAction func addSting(_ sender: Any) {
        engine.addSting()
        tableView.insertRows(at: [IndexPath(row: engine.stings.count - 1, section: 1)], with: .automatic)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "File"
        case 1:
            return "Stings"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return engine.stings.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return tableView.dequeueReusableCell(withIdentifier: "File Cell") ?? UITableViewCell()
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Edit Sting Cell") ?? UITableViewCell()
            cell.textLabel?.text = engine.stings[indexPath.row].title
        
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let alert = UIAlertController(title: "New Show?", message: "Are you sure you would like to start a new show? This will delete any unsaved changes.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
                tableView.deselectRow(at: indexPath, animated: true)
            })
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { action in
                self.engine.newShow()   // reloads playback view controller via notification
                tableView.deselectRow(at: indexPath, animated: true)
                tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            })
            present(alert, animated: true)
        case 1:
            super.tableView(tableView, didSelectRowAt: indexPath)
        default:
            return
        }
    }
    
}

import UIKit

class ShowViewController: UITableViewController {
    
    private let engine = Engine.shared
    private var editedIndexPath: IndexPath?
    
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    
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
    
    @IBAction func addSting() {
        engine.addSting()
        tableView.insertRows(at: [IndexPath(row: engine.show.stings.count - 1, section: 1)], with: .automatic)
    }
    
    @IBAction func edit() {
        tableView.setEditing(!tableView.isEditing, animated: true)
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
            return engine.show.stings.count + 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return tableView.dequeueReusableCell(withIdentifier: "File Cell") ?? UITableViewCell()
        case 1:
            if indexPath.row < engine.show.stings.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Edit Sting Cell") ?? UITableViewCell()
                cell.textLabel?.text = engine.show.stings[indexPath.row].title
            
                return cell
            } else {
                return tableView.dequeueReusableCell(withIdentifier: "Add Sting Cell") ?? UITableViewCell()
            }
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
            if indexPath.row == engine.show.stings.count {
                tableView.deselectRow(at: indexPath, animated: true)
                addSting()
            }
        default:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == 1 else { return false }
        return indexPath.row < engine.show.stings.count  // ignores add sting button
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == 1 else { return false }
        return indexPath.row < engine.show.stings.count  // ignores add sting button
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { super.tableView(tableView, commit: editingStyle, forRowAt: indexPath); return }
        engine.show.stings.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        engine.show.stings.insert(engine.show.stings.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
    }
    
}

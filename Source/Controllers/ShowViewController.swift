import UIKit
import MediaPlayer

class ShowViewController: UITableViewController {
    
    private let engine = Engine.shared
    private var editedIndexPath: IndexPath?
    
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let editedIndexPath = editedIndexPath {
            tableView.reloadRows(at: [editedIndexPath], with: .automatic)
            self.editedIndexPath = nil
        }
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
            return engine.show.stings.count
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
            
            let sting = engine.show.stings[indexPath.row]
            cell.textLabel?.text = sting.name ?? sting.songTitle
        
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
        default:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        engine.show.stings.insert(engine.show.stings.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
    }
    
}

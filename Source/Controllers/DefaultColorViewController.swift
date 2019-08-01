import UIKit

class DefaultColorViewController: UITableViewController {
    
    lazy var dataSource = makeDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
        #warning("UITableView was told to layout its visible cells and other contents without being in the view hierarchy")
        applySnapshot()
    }
    
    func makeDataSource() -> UITableViewDiffableDataSource<Int, Color> {
        UITableViewDiffableDataSource<Int, Color>(tableView: tableView) { tableView, indexPath, color -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "ColorCell") ?? UITableViewCell()
            
            cell.textLabel?.text = "\(color)".capitalized
            cell.imageView?.tintColor = color.value
            cell.accessoryType = color == Color.default ? .checkmark : .none
            
            return cell
        }
    }
    
    func applySnapshot() {
        let snapshot = NSDiffableDataSourceSnapshot<Int, Color>()
        snapshot.appendSections([0])
        snapshot.appendItems(Color.allCases)
        dataSource.apply(snapshot)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        let oldColor = Color.default
        guard let color = dataSource.itemIdentifier(for: indexPath), oldColor != color else { return }
        
        Color.default = color
        
        let snapshot = dataSource.snapshot()
        snapshot.reloadItems([color, oldColor])
        
        dataSource.apply(snapshot)
    }
    
}

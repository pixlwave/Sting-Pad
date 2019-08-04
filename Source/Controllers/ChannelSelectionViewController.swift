import UIKit
import AVFoundation

class ChannelSelectionViewController: UITableViewController {
    
    var outputConfig = Engine.shared.outputConfig
    let outputChannelCount = Engine.shared.outputChannelCount()
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return outputChannelCount / 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        #warning("Get name of audio interface here...")
        return "Audio Interface Name"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell") ?? UITableViewCell()
        
        let cellChannels = channels(for: indexPath)
        
        if let textLabel = cell.textLabel {
            textLabel.text = "Channels \(cellChannels.0 + 1) & \(cellChannels.1 + 1)"
            textLabel.font = UIFont.monospacedDigitSystemFont(ofSize: textLabel.font.pointSize, weight: .regular)
        }
        
        if outputConfig.left == cellChannels.0, outputConfig.right == cellChannels.1 {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedChannels = channels(for: indexPath)
        outputConfig.left = selectedChannels.0
        outputConfig.right = selectedChannels.1
        tableView.reloadData()
        
        Engine.shared.outputConfig = outputConfig
    }
    
    func channels(for indexPath: IndexPath) -> (Int, Int) {
        return ((2 * indexPath.row), (2 * indexPath.row) + 1)
    }
    
}

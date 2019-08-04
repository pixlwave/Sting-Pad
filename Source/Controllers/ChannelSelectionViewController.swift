import UIKit
import AVFoundation

class ChannelSelectionViewController: UITableViewController {
    
    var outputConfig = Engine.shared.outputConfig
    let outputChannelCount = Engine.shared.outputChannelCount()
    
    func isOutputConfigAvailable() -> Bool {
        outputConfig.highestChannel < outputChannelCount
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        isOutputConfigAvailable() ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return outputChannelCount / 2
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            #warning("Get name of audio interface here...")
            return "Audio Interface Name"
        } else {
            return "Unavailable"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell") ?? UITableViewCell()
        
        if indexPath.section == 0 {
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
            
            cell.selectionStyle = .default
        } else {
            if let textLabel = cell.textLabel {
                textLabel.text = "Channels \(outputConfig.left + 1) & \(outputConfig.right + 1)"
                textLabel.font = UIFont.monospacedDigitSystemFont(ofSize: textLabel.font.pointSize, weight: .regular)
            }
            
            cell.accessoryType = .checkmark
            cell.selectionStyle = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        
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

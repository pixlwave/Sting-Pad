import UIKit
import AVFoundation

class ChannelSelectionViewController: UITableViewController {
    
    var outputConfig = Engine.shared.outputConfig
    let outputChannelCount = Engine.shared.outputChannelCount()
    
    func outputConfigIsDefault() -> Bool {
        outputConfig.left == 0 && outputConfig.right == 1
    }
    
    func outputConfigIsAvailable() -> Bool {
        outputConfig.highestChannel < outputChannelCount
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if outputConfigIsAvailable() {
            return 1
        } else if outputChannelCount == 1 && outputConfigIsDefault() {
            return 1    // hide channels 1 & 2 being unavailable for mono output
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if outputChannelCount == 1 { return 1 }     // ensure a cell is provided for a single mono output
            return outputChannelCount / 2
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return Engine.shared.audioInterfaceName()
        } else {
            return "Unavailable"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell") ?? UITableViewCell()
            
            if outputChannelCount == 1 {
                if let textLabel = cell.textLabel {
                    textLabel.text = "Mono output"
                    textLabel.font = .monospacedDigitSystemFont(ofSize: textLabel.font.pointSize, weight: .regular)
                }
                
                if outputConfigIsDefault() {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else {
                let cellChannels = channels(for: indexPath)
                
                if let textLabel = cell.textLabel {
                    textLabel.text = "Channels \(cellChannels.0 + 1) & \(cellChannels.1 + 1)"
                    textLabel.font = .monospacedDigitSystemFont(ofSize: textLabel.font.pointSize, weight: .regular)
                }
                
                if outputConfig.left == cellChannels.0, outputConfig.right == cellChannels.1 {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UnavailableChannelCell") ?? UITableViewCell()
            
            if let textLabel = cell.textLabel {
                textLabel.text = "Channels \(outputConfig.left + 1) & \(outputConfig.right + 1)"
                textLabel.font = .monospacedDigitSystemFont(ofSize: textLabel.font.pointSize, weight: .regular)
            }
            
            return cell
        }
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

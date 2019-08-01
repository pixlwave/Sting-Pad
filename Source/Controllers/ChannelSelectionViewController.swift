import UIKit
import AVFoundation

class ChannelSelectionViewController: UITableViewController {
    
    var outputConfig = Engine.shared.outputConfig
    let outputChannelCount = Engine.shared.outputChannelCount()
    
    @IBAction func channelSelectionDidChange(_ sender: UISegmentedControl) {
        let outputChannel = sender.tag
        
        switch sender.selectedSegmentIndex {
        case 0:
            // left playback channel
            let oldOutputChannel = outputConfig.left
            outputConfig.left = outputChannel
            tableView.reloadRows(at: [IndexPath(row: oldOutputChannel, section: 0), IndexPath(row: outputChannel, section: 0)], with: .automatic)
        case 1:
            // right playback channel
            let oldOutputChannel = outputConfig.right
            outputConfig.right = outputChannel
            tableView.reloadRows(at: [IndexPath(row: oldOutputChannel, section: 0), IndexPath(row: outputChannel, section: 0)], with: .automatic)
        default:
            return
        }
        
        Engine.shared.outputConfig = outputConfig
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return outputChannelCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell") as? ChannelCell ?? ChannelCell()
        
        cell.textLabel?.text = "Channel \(indexPath.row + 1)"
        cell.selectorControl.tag = indexPath.row
        
        if indexPath.row == outputConfig.left {
            cell.selectorControl.selectedSegmentIndex = 0
        } else if indexPath.row == outputConfig.right {
            cell.selectorControl.selectedSegmentIndex = 1
        } else {
            cell.selectorControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        
        return cell
    }
    
}

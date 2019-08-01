import UIKit
import AVFoundation

class ChannelSelectionViewController: UITableViewController {
    
    enum PlaybackChannel {
        case left, right
    }
    var playbackChannel: PlaybackChannel = .left
    var outputConfig = Engine.shared.outputConfig
    let outputChannelCount = Engine.shared.outputChannelCount()
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return outputChannelCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell") ?? UITableViewCell()
        
        cell.textLabel?.text = "Output \(indexPath.row + 1)"
        
        switch playbackChannel {
        case .left:
            cell.accessoryType = outputConfig.left == indexPath.row ? .checkmark : .none
        case .right:
            cell.accessoryType = outputConfig.right == indexPath.row ? .checkmark : .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch playbackChannel {
        case .left:
            outputConfig.left = indexPath.row
            tableView.reloadData()
        case .right:
            outputConfig.right = indexPath.row
            tableView.reloadData()
        }
        
        Engine.shared.outputConfig = outputConfig
    }
    
}

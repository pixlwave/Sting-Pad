import UIKit
import MediaPlayer

class BackgroundController: UITableViewController {
    
    private let engine = Engine.sharedClient
    private var currentPlaylist: MPMediaPlaylist? {
        return engine.ipod.playlist
    }
    
    private var playlistImage = UIImage(named: "playlist")
    private var smartPlaylistImage = UIImage(named: "smartplaylist")
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let playlistIndex = engine.ipod.playlistIndex {
            let indexPath = NSIndexPath(forRow: playlistIndex, inSection: 0)
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: false)
        }
    }
    
    @IBAction func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engine.ipod.allPlaylists.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Playlists"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Playlist Cell") ?? UITableViewCell(style: .Default, reuseIdentifier: "Playlist Cell")
        
        let playlist = engine.ipod.allPlaylists[indexPath.row]
        cell.textLabel?.text = playlist.valueForProperty(MPMediaPlaylistPropertyName) as? String
        
        if let attributes = playlist.valueForProperty(MPMediaPlaylistPropertyPlaylistAttributes) as? NSNumber {
            if attributes == Int(MPMediaPlaylistAttribute.Smart.rawValue) {
                cell.imageView?.image = smartPlaylistImage
            } else {
                cell.imageView?.image = playlistImage
            }
        }
        
        if playlist == currentPlaylist {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    
    // MARK: UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedPlaylist = engine.ipod.allPlaylists[indexPath.row]
        
        // don't update playlist when it's already the current playlist
        if selectedPlaylist != currentPlaylist {
            // TODO: Test ?? 0 for cases where selected is also 0
            let oldIndexPath = NSIndexPath(forRow: engine.ipod.playlistIndex ?? 0, inSection: 0)
            
            engine.ipod.usePlaylist(indexPath.row)
            (presentingViewController as! StkController).playlistDidChange()
            
            // update checkmark and clear selection
            let indexPaths = [oldIndexPath, indexPath]
            tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            
            save(engine.ipod)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func save(ipod: Music) {
        // this needs to be changed to save by playlist id or similar
        // would enable checking of playlist properly if order changed
        Defaults["Playlist Index"] = ipod.playlistIndex
    }
    
}

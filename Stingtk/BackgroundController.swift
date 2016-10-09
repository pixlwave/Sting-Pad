import UIKit
import MediaPlayer

class BackgroundController: UITableViewController {
    
    private let engine = Engine.sharedClient
    private var currentPlaylist: MPMediaPlaylist? {
        return engine.ipod.playlist
    }
    
    private var playlistImage = UIImage(named: "playlist")
    private var smartPlaylistImage = UIImage(named: "smartplaylist")
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let playlistIndex = engine.ipod.playlistIndex {
            let indexPath = IndexPath(row: playlistIndex, section: 0)
            tableView.scrollToRow(at: indexPath, at: .none, animated: false)
        }
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return engine.ipod.allPlaylists.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Playlists"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Playlist Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Playlist Cell")
        
        let playlist = engine.ipod.allPlaylists[indexPath.row]
        cell.textLabel?.text = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String
        
        if let attributes = playlist.value(forProperty: MPMediaPlaylistPropertyPlaylistAttributes) as? MPMediaPlaylistAttribute {
            if attributes == .smart {
                cell.imageView?.image = smartPlaylistImage
            } else {
                cell.imageView?.image = playlistImage
            }
        }
        
        if playlist == currentPlaylist {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlaylist = engine.ipod.allPlaylists[indexPath.row]
        
        // don't update playlist when it's already the current playlist
        if selectedPlaylist != currentPlaylist {
            // TODO: Test ?? 0 for cases where selected is also 0
            let oldIndexPath = IndexPath(row: engine.ipod.playlistIndex ?? 0, section: 0)
            
            engine.ipod.usePlaylist(indexPath.row)
            (presentingViewController as! StkController).playlistDidChange()
            
            // update checkmark and clear selection
            let indexPaths = [oldIndexPath, indexPath]
            tableView.reloadRows(at: indexPaths, with: .automatic)
            
            save(engine.ipod)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func save(_ ipod: Music) {
        // this needs to be changed to save by playlist id or similar
        // would enable checking of playlist properly if order changed
        UserDefaults.standard.set(ipod.playlistIndex, forKey: "Playlist Index")
    }
    
}

import UIKit
import MediaPlayer

class PickerCoordinator: NSObject {
    let show: Show
    let pickerOperation: PickerOperation
    
    init(show: Show, pickerOperation: PickerOperation) {
        self.show = show
        self.pickerOperation = pickerOperation
    }
    
    func replace(_ missingSting: Sting, with sting: Sting) {
        missingSting.reloadAudio(from: sting)
        show.updateChangeCount(.done)
        
        // post a notification to update the collection view cell
        NotificationCenter.default.post(Notification(name: .didFinishEditing, object: sting))
    }
    
    func load(_ sting: Sting) {
        switch pickerOperation {
        case .insert(let index) where index < show.stings.count:
            show.insert(sting, at: index)
        case .locate(let missingSting):
            missingSting.reloadAudio(from: sting)
            show.updateChangeCount(.done)
            
            // notification to update the playback collection view cell
            NotificationCenter.default.post(Notification(name: .didFinishEditing, object: missingSting))
            // notification to update stings management list
            NotificationCenter.default.post(Notification(name: .unavailableStingsDidChange))
        default:
            show.append(sting)
            
            // notification to scroll to the end of the show
            NotificationCenter.default.post(Notification(name: .didAppendSting, object: sting))
        }
    }
}


// MARK: MPMediaPickerControllerDelegate
extension PickerCoordinator: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // make a sting from the selected media item, add it to the engine and update the table view
        if let sting = Sting(mediaItem: mediaItemCollection.items[0]) {
            load(sting)
        }
        
        // dismiss media picker
        mediaPicker.dismiss(animated: true)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true)
    }
}


// MARK: UIDocumentPickerDelegate
extension PickerCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let sting = Sting(url: urls[0]) {
            load(sting)
        }
    }
}

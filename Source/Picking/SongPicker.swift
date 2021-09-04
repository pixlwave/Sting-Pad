import SwiftUI
import MediaPlayer

struct SongPicker: UIViewControllerRepresentable {
    let show: Show
    let pickerOperation: PickerOperation
    
    func makeUIViewController(context: Context) -> MPMediaPickerController {
        // a music picker to load a track from media library
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = context.coordinator
        mediaPicker.showsCloudItems = false  // hides iTunes in the Cloud items, which crash the app if picked
        mediaPicker.showsItemsWithProtectedAssets = false  // hides Apple Music items, which are DRM protected
        mediaPicker.allowsPickingMultipleItems = false
        
        return mediaPicker
    }
    
    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {
        // nothing to update
    }
    
    func makeCoordinator() -> PickerCoordinator {
        PickerCoordinator(show: show, pickerOperation: pickerOperation)
    }
}

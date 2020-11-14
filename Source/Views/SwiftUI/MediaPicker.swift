import SwiftUI
import MediaPlayer

struct MediaPicker: UIViewControllerRepresentable {
    @EnvironmentObject var playbackController: PlaybackController
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = context.coordinator
        mediaPicker.showsCloudItems = false  // hides iTunes in the Cloud items, which crash the app if picked
        mediaPicker.showsItemsWithProtectedAssets = false  // hides Apple Music items, which are DRM protected
        mediaPicker.allowsPickingMultipleItems = false
        
        return mediaPicker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(controller: playbackController, presentationMode: presentationMode.wrappedValue)
    }
    
    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        let playbackController: PlaybackController
        var presentationMode: PresentationMode
        
        init(controller: PlaybackController, presentationMode: PresentationMode) {
            self.playbackController = controller
            self.presentationMode = presentationMode
        }
        
        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            // make a sting from the selected media item, add it to the engine and update the table view
            if let sting = Sting(mediaItem: mediaItemCollection.items[0]) {
                playbackController.load(sting)
            }
            
            // dismiss media picker
            presentationMode.dismiss()
        }
        
        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            playbackController.pickerOperation = .normal
            presentationMode.dismiss()
        }
    }
}

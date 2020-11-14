import SwiftUI

struct FilePicker: UIViewControllerRepresentable {
    @EnvironmentObject var playbackController: PlaybackController
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        documentPicker.delegate = context.coordinator
        
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(controller: playbackController)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let playbackController: PlaybackController
        
        init(controller: PlaybackController) {
            self.playbackController = controller
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let sting = Sting(url: urls[0]) {
                playbackController.load(sting)
            }
        }
    }
}

import SwiftUI
import MediaPlayer

struct FilePicker: UIViewControllerRepresentable {
    let show: Show
    let pickerOperation: PickerOperation
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // present file picker to load a track from
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        documentPicker.delegate = context.coordinator
        
        // start in the original directory if locating a sting
        if case .locate(let sting) = pickerOperation {
            documentPicker.directoryURL = sting.url.deletingLastPathComponent()
        }
        
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // nothing to update
    }
    
    func makeCoordinator() -> PickerCoordinator {
        PickerCoordinator(show: show, pickerOperation: pickerOperation)
    }
}

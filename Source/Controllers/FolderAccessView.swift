import SwiftUI

struct FolderAccessView: UIViewControllerRepresentable {
    let show: Show
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = context.coordinator
        
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let view: FolderAccessView
        
        init(_ view: FolderAccessView) {
            self.view = view
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            urls.forEach { url in
                UserDefaults.bookmarks.setBookmark(from: url, forKey: url.path)
            }
            view.show.reloadWithBookmarks()
        }
    }
}

import SwiftUI

struct Waveform: UIViewControllerRepresentable {
    let show: Show
    let sting: Sting
    
    @Binding var previewLength: TimeInterval
    
    func makeCoordinator() -> Coordinator {
        Coordinator(previewLength: $previewLength)
    }
    
    func makeUIViewController(context: Context) -> WaveformViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard
            let viewController = storyboard.instantiateViewController(withIdentifier: "Waveform View Controller") as? WaveformViewController
        else { fatalError("Unable to load waveform view controller from storyboard") }
        
        viewController.show = show
        viewController.sting = sting
        viewController.coordinator = context.coordinator
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: WaveformViewController, context: Context) {
        uiViewController.previewLength = previewLength
    }
    
    struct Coordinator {
        @Binding var previewLength: TimeInterval
        
        func setPreviewLength(_ length: TimeInterval) {
            previewLength = length
        }
    }
}

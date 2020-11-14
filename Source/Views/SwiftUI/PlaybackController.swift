import Foundation
import MediaPlayer

class PlaybackController: ObservableObject {
    let engine = Engine.shared
    @Published var show: Show
    @Published var cuedSting: Sting?
//    {
//        didSet { if let sting = cuedSting { scrollTo(sting) } }
//    }
    
    var pickerOperation: PickerOperation = .normal
    
    enum PickerOperation {
        case normal
        case locate(Sting)
        case insert(Int)
        #warning("Replace int with file?")
    }
    
    init(show: Show) {
        self.show = show
    }
    
    func closeShow() {
        engine.stopSting()
        show.close { success in
            #warning("Dismiss on close?")
        }
    }
    
    func load(_ sting: Sting) {
        switch pickerOperation {
        case .insert(let index) where index < show.stings.count:
            show.insert(sting, at: index)
            pickerOperation = .normal
        case .locate(let missingSting):
            missingSting.reloadAudio(from: sting)
            show.updateChangeCount(.done)
            pickerOperation = .normal
        default:
            show.append(sting)
            #warning("Scroll to sting without animation.")
        }
    }
    
    func rename(_ sting: Sting, to name: String?) {
        let oldName = sting.name
        sting.name = name
        if sting.name != oldName {
            show.undoManager.registerUndo(withTarget: self) { _ in
                self.rename(sting, to: oldName)
            }
        }
    }
    
    func change(_ sting: Sting, to color: Sting.Color) {
        let oldColor = sting.color
        sting.color = color
        if sting.color != oldColor {
            show.undoManager.registerUndo(withTarget: self) { _ in
                self.change(sting, to: oldColor)
            }
        }
    }
    
    func playSting() {
        guard let sting = cuedSting ?? show.stings.playable.first else { return }
        
        engine.play(sting)
        nextCue()
    }
    
    func stopSting() {
        engine.stopSting()
    }
    
    func validateCuedSting() {
        guard let cuedSting = cuedSting else {
            self.cuedSting = show.stings.playable.first
            return
        }
        
        if !show.stings.playable.contains(cuedSting) {
            self.cuedSting = show.stings.playable.first
        }
    }
    
    func nextCue() {
        let playableStings = show.stings.playable
        
        guard
            playableStings.count > 1,
            let oldCue = cuedSting,
            let oldCueIndex = playableStings.firstIndex(of: oldCue)
        else { return }
        
        let newCueIndex = (oldCueIndex + 1) % playableStings.count
        let newCue = playableStings[newCueIndex]
        cuedSting = newCue
    }
    
    func previousCue() {
        let playableStings = show.stings.playable
        
        guard
            playableStings.count > 1,
            let oldCue = cuedSting,
            let oldCueIndex = playableStings.firstIndex(of: oldCue),
            oldCueIndex > 0
        else { return }
        
        let newCueIndex = (oldCueIndex - 1) % playableStings.count
        let newCue = playableStings[newCueIndex]
        cuedSting = newCue
    }
    
}

import SwiftUI
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
            withAnimation { show.insert(sting, at: index) }
            pickerOperation = .normal
        case .locate(let missingSting):
            missingSting.reloadAudio(from: sting)
            show.updateChangeCount(.done)
            pickerOperation = .normal
        default:
            withAnimation { show.append(sting) }
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
    
    func duplicate(_ sting: Sting) {
        guard let duplicate = sting.copy() else { return }
        withAnimation { show.insert(duplicate, before: sting) }
    }
    
    func insertSting(before sting: Sting) {
        pickerOperation = .insert(0)
//        pickStingFromLibrary()
    }
    
    func delete(_ sting: Sting) {
        guard sting != engine.playingSting else { return }
        if sting == cuedSting {
            nextCue()
            // remove cued sting if next cue is still the chosen sting
            if sting == cuedSting { cuedSting = nil }
        }
        withAnimation { _ = show.remove(sting) }
    }
    
    func locate(_ sting: Sting) {
        pickerOperation = .locate(sting)
        if sting.url.isMediaItem {
//            pickStingFromLibrary()
        } else {
//            pickStingFromFiles()
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

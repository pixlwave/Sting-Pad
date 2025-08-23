import Foundation

@Observable class PlaybackViewModel {
    let engine = Engine.shared
    let show: Show
    var cuedSting: Sting?
    
    private(set) var progress: Progress
    private var progressTimer: Timer?
    
    init(show: Show, progress: Progress = Progress(elapsed: 0, total: 0)) {
        self.show = show
        self.progress = progress
        engine.playbackDelegate = self
    }
    
    func closeShow() async {
        engine.stopSting()
        await show.close()
    }
    
    func rename(_ sting: Sting, to name: String?) {
        let oldName = sting.name
        sting.name = name
        if sting.name != oldName {
            show.undoManager.registerUndo(withTarget: self) {
                $0.rename(sting, to: oldName)
            }
        }
    }
    
    func change(_ sting: Sting, to color: Sting.Color) {
        let oldColor = sting.color
        sting.color = color
        if sting.color != oldColor {
            show.undoManager.registerUndo(withTarget: self) {
                $0.change(sting, to: oldColor)
            }
        }
    }
    
    func copy(_ sting: Sting, to index: Int) {
        guard let duplicate = sting.copy() else { return }
        show.insert(duplicate, at: index)
    }
    
    func delete(_ sting: Sting, at index: Int) {
        guard sting != engine.playingSting else { return }
        if sting == cuedSting {
            nextCue()
            // remove cued sting if next cue is still the chosen sting
            if sting == cuedSting { cuedSting = nil }
        }
        show.removeSting(at: index)
    }
    
    // MARK: - Playback
    
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
    
    func updateProgress() {
        progress.elapsed = engine.elapsedTime
        progress.total = engine.totalTime
    }
    
    func beginUpdatingProgress() {
        if progressTimer?.isValid == true {
            stopUpdatingProgress()
        }
        
        updateProgress()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateProgress()
        }
    }
    
    func stopUpdatingProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
        
        progress.elapsed = 0
        progress.total = cuedSting?.totalTime ?? 0
    }
}

// MARK: PlaybackDelegate
extension PlaybackViewModel: PlaybackDelegate {
    func stingDidStartPlaying(_ sting: Sting) {
        beginUpdatingProgress()
    }
    
    func stingDidStopPlaying(_ sting: Sting) {
        DispatchQueue.main.async {
            // by the time this executes another sting may have already started playback
            if self.engine.playingSting == nil { self.stopUpdatingProgress() }
        }
    }
}

extension PlaybackViewModel {
    struct Progress {
        var elapsed: TimeInterval
        var total: TimeInterval
        
        var value: Double {
            guard total > 0 else { return 0 }
            let progress = (elapsed / total).truncatingRemainder(dividingBy: 1) // + (1 / total)
            return max(0, min(1, progress))
            
            // Make sure not to animate the loop point 🤔
            // if progressView.progress == 1 {
            //    progressView.reset()
            // }
            // UIView.animate { progressView.progress = newValue }
        }
        
        var remaining: String {
            let timeRemaining = total - elapsed
            if timeRemaining < 0 {
                return "Looping"
            } else if let remainingString = timeRemaining.formattedAsRemaining() {
                return remainingString
            } else {
                return "0:00 remaining"
            }
        }
    }
}

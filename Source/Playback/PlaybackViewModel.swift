import Foundation
import MediaPlayer

@Observable class PlaybackViewModel {
    let engine = Engine.shared
    let show: Show
    var cuedSting: Sting?
    
    var state = State()
    
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
    
    // MARK: - Editing
    
    func presentRenameDialog(for sting: Sting) {
        state.stingToRename = sting
        state.renameText = sting.name ?? ""
        state.isPresentingRenameAlert = true
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
    
    // MARK: Picking
    
    func pickStingFromLibrary(pickerOperation: PickerOperation) {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            if MPMediaLibrary.authorizationStatus() == .notDetermined {
                requestMediaLibraryAuthorization { self.pickStingFromLibrary(pickerOperation: pickerOperation) }
            } else {
                state.isPresentingMediaLibraryAccessAlert = true
            }
            
            return
        }
        
        #if targetEnvironment(simulator)
        // pick a random file from the file system as no library is available on the simulator
        Task { await loadRandomTrackFromHostFileSystem() }
        #else
        
        state.songPickerOperation = pickerOperation
        #endif
    }
    
    func pickStingFromFiles(pickerOperation: PickerOperation) {
        state.filePickerOperation = pickerOperation
    }
    
    func requestMediaLibraryAuthorization(successHandler: @escaping () -> Void) {
        MPMediaLibrary.requestAuthorization { authorizationStatus in
            if authorizationStatus == .authorized {
                DispatchQueue.main.async { successHandler() }
            }
        }
    }
    
    #if targetEnvironment(simulator)
    func loadRandomTrackFromHostFileSystem() async {
        let sharedMusicDirectory = URL(filePath: "/Users/Shared/Music")
        guard let sharedFiles = try? FileManager.default.contentsOfDirectory(at: sharedMusicDirectory, includingPropertiesForKeys: nil) else { return }
        
        let audioFiles = sharedFiles.filter { $0.pathExtension == "mp3" || $0.pathExtension == "m4a" }
        guard audioFiles.count > 0 else { fatalError() }
        let fileURL = audioFiles[Int.random(in: 0..<audioFiles.count)]
        
        if let sting = await Sting(url: fileURL) {
            PickerCoordinator(show: show, pickerOperation: .normal).load(sting)
        }
    }
    #endif
    
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

// MARK: - Models

extension PlaybackViewModel {
    struct State {
        var songPickerOperation: PickerOperation?
        var filePickerOperation: PickerOperation?
        var isPresentingMediaLibraryAccessAlert = false
        
        var isPresentingRenameAlert = false
        var stingToRename: Sting?
        var renameText = ""
        
        var stingToEdit: Sting?
        
        var isPresentingSettings = false
        var isPresentingManageStings = false
    }
    
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

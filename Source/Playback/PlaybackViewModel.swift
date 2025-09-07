import Foundation
import MediaPlayer
import OSLog

#warning("Revisit the implicit @MainActor with the new Approachable Concurrency stuff.")
@Observable @MainActor class PlaybackViewModel {
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
        
        NotificationCenter.default.addObserver(forName: UIDocument.stateChangedNotification, object: show, queue: nil) { notification in
            guard let show = notification.object as? Show else { return }
            os_log("Show State Changed: %d", log: .default, type: .debug, show.documentState.rawValue)
        }
    }
    
    func closeShow() async {
        engine.stopSting()
        await show.close()
        
        NotificationCenter.default.removeObserver(self)
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
        progress.update(elapsed: engine.elapsedTime, total: engine.totalTime)
    }
    
    func beginUpdatingProgress() {
        if progressTimer?.isValid == true {
            stopUpdatingProgress()
        }
        
        updateProgress()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.updateProgress() }
        }
    }
    
    func stopUpdatingProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
        
        progress.reset(total: cuedSting?.totalTime ?? 0)
    }
}

// MARK: PlaybackDelegate

extension PlaybackViewModel: PlaybackDelegate {
    nonisolated func stingDidStartPlaying(_ sting: Sting) {
        Task { await beginUpdatingProgress() }
    }
    
    nonisolated func stingDidStopPlaying(_ sting: Sting) {
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
        private(set) var elapsed: TimeInterval = 0
        private(set) var total: TimeInterval = 0
        private(set) var value: Double
        
        init(elapsed: TimeInterval, total: TimeInterval) {
            self.elapsed = elapsed
            self.total = total
            self.value = 0
            
            calculateNextValue()
        }
        
        mutating func update(elapsed: TimeInterval, total: TimeInterval) {
            self.elapsed = elapsed
            self.total = total
            
            calculateNextValue()
        }
        
        mutating func reset(total: TimeInterval) {
            self.total = total
            elapsed = 0
            value = 0
            
            // Don't calculate the next value as this is the stopped state.
        }
        
        /// Calculates the next value to be shown by adding an additional 1-second as compensation for the animation time.
        private mutating func calculateNextValue() {
            guard total > 0 else { return }
            let rawValue = (elapsed / total).truncatingRemainder(dividingBy: 1) + (1 / total)
            value = max(0, min(1, rawValue))
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

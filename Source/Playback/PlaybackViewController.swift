import UIKit
import MediaPlayer
import MobileCoreServices
import SwiftUI
import os.log

class PlaybackViewController: UICollectionViewController {
    
    private let engine = Engine.shared
    var show: Show!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Sting>?
    private var cuedSting: Sting? {
        didSet { if let sting = cuedSting { scrollTo(sting) } }
    }
    
    @IBOutlet weak var manageStingsButton: UIBarButtonItem!
    @IBOutlet var transportView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    private let transportViewHeight: CGFloat = 90
    private var progressTimer: Timer?
    private var progressAnimator: UIViewPropertyAnimator?
    
    private var pickerOperation: PickerOperation = .normal
    
    private enum PickerOperation {
        case normal
        case locate(Sting)
        case insert(Int)
    }
    
    // respond to undo gestures, forwarding them to the show's undo manager
    override var canBecomeFirstResponder: Bool { true }
    override var undoManager: UndoManager? { return show.undoManager }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self delegate for sting players
        engine.playbackDelegate = self
        
        // load the transport view nib and add as a subview via it's outlet
        Bundle.main.loadNibNamed("TransportView", owner: self, options: nil)
        view.addSubview(transportView)
        progressView.progress = 0
        timeRemainingLabel.font = .monospacedDigitSystemFont(ofSize: timeRemainingLabel.font.pointSize, weight: .regular)
        
        configureDataSource()
        collectionView.register(UINib(nibName: "AddStingFooterView", bundle: nil), forSupplementaryViewOfKind: "footer", withReuseIdentifier: "AddStingFooter")
        collectionView.collectionViewLayout = createLayout()
        collectionView.dragInteractionEnabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(pickStingFromLibrary), name: .addStingFromLibrary, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pickStingFromFiles), name: .addStingFromFiles, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applySnapshot), name: .stingsDidChange, object: show)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadEditedSting(_:)), name: .didFinishEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showStateChanged(_:)), name: UIDocument.stateChangedNotification, object: show)
        
        manageStingsButton.image = manageStingsButton.image?.withConfiguration(UIImage.SymbolConfiguration(weight: .semibold))
        if show.unavailableStings.count == 0 { navigationItem.rightBarButtonItems?.removeAll{ $0 == manageStingsButton } }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()  // respond to undo gestures
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    override func viewWillLayoutSubviews() {
        let origin = CGPoint(x: 0, y: view.frame.height - view.safeAreaInsets.bottom - transportViewHeight)
        let size = CGSize(width: view.frame.width, height: view.bounds.height - origin.y)
        transportView?.frame = CGRect(origin: origin, size: size)
        collectionView.contentInset.bottom = size.height
        collectionView.verticalScrollIndicatorInsets.bottom = size.height
    }
    
    @IBSegueAction func manageStingsSegue(_ coder: NSCoder) -> UIViewController? {
        let view = ManageStingsView(show: show, dismiss: { self.dismiss(animated: true) })
        return UIHostingController(coder: coder, rootView: view)
    }
    
    @IBSegueAction func settingsSegue(_ coder: NSCoder) -> UIViewController? {
        let view = SettingsView(show: show, dismiss: { self.dismiss(animated: true) })
        return UIHostingController(coder: coder, rootView: view)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Edit Sting" {
            guard
                let navigationVC = segue.destination as? UINavigationController,
                let editVC = navigationVC.topViewController as? EditViewController,
                let sting = sender as? Sting
            else { return }
            
            editVC.show = show
            editVC.sting = sting
        }
    }
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            let minimumWidth: CGFloat = 300
            let effectiveWidth = layoutEnvironment.container.effectiveContentSize.width
            let count = effectiveWidth > minimumWidth ? Int(effectiveWidth / minimumWidth) : 1  // ensure count is greater than 0
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(110))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = item.contentInsets
            
            let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: groupSize, elementKind: "footer", alignment: .bottom)
            section.boundarySupplementaryItems = [footer]
            // footer doesn't seem to obay the bottom insets, so this is compensated for the subview layout
            footer.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
            
            return section
        }
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Sting>(collectionView: collectionView) { collectionView, indexPath, sting -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Sting Cell", for: indexPath)
            
            guard let stingCell = cell as? StingCell else { return cell }
            
            stingCell.titleLabel.text = sting.name ?? sting.songTitle
            stingCell.color = sting.color
            
            if sting.audioFile == nil {
                stingCell.isMissing = true
                stingCell.footerLabel.text = sting.availability.rawValue
            } else if sting.loops, let loopImage = UIImage(systemName: "repeat") {
                stingCell.isMissing = false
                let loopString = NSAttributedString(attachment: NSTextAttachment(image: loopImage))
                stingCell.footerLabel.attributedText = loopString
            } else {
                stingCell.isMissing = false
                stingCell.footerLabel.text = sting.totalTime.formattedAsLength()
            }
            
            stingCell.isCued = sting == self.cuedSting
            stingCell.isPlaying = sting == self.engine.playingSting
            
            return stingCell
        }
        
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "AddStingFooter", for: indexPath)
        }
    }
    
    @objc func applySnapshot() {
        // ensure there's a cued sting if possible
        validateCuedSting()
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, Sting>()
        snapshot.appendSections([0])
        snapshot.appendItems(show.stings)
        dataSource?.apply(snapshot)
    }
    
    func reloadItems(_ identifiers: [Sting]) {
        guard let dataSource = dataSource else { return }
        let uniqueIdentifiers = Set(identifiers)
        var snapshot = dataSource.snapshot()
        
        guard uniqueIdentifiers.isSubset(of: snapshot.itemIdentifiers) else {
            os_log("WARNING: Attempted to reload a sting that is no longer in the collection view.", log: .default, type: .debug)
            applySnapshot()
            return
        }
        
        snapshot.reloadItems(Array(uniqueIdentifiers))
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc func reloadEditedSting(_ notification: Notification) {
        becomeFirstResponder()  // ensure undo works again
        guard let sting = notification.object as? Sting else { return }
        reloadItems([sting])
    }
    
    @objc func showStateChanged(_ notification: Notification) {
        os_log("Show State Changed: %d", log: .default, type: .debug, show.documentState.rawValue)
    }
    
    @IBAction func closeShow() {
        // stop listening for notifications in case a new show is opened before this gets deallocated
        NotificationCenter.default.removeObserver(self)
        
        engine.stopSting()
        show.close { success in
            (self.presentingViewController as? ShowBrowserViewController)?.isLoading = false
            self.dismiss(animated: true)
        }
        
        // set data source to nil to remove reference cycle
        dataSource = nil
    }
    
    func requestMediaLibraryAuthorization(successHandler: @escaping () -> Void) {
        MPMediaLibrary.requestAuthorization { authorizationStatus in
            if authorizationStatus == .authorized {
                DispatchQueue.main.async { successHandler() }
            }
        }
    }
    
    func presentMediaLibraryAccessAlert() {
        let alert = UIAlertController(title: "Enable Access",
                                      message: "Please enable Media & Apple Music access in the Settings app.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        }))
        self.present(alert, animated: true)
    }
    
    @objc func pickStingFromLibrary() {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            if MPMediaLibrary.authorizationStatus() == .notDetermined {
                requestMediaLibraryAuthorization(successHandler: { self.pickStingFromLibrary() })
            } else {
                presentMediaLibraryAccessAlert()
            }
            
            return
        }
        
        #if targetEnvironment(simulator)
        // pick a random file from the file system as no library is available on the simulator
        loadRandomTrackFromHostFileSystem()
        #else
        
        // present music picker to load a track from media library
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = self
        mediaPicker.showsCloudItems = false  // hides iTunes in the Cloud items, which crash the app if picked
        mediaPicker.showsItemsWithProtectedAssets = false  // hides Apple Music items, which are DRM protected
        mediaPicker.allowsPickingMultipleItems = false
        present(mediaPicker, animated: true)
        #endif
    }
    
    @objc func pickStingFromFiles() {
        // present file picker to load a track from
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        documentPicker.delegate = self
        
        // start in the original directory if locating a sting
        if case .locate(let sting) = pickerOperation {
            documentPicker.directoryURL = sting.url.deletingLastPathComponent()
        }
        
        present(documentPicker, animated: true)
    }
    
    #if targetEnvironment(simulator)
    func loadRandomTrackFromHostFileSystem() {
        guard let sharedFiles = try? FileManager.default.contentsOfDirectory(atPath: "/Users/Shared/Music") else { return }
        
        let audioFiles = sharedFiles.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".m4a") }
        guard audioFiles.count > 0 else { fatalError() }
        let file = audioFiles[Int.random(in: 0..<audioFiles.count)]
        let url = URL(fileURLWithPath: "/Users/Shared/Music").appendingPathComponent(file)
        
        if let sting = Sting(url: url) {
            load(sting)
        }
    }
    #endif
    
    func load(_ sting: Sting) {
        switch pickerOperation {
        case .insert(let index) where index < show.stings.count:
            show.insert(sting, at: index)
            pickerOperation = .normal
        case .locate(let missingSting):
            missingSting.reloadAudio(from: sting)
            show.updateChangeCount(.done)
            reloadItems([missingSting])
            pickerOperation = .normal
        default:
            show.append(sting)
            scrollTo(sting, animated: false)
        }
    }
    
    func presentRenameDialog(for sting: Sting) {
        let alertController = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = sting.name
            textField.placeholder = sting.songTitle
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .always
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.becomeFirstResponder()     // ensure undo gestures work after a rename
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            var name = alertController.textFields?.first?.text
            if name?.isEmpty == true { name = nil }
            self.rename(sting, to: name)
            self.becomeFirstResponder()     // ensure undo gestures work after a rename
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func rename(_ sting: Sting, to name: String?) {
        let oldName = sting.name
        sting.name = name
        if sting.name != oldName {
            show.undoManager.registerUndo(withTarget: self) { _ in
                self.rename(sting, to: oldName)
            }
        }
        reloadItems([sting])
    }
    
    func change(_ sting: Sting, to color: Sting.Color) {
        let oldColor = sting.color
        sting.color = color
        if sting.color != oldColor {
            show.undoManager.registerUndo(withTarget: self) { _ in
                self.change(sting, to: oldColor)
            }
        }
        reloadItems([sting])
    }
    
    @IBAction func playSting() {
        guard let sting = cuedSting ?? show.stings.playable.first else { return }
        
        engine.play(sting)
        nextCue()
    }
    
    @IBAction func stopSting() {
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
    
    @IBAction func nextCue() {
        let playableStings = show.stings.playable
        
        guard
            playableStings.count > 1,
            let oldCue = cuedSting,
            let oldCueIndex = playableStings.firstIndex(of: oldCue)
        else { return }
        
        let newCueIndex = (oldCueIndex + 1) % playableStings.count
        let newCue = playableStings[newCueIndex]
        cuedSting = newCue
        
        reloadItems([oldCue, newCue])
    }
    
    @IBAction func previousCue() {
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
        
        reloadItems([oldCue, newCue])
    }
    
    func stingCellForItem(at indexPath: IndexPath) -> StingCell? {
        return collectionView.cellForItem(at: indexPath) as? StingCell
    }
    
    func scrollTo(_ sting: Sting, animated: Bool = true) {
        guard let indexPath = dataSource?.indexPath(for: sting) else { return }
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)
    }
    
    func updateProgress() {
        let elapsedTime = engine.elapsedTime
        let totalTime = engine.totalTime
        
        let progress = Float((elapsedTime / totalTime).truncatingRemainder(dividingBy: 1) + (1 / totalTime))
        
        if progressView.progress == 1 {
            progressView.reset()
        }
        
        progressAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            self.progressView.setProgress(progress, animated: true)
        }
        progressAnimator?.startAnimation()
        
        let timeRemaining = totalTime - elapsedTime
        if timeRemaining < 0 {
            timeRemainingLabel.text = "Looping"
        } else if let remainingString = timeRemaining.formattedAsRemaining() {
            timeRemainingLabel.text = remainingString
        }
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
        progressAnimator?.stopAnimation(true)
        
        progressView.reset()
        timeRemainingLabel.text = cuedSting?.totalTime.formattedAsRemaining()
    }
    
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let sting = dataSource?.itemIdentifier(for: indexPath) else { return }
        engine.play(sting)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: indexPath.item as NSCopying, previewProvider: nil) { suggestedActions in
            guard let sting = self.dataSource?.itemIdentifier(for: indexPath) else { return nil }
            
            let cue = UIAction(title: "Cue Next", image: UIImage(systemName: "smallcircle.fill.circle")) { action in
                let oldCue = self.cuedSting
                self.cuedSting = sting
                self.reloadItems([oldCue, sting].compactMap { $0 })
            }
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "waveform")) { action in
                self.performSegue(withIdentifier: "Edit Sting", sender: sting)
            }
            let rename = UIAction(title: "Rename", image: UIImage(systemName: "square.and.pencil")) { action in
                self.presentRenameDialog(for: sting)
            }
            var colorActions = [UIAction]()
            for color in Sting.Color.allCases {
                let image = UIImage(systemName: color == sting.color ? "checkmark.circle.fill" : "circle.fill")?.withTintColor(color.object, renderingMode: .alwaysOriginal).applyingSymbolConfiguration(UIImage.SymbolConfiguration(weight: .heavy))
                let action = UIAction(title: "\(color)".capitalized, image: image) { action in
                    self.change(sting, to: color)
                }
                colorActions.append(action)
            }
            let colorMenu = UIMenu(title: "Colour", image: UIImage(systemName: "paintbrush"), children: colorActions)
            
            let duplicate = UIAction(title: "Duplicate", image: UIImage(systemName: "plus.square.on.square")) { action in
                guard let duplicate = sting.copy() else { return }
                self.show.insert(duplicate, at: indexPath.item + 1)  // updates collection view via didSet
            }
            let insert = UIAction(title: "Insert Song Here", image: UIImage(systemName: "square.stack")) { action in
                self.pickerOperation = .insert(indexPath.item)
                self.pickStingFromLibrary()
            }
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash")) { action in
                guard sting != self.engine.playingSting else { return }
                if sting == self.cuedSting {
                    self.nextCue()
                    // remove cued sting if next cue is still the chosen sting
                    if sting == self.cuedSting { self.cuedSting = nil }
                }
                self.show.removeSting(at: indexPath.item)     // updates collection view via didSet
            }
            
            if sting == self.engine.playingSting {
                delete.attributes = .disabled
            } else {
                delete.attributes = .destructive
            }
            
            if sting.audioFile == nil {
                let songInfo = UIAction(title: "\(sting.songTitle) by \(sting.songArtist)", attributes: .disabled) { action in }
                let locate = UIAction(title: "Locate", image: UIImage(systemName: "magnifyingglass")) { action in
                    self.pickerOperation = .locate(sting)
                    if sting.url.isMediaItem {
                        self.pickStingFromLibrary()
                    } else {
                        self.pickStingFromFiles()
                    }
                }
                let editMenu = UIMenu(title: "", options: .displayInline, children: [locate, insert, delete])
                let infoMenu = UIMenu(title: "", options: .displayInline, children: [songInfo])
                return UIMenu(title: "", children: [editMenu, infoMenu])
            }
            
            let editMenu = UIMenu(title: "", options: .displayInline, children: [edit, rename, colorMenu])
            let fileMenu = UIMenu(title: "", options: .displayInline, children: [duplicate, insert, delete])
            
            if sting == self.cuedSting {
                return UIMenu(title: "", children: [editMenu, fileMenu])
            }
            
            let playMenu = UIMenu(title: "", options: .displayInline, children: [cue])
            return UIMenu(title: "", children: [playMenu, editMenu, fileMenu])
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let index = configuration.identifier as? Int else { return nil }
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else { return nil }
        return UITargetedPreview(view: cell)
    }
    
}


// MARK: UICollectionViewDragDelegate
extension PlaybackViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // drag item doesn't require any customisation as the drop delegate only needs the source/destination index paths
        return [UIDragItem(itemProvider: NSItemProvider())]
    }
}


// MARK: UICollectionViewDropDelegate
extension PlaybackViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard collectionView.hasActiveDrag else { return UICollectionViewDropProposal(operation: .forbidden) }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard
            let sourceItem = coordinator.items.first,
            let sourceIndexPath = sourceItem.sourceIndexPath,
            let destinationIndexPath = coordinator.destinationIndexPath
        else { return }
        
        show.moveSting(from: sourceIndexPath.item, to: destinationIndexPath.item)
        coordinator.drop(sourceItem.dragItem, toItemAt: destinationIndexPath)
    }
}


// MARK: MPMediaPickerControllerDelegate
extension PlaybackViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // make a sting from the selected media item, add it to the engine and update the table view
        if let sting = Sting(mediaItem: mediaItemCollection.items[0]) {
            load(sting)
        }
        
        // dismiss media picker
        dismiss(animated: true)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        pickerOperation = .normal
        dismiss(animated: true)
    }
}


// MARK: UIDocumentPickerDelegate
extension PlaybackViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let sting = Sting(url: urls[0]) {
            load(sting)
        }
    }
}


// MARK: PlaybackDelegate
extension PlaybackViewController: PlaybackDelegate {
    func stingDidStartPlaying(_ sting: Sting) {
        reloadItems([sting])
        beginUpdatingProgress()
    }
    
    func stingDidStopPlaying(_ sting: Sting) {
        DispatchQueue.main.async {
            self.reloadItems([sting])
            
            // by the time this executes another sting may have already started playback
            if self.engine.playingSting == nil { self.stopUpdatingProgress() }
        }
    }
}

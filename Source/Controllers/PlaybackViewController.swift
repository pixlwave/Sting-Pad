import UIKit
import MediaPlayer
import MobileCoreServices

class PlaybackViewController: UICollectionViewController {
    
    private let engine = Engine.shared
    var show: Show!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Sting>?
    private var cuedSting: Sting? {
        didSet { if let sting = cuedSting { scrollTo(sting) } }
    }
    
    @IBOutlet var transportView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    
    private let transportViewHeight: CGFloat = 90
    private var progressTimer: Timer?
    private var progressAnimator: UIViewPropertyAnimator?
    
    private var addStingAfterIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self delegate for sting players
        engine.playbackDelegate = self
        
        // load the transport view nib and add as a subview via it's outlet
        Bundle.main.loadNibNamed("TransportView", owner: self, options: nil)
        view.addSubview(transportView)
        progressView.progress = 0
        timeRemainingLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeRemainingLabel.font.pointSize, weight: .regular)
        
        configureDataSource()
        collectionView.register(UINib(nibName: "AddStingFooterView", bundle: nil), forSupplementaryViewOfKind: "footer", withReuseIdentifier: "AddStingFooter")
        collectionView.collectionViewLayout = createLayout()
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        // prevents scroll view from momentarily blocking the play button's action
        collectionView.delaysContentTouches = false; #warning("Test if this works or if the property needs to be set on the scroll view")
        
        NotificationCenter.default.addObserver(self, selector: #selector(addStingFromLibrary), name: .addStingFromLibrary, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(addStingFromFiles), name: .addStingFromFiles, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applySnapshot), name: .stingsDidChange, object: show)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadEditedSting(_:)), name: .didFinishEditing, object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        let origin = CGPoint(x: 0, y: view.frame.height - view.safeAreaInsets.bottom - transportViewHeight)
        let size = CGSize(width: view.frame.width, height: view.bounds.height - origin.y)
        transportView?.frame = CGRect(origin: origin, size: size)
        collectionView.contentInset.bottom = size.height
        collectionView.verticalScrollIndicatorInsets.bottom = size.height
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
            stingCell.isMissing = sting.isMissing
            stingCell.color = sting.color
            
            if sting.isMissing {
                stingCell.footerLabel.text = sting.url.isMediaItem ? "Song Missing" : "File Missing"
            } else if sting.loops, let loopImage = UIImage(systemName: "repeat") {
                let loopString = NSAttributedString(attachment: NSTextAttachment(image: loopImage))
                stingCell.footerLabel.attributedText = loopString
            } else {
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
        #warning("Is there a better way to do this?")
        let uniqueIdentifiers = Array(Set(identifiers))
        var snapshot = dataSource.snapshot()
        
        #warning("Test this and add debug notification")
        uniqueIdentifiers.forEach { sting in
            guard snapshot.itemIdentifiers.contains(sting) else {
                applySnapshot()
                return
            }
        }
        
        snapshot.reloadItems(uniqueIdentifiers)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    @objc func reloadEditedSting(_ notification: Notification) {
        guard let sting = notification.object as? Sting else { return }
        reloadItems([sting])
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
        #warning("Test if this is necessary with the GM")
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
    
    @objc func addStingFromLibrary() {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            if MPMediaLibrary.authorizationStatus() == .notDetermined {
                requestMediaLibraryAuthorization(successHandler: { self.addStingFromLibrary() })
            } else {
                presentMediaLibraryAccessAlert()
            }
            
            return
        }
        
        #if targetEnvironment(simulator)
        // pick a random file from the file system as no library is available on the simulator
        loadRandomTrackFromHostFileSystem()
        #else
        
        // present music picker to load a track from ipod
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = self
        mediaPicker.showsCloudItems = false  // hides iTunes in the Cloud items, which crash the app if picked
        mediaPicker.showsItemsWithProtectedAssets = false  // hides Apple Music items, which are DRM protected
        mediaPicker.allowsPickingMultipleItems = false
        present(mediaPicker, animated: true)
        #endif
    }
    
    @objc func addStingFromFiles() {
        // present file picker to load a track from
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeAudio as String], in: .open)
        documentPicker.delegate = self
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
            if let index = addStingAfterIndex, index < show.stings.count {
                show.insert(sting, at: index + 1)
                addStingAfterIndex = nil
            } else {
                show.append(sting)
            }
            applySnapshot()
        }
    }
    #endif
    
    func rename(_ sting: Sting) {
        let alertController = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = sting.name
            textField.placeholder = sting.songTitle
            textField.autocapitalizationType = .words
            textField.clearButtonMode = .always
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            guard let name = alertController.textFields?.first?.text else { return }
            sting.name = name.isEmpty == false ? name : nil
            self.show.updateChangeCount(.done)
            self.reloadItems([sting])
        }))
        present(alertController, animated: true, completion: nil)
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
        progressAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            self.progressView.setProgress(Float((self.engine.elapsedTime + 1) / self.engine.totalTime), animated: true)
        }
        progressAnimator?.startAnimation()
        
        if let remainingString = engine.remainingTime.formattedAsRemaining() {
            timeRemainingLabel.text = remainingString
        }
    }
    
    func beginUpdatingProgress() {
        if progressTimer?.isValid == true {
            stopUpdatingProgress()
        }
        
        // reset progress view without animation
        progressView.progress = 0
        progressView.layoutIfNeeded()
        
        updateProgress()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateProgress()
        }
    }
    
    func stopUpdatingProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
        progressAnimator?.stopAnimation(true)
        
        progressView.setProgress(0, animated: false)
        timeRemainingLabel.text = cuedSting?.totalTime.formattedAsRemaining()
    }
    
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let sting = dataSource?.itemIdentifier(for: indexPath) else { return }
        engine.play(sting)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            guard let sting = self.dataSource?.itemIdentifier(for: indexPath) else { return nil }
            
            let cue = UIAction(title: "Cue Next", image: UIImage(systemName: "pause.circle")) { action in
                let oldCue = self.cuedSting
                self.cuedSting = sting
                self.reloadItems([oldCue, sting].compactMap { $0 })
            }
            let edit = UIAction(title: "Edit", image: UIImage(systemName: "waveform")) { action in
                self.performSegue(withIdentifier: "Edit Sting", sender: sting)
            }
            let rename = UIAction(title: "Rename", image: UIImage(systemName: "square.and.pencil")) { action in
                self.rename(sting)
            }
            var colorActions = [UIAction]()
            for color in Color.allCases {
                let image = UIImage(systemName: color == sting.color ? "checkmark.circle.fill" : "circle.fill")?.withTintColor(color.value, renderingMode: .alwaysOriginal).applyingSymbolConfiguration(UIImage.SymbolConfiguration(weight: .heavy))
                let action = UIAction(title: "\(color)".capitalized, image: image) { action in
                    sting.color = color
                    self.show.updateChangeCount(.done)
                    self.reloadItems([sting])
                }
                colorActions.append(action)
            }
            let colorMenu = UIMenu(title: "Colour", image: UIImage(systemName: "paintbrush"), children: colorActions)
            
            let duplicate = UIAction(title: "Duplicate", image: UIImage(systemName: "plus.square.on.square")) { action in
                guard let duplicate = sting.copy() else { return }
                self.show.insert(duplicate, at: indexPath.item + 1)  // updates collection view via didSet
            }
            let insert = UIAction(title: "Insert After", image: UIImage(systemName: "square.stack")) { action in
                self.addStingAfterIndex = indexPath.item
                self.addStingFromLibrary()
            }
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash")) { action in
                guard sting != self.engine.playingSting else { return }
                if sting == self.cuedSting { self.cuedSting = nil }
                self.show.removeSting(at: indexPath.item)     // updates collection view via didSet
            }
            
            if sting == self.engine.playingSting {
                delete.attributes = .disabled
            } else {
                delete.attributes = .destructive
            }
            
            if sting.isMissing {
                let songInfo = UIAction(title: "\(sting.songTitle) by \(sting.songArtist)", attributes: .disabled) { action in }
                return UIMenu(title: "", children: [delete, UIMenu(title: "", options: .displayInline, children: [songInfo])])
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
    
}


// MARK: UICollectionViewDragDelegate
extension PlaybackViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // drag item doesn't require any customisation as the drop delegate only needs the source/destination index paths
        return [UIDragItem(itemProvider: NSItemProvider())]
    }
    
    #warning("Add itemsForAddingTo when testing on device, and handle multiple drops")
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
        
        show.insert(show.removeSting(at: sourceIndexPath.item), at: destinationIndexPath.item)
        applySnapshot()
        coordinator.drop(sourceItem.dragItem, toItemAt: destinationIndexPath)
    }
}


// MARK: MPMediaPickerControllerDelegate
extension PlaybackViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // make a sting from the selected media item, add it to the engine and update the table view
        if let sting = Sting(mediaItem: mediaItemCollection.items[0]) {
            if let index = addStingAfterIndex, index < show.stings.count {
                show.insert(sting, at: index + 1)
                addStingAfterIndex = nil
            } else {
                show.append(sting)
            }
            
            applySnapshot()
            scrollTo(sting, animated: false)
        }
        
        // dismiss media picker
        dismiss(animated: true)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        addStingAfterIndex = nil
        dismiss(animated: true)
    }
}


// MARK: UIDocumentPickerDelegate
extension PlaybackViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let sting = Sting(url: urls[0]) {
            show.append(sting)
            applySnapshot()
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

import UIKit
import MediaPlayer
import MobileCoreServices

class PlaybackViewController: UICollectionViewController {
    
    private let engine = Engine.shared
    lazy private var dataSource = makeDataSource()
    private var cuedStingIndex = 0; #warning("Should this be optional?")
    
    @IBOutlet var transportView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    private let transportViewHeight: CGFloat = 90
    private var timeTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self delegate for sting players
        engine.playbackDelegate = self
        
        // load the transport view nib and add as a subview via it's outlet
        Bundle.main.loadNibNamed("TransportView", owner: self, options: nil)
        view.addSubview(transportView)
        #warning("Symbol config would be better in the storyboard if possible")
        playButton.setPreferredSymbolConfiguration(.init(pointSize: 52, weight: .thin, scale: .large), forImageIn: .normal)
        stopButton.setPreferredSymbolConfiguration(.init(pointSize: 52, weight: .thin, scale: .medium), forImageIn: .normal)
        previousButton.setPreferredSymbolConfiguration(.init(pointSize: 52, weight: .thin, scale: .small), forImageIn: .normal)
        nextButton.setPreferredSymbolConfiguration(.init(pointSize: 52, weight: .thin, scale: .small), forImageIn: .normal)
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeLabel.font.pointSize, weight: .regular)
        
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        // prevents scroll view from momentarily blocking the play button's action
        collectionView.delaysContentTouches = false; #warning("Test if this works or if the property needs to be set on the scroll view")
        
        NotificationCenter.default.addObserver(self, selector: #selector(applySnapshot), name: .stingsDidChange, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.double(forKey: "WelcomeVersionSeen") < WelcomeViewController.currentVersion {
            showWelcomeScreen()
        }
    }
    
    override func viewWillLayoutSubviews() {
        let origin = CGPoint(x: 0, y: view.frame.height - view.safeAreaInsets.bottom - transportViewHeight)
        let size = CGSize(width: view.frame.width, height: transportViewHeight)
        transportView?.frame = CGRect(origin: origin, size: size)
        collectionView.contentInset.bottom = size.height
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Edit Sting" {
            guard
                let navigationVC = segue.destination as? UINavigationController,
                let stingVC = navigationVC.topViewController as? StingViewController,
                let indexPath = sender as? IndexPath
            else { return }
            
            stingVC.stingIndex = indexPath.row
        }
    }
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(120))
            let minimumWidth: CGFloat = 300
            let count = Int(layoutEnvironment.container.effectiveContentSize.width / minimumWidth)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = item.contentInsets
            
            return section
        }
    }
    
    func makeDataSource() -> UICollectionViewDiffableDataSource<Int, Sting> {
        return UICollectionViewDiffableDataSource<Int, Sting>(collectionView: collectionView) { collectionView, indexPath, sting -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Sting Cell", for: indexPath)
            
            guard let stingCell = cell as? StingCell else { return cell }
            
            stingCell.titleLabel.text = sting.name ?? sting.songTitle
            stingCell.isCued = indexPath.item == self.cuedStingIndex
            stingCell.isPlaying = sting == self.engine.currentSting
            
            return stingCell
        }
    }
    
    #warning("Implement more efficient responses to changed data.")
    @objc func applySnapshot() {
        let snapshot = NSDiffableDataSourceSnapshot<Int, Sting>()
        snapshot.appendSections([0])
        snapshot.appendItems(engine.show.stings)
        dataSource.apply(snapshot)
    }
    
    func reloadItems(_ identifiers: [Sting]) {
        let snapshot = dataSource.snapshot()
        snapshot.reloadItems(identifiers)
        dataSource.apply(snapshot)
    }
    
    func showWelcomeScreen() {
        // instantiate welcome controller and present
        let walkSB = UIStoryboard(name: "Welcome", bundle: nil)
        if let walkVC = walkSB.instantiateViewController(withIdentifier: "Welcome") as? WelcomeViewController {
            walkVC.modalTransitionStyle = .crossDissolve
            present(walkVC, animated:true, completion:nil)
            
            // record the version being seen to allow ui updates to be shown in future versions
            UserDefaults.standard.set(WelcomeViewController.currentVersion, forKey: "WelcomeVersionSeen")
        }
    }
    
    @IBAction func newShow() {
        let alert = UIAlertController(title: "New Show?",
                                      message: "Are you sure you would like to start a new show? This will delete any unsaved changes.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { action in
            self.engine.newShow()   // reloads via notification
        })
        
        present(alert, animated: true)
    }
    
    func loadTrack() {
        // present music picker to load a track from ipod
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = self
        mediaPicker.showsCloudItems = false  // hides iTunes in the Cloud items, which crash the app if picked
        mediaPicker.showsItemsWithProtectedAssets = false  // hides Apple Music items, which are DRM protected
        mediaPicker.allowsPickingMultipleItems = false
        present(mediaPicker, animated: true)
    }
    
    func loadTrackFromFile() {
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
            engine.add(sting)
            applySnapshot()
        }
    }
    #endif
    
    @IBAction func addSting() {
        #if targetEnvironment(simulator)
            // pick a random file from the documents directory until iOS 13 syncs iCloud drive
            loadRandomTrackFromHostFileSystem()
        #else
            // load the track with a media picker
            loadTrack()
        #endif
    }
    
    func renameSting(at index: Int) {
        let sting = engine.show.stings[index]
        
        let alertController = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in textField.text = sting.name }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            guard let name = alertController.textFields?.first?.text else { return }
            sting.name = name.isEmpty == false ? name : nil
            self.engine.show.updateChangeCount(.done)
            self.reloadItems([sting])
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func playSting() {
        guard cuedStingIndex < engine.show.stings.count else { return }
        
        engine.playSting(at: cuedStingIndex)
        nextSting()
    }
    
    @IBAction func stopSting() {
        engine.stopSting()
    }
    
    @IBAction func nextSting() {
        guard engine.show.stings.count > 0 else { return }
        
        let oldCue = engine.show.stings[cuedStingIndex]
        cuedStingIndex = (cuedStingIndex + 1) % engine.show.stings.count
        let newCue = engine.show.stings[cuedStingIndex]
        
        reloadItems([oldCue, newCue])
    }
    
    @IBAction func previousSting() {
        guard engine.show.stings.count > 0 else { return }
        
        if cuedStingIndex > 0 {
            let oldCue = engine.show.stings[cuedStingIndex]
            cuedStingIndex = cuedStingIndex - 1 % engine.show.stings.count
            let newCue = engine.show.stings[cuedStingIndex]
            
            reloadItems([oldCue, newCue])
        }
    }
    
    func stingCellForItem(at indexPath: IndexPath) -> StingCell? {
        return collectionView.cellForItem(at: indexPath) as? StingCell
    }
    
    func updateTimeLabel() {
        guard let remainingString = engine.remainingTime.formatted() else { return }
        timeLabel.text = remainingString
    }
    
    func beginUpdatingTime() {
        if timeTimer?.isValid == true {
            stopUpdatingTime()
        }
        
        updateTimeLabel()
        timeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateTimeLabel()
        }
    }
    
    func stopUpdatingTime() {
        timeTimer?.invalidate()
        timeTimer = nil
    }
    
    
    // MARK: UICollectionViewDataDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        engine.playSting(at: indexPath.item)
    }
    
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return indexPath.item < engine.show.stings.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        engine.show.stings.insert(engine.show.stings.remove(at: sourceIndexPath.item), at: destinationIndexPath.item)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let rename = UIAction(__title: "Rename", image: UIImage(systemName: "square.and.pencil"), identifier: nil) { action in
                self.renameSting(at: indexPath.item)
            }
            let edit = UIAction(__title: "Edit", image: UIImage(systemName: "waveform"), identifier: nil) { action in
                self.performSegue(withIdentifier: "Edit Sting", sender: indexPath)
            }
            let duplicate = UIAction(__title: "Duplicate", image: UIImage(systemName: "plus.square.on.square"), identifier: nil) { action in
                guard let duplicate = self.engine.show.stings[indexPath.item].copy() else { return }
                self.engine.show.stings.insert(duplicate, at: indexPath.item + 1)
                self.applySnapshot()
            }
            let delete = UIAction(__title: "Delete", image: UIImage(systemName: "minus.circle.fill"), identifier: nil) { action in
                self.engine.show.stings.remove(at: indexPath.item)
                self.applySnapshot()
            }
            delete.attributes = .destructive
            
            // Create and return a UIMenu with the share action
            return UIMenu(__title: "", image: nil, identifier: nil, children: [rename, edit, duplicate, delete])
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
        if let desinationIndexPath = coordinator.destinationIndexPath, let sourceIndexPath = coordinator.items.first?.sourceIndexPath {
            engine.show.stings.insert(engine.show.stings.remove(at: sourceIndexPath.item), at: desinationIndexPath.item)
            applySnapshot()
        }
    }
}


// MARK: MPMediaPickerControllerDelegate
extension PlaybackViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // make a sting from the selected media item, add it to the engine and update the table view
        if let sting = Sting(mediaItem: mediaItemCollection.items[0]) {
            engine.add(sting)
            applySnapshot()
        }
        
        // dismiss media picker
        dismiss(animated: true)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        // dismiss media picker
        dismiss(animated: true)
    }
    
}


// MARK: UIDocumentPickerDelegate
extension PlaybackViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let sting = Sting(url: urls[0]) {
            engine.add(sting)
            applySnapshot()
        }
        
        // dismiss document picker
        dismiss(animated: true)
    }
}


// MARK: PlaybackDelegate
extension PlaybackViewController: PlaybackDelegate {
    func stingDidStartPlaying(_ sting: Sting) {
        reloadItems([sting])
        beginUpdatingTime()
    }
    
    func stingDidStopPlaying(_ sting: Sting) {
        DispatchQueue.main.async {
            self.reloadItems([sting])
            
            // this may be run after another sting has already started playback
            if self.engine.currentSting == nil { self.stopUpdatingTime() }
        }
    }
}

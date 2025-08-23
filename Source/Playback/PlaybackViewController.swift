import UIKit
import MediaPlayer
import MobileCoreServices
import SwiftUI
import os.log

class PlaybackViewController: UICollectionViewController {
    var viewModel: PlaybackViewModel!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Sting>?
    
    @IBOutlet weak var manageStingsButton: UIBarButtonItem!
    var transportController: UIHostingController<TransportView>!
    
    private let transportViewHeight: CGFloat = 90
    
    private var cuedStingTask: Task<Void, Never>?
    
    // respond to undo gestures, forwarding them to the show's undo manager
    override var canBecomeFirstResponder: Bool { true }
    override var undoManager: UndoManager? { viewModel.show.undoManager }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let transportView = TransportView(model: viewModel.transportModel) { [weak self] action in
            guard let self else { return }
            switch action {
            case .play: viewModel.playSting()
            case .stop: viewModel.stopSting()
            case .next: viewModel.nextCue()
            case .previous: viewModel.previousCue()
            }
        }
        transportController = UIHostingController(rootView: transportView)
        transportController.view.backgroundColor = .clear
        addChild(transportController)
        transportController.didMove(toParent: self)
        view.addSubview(transportController.view)
        transportController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            transportController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            transportController.view.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        configureDataSource()
        collectionView.register(UINib(nibName: "AddStingFooterView", bundle: nil), forSupplementaryViewOfKind: "footer", withReuseIdentifier: "AddStingFooter")
        collectionView.collectionViewLayout = createLayout()
        collectionView.dragInteractionEnabled = true
        
        let cuedStingObservations = Observations { [viewModel] in viewModel.cuedSting }
        cuedStingTask = Task { [weak self] in
            for await sting in cuedStingObservations {
                guard let sting else { continue }
                self?.scrollTo(sting)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(addStingFromLibrary), name: .addStingFromLibrary, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(addStingFromFiles), name: .addStingFromFiles, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didAppendSting(_:)), name: .didAppendSting, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applySnapshot), name: .stingsDidChange, object: viewModel.show)
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishEditing), name: .didFinishEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showStateChanged(_:)), name: UIDocument.stateChangedNotification, object: viewModel.show)
        NotificationCenter.default.addObserver(self, selector: #selector(updateManageStingsButtonVisibility), name: .unavailableStingsDidChange, object: nil)
        
        manageStingsButton.image = manageStingsButton.image?.withConfiguration(UIImage.SymbolConfiguration(weight: .semibold))
        updateManageStingsButtonVisibility()
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
        let bottomInset = 8 + transportViewHeight
        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
    
    @IBSegueAction func editStingSegue(_ coder: NSCoder, sender: Any?) -> UIViewController? {
        guard let sting = sender as? Sting else { return nil }
        
        let view = EditStingView(show: viewModel.show, sting: sting, dismiss: { self.dismiss(animated: true) })
        return HostingController(coder: coder, rootView: view, show: viewModel.show)
    }
    
    @IBSegueAction func manageStingsSegue(_ coder: NSCoder) -> UIViewController? {
        let view = ManageStingsView(show: viewModel.show, dismiss: { self.dismiss(animated: true) })
        return UIHostingController(coder: coder, rootView: view)
    }
    
    @IBSegueAction func settingsSegue(_ coder: NSCoder) -> UIViewController? {
        let view = SettingsView(show: viewModel.show, dismiss: { self.dismiss(animated: true) })
        return UIHostingController(coder: coder, rootView: view)
    }
    
    @objc func showStateChanged(_ notification: Notification) {
        os_log("Show State Changed: %d", log: .default, type: .debug, viewModel.show.documentState.rawValue)
    }
    
    @IBAction func closeShow() {
        // stop listening for notifications in case a new show is opened before this gets deallocated
        NotificationCenter.default.removeObserver(self)
        
        cuedStingTask?.cancel()
        cuedStingTask = nil
        
        Task {
            await viewModel.closeShow()
            (self.presentingViewController as? ShowBrowserViewController)?.isLoading = false
            self.dismiss(animated: true)
            
            // set data source to nil to remove reference cycle
            dataSource = nil
        }
    }
    
    // MARK: Collection View
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
            cell.contentConfiguration = UIHostingConfiguration {
                StingCell(sting: sting, viewModel: self.viewModel)
            }
            .margins(.all, 0)
            
            return cell
        }
        
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "AddStingFooter", for: indexPath)
        }
    }
    
    @objc func applySnapshot() {
        // ensure there's a cued sting if possible
        viewModel.validateCuedSting()
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, Sting>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.show.stings)
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
    
    @objc func didFinishEditing() {
        becomeFirstResponder()  // ensure undo works again
    }
    
    func scrollTo(_ sting: Sting, animated: Bool = true) {
        guard let indexPath = dataSource?.indexPath(for: sting) else { return }
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)
    }
    
    // MARK: Editing
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
        pickStingFromLibrary(pickerOperation: .normal)
    }
    
    func pickStingFromLibrary(pickerOperation: PickerOperation) {
        guard MPMediaLibrary.authorizationStatus() == .authorized else {
            if MPMediaLibrary.authorizationStatus() == .notDetermined {
                requestMediaLibraryAuthorization(successHandler: { self.pickStingFromLibrary(pickerOperation: pickerOperation) })
            } else {
                presentMediaLibraryAccessAlert()
            }
            
            return
        }
        
        #if targetEnvironment(simulator)
        // pick a random file from the file system as no library is available on the simulator
        Task { await loadRandomTrackFromHostFileSystem() }
        #else
        
        let hostedSongPicker = UIHostingController(rootView: SongPicker(show: show, pickerOperation: pickerOperation))
        present(hostedSongPicker, animated: true)
        #endif
    }
    
    @objc func addStingFromFiles() {
        pickStingFromFiles(pickerOperation: .normal)
    }
    
    func pickStingFromFiles(pickerOperation: PickerOperation) {
        let hostedFilePicker = UIHostingController(rootView: FilePicker(show: viewModel.show, pickerOperation: pickerOperation))
        present(hostedFilePicker, animated: true)
    }
    
    #if targetEnvironment(simulator)
    func loadRandomTrackFromHostFileSystem() async {
        guard let sharedFiles = try? FileManager.default.contentsOfDirectory(atPath: "/Users/Shared/Music") else { return }
        
        let audioFiles = sharedFiles.filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".m4a") }
        guard audioFiles.count > 0 else { fatalError() }
        let file = audioFiles[Int.random(in: 0..<audioFiles.count)]
        let url = URL(fileURLWithPath: "/Users/Shared/Music").appendingPathComponent(file)
        
        if let sting = await Sting(url: url) {
            PickerCoordinator(show: viewModel.show, pickerOperation: .normal).load(sting)
        }
    }
    #endif
    
    @objc func didAppendSting(_ notification: Notification) {
        guard let sting = notification.object as? Sting else { return }
        scrollTo(sting, animated: false)
    }
    
    @objc func updateManageStingsButtonVisibility() {
        guard let manageStingsButton = manageStingsButton else { return }
        
        if viewModel.show.unavailableSongs.isEmpty && viewModel.show.unavailableFiles.isEmpty {
            navigationItem.rightBarButtonItems?.removeAll{ $0 == manageStingsButton }
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
            self.viewModel.rename(sting, to: name)
            self.becomeFirstResponder()     // ensure undo gestures work after a rename
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let sting = dataSource?.itemIdentifier(for: indexPath) else { return }
        viewModel.engine.play(sting)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: indexPath.item as NSCopying, previewProvider: nil) { suggestedActions in
            guard let sting = self.dataSource?.itemIdentifier(for: indexPath) else { return nil }
            
            let cue = UIAction(title: "Cue Next", image: UIImage(systemName: "smallcircle.fill.circle")) { action in
                self.viewModel.cuedSting = sting
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
                    self.viewModel.change(sting, to: color)
                }
                colorActions.append(action)
            }
            let colorMenu = UIMenu(title: "Colour", image: UIImage(systemName: "paintbrush"), children: colorActions)
            
            let duplicate = UIAction(title: "Duplicate", image: UIImage(systemName: "plus.square.on.square")) { action in
                self.viewModel.copy(sting, to: indexPath.item + 1)
            }
            let insert = UIAction(title: "Insert Song Here", image: UIImage(systemName: "square.stack")) { action in
                self.pickStingFromLibrary(pickerOperation: .insert(indexPath.item))
            }
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash")) { action in
                self.viewModel.delete(sting, at: indexPath.item)
            }
            
            if sting == self.viewModel.engine.playingSting {
                delete.attributes = .disabled
            } else {
                delete.attributes = .destructive
            }
            
            if sting.audioFile == nil {
                let songInfo = UIAction(title: "\(sting.songTitle) by \(sting.songArtist)", attributes: .disabled) { action in }
                let locate = UIAction(title: "Locate", image: UIImage(systemName: "magnifyingglass")) { action in
                    if sting.url.isMediaItem {
                        self.pickStingFromLibrary(pickerOperation: .locate(sting))
                    } else {
                        self.pickStingFromFiles(pickerOperation: .locate(sting))
                    }
                }
                let editMenu = UIMenu(title: "", options: .displayInline, children: [locate, insert, delete])
                let infoMenu = UIMenu(title: "", options: .displayInline, children: [songInfo])
                return UIMenu(title: "", children: [editMenu, infoMenu])
            }
            
            let editMenu = UIMenu(title: "", options: .displayInline, children: [edit, rename, colorMenu])
            let fileMenu = UIMenu(title: "", options: .displayInline, children: [duplicate, insert, delete])
            
            if sting == self.viewModel.cuedSting {
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
        
        viewModel.show.moveSting(from: sourceIndexPath.item, to: destinationIndexPath.item)
        coordinator.drop(sourceItem.dragItem, toItemAt: destinationIndexPath)
    }
}

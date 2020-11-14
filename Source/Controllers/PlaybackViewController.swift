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
        
        NotificationCenter.default.addObserver(self, selector: #selector(applySnapshot), name: .stingsDidChange, object: show)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadEditedSting(_:)), name: .didFinishEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showStateChanged(_:)), name: UIDocument.stateChangedNotification, object: show)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()  // respond to undo gestures
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
                stingCell.footerLabel.text = sting.url.isMediaItem ? "Song Missing" : "File Missing"
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
//        validateCuedSting()
        
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
        engine.stopSting()
        show.close { success in
            (self.presentingViewController as? ShowBrowserViewController)?.isLoading = false
            self.dismiss(animated: true)
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
//            self.rename(sting, to: name)
            self.becomeFirstResponder()     // ensure undo gestures work after a rename
        }))
        
        present(alertController, animated: true, completion: nil)
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
    
    // re-uses cell so it reacts to changes
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

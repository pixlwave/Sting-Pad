import UIKit

class SongCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumArtImageView: UIImageView!
    
    var isPlaying = false {
        didSet {
            // color the labels orange (slightly darker than the main orange for balance)
            if isPlaying {
                titleLabel.textColor = UIColor(hue: 30/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
                artistLabel.textColor = UIColor(hue: 34/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
            } else {
                titleLabel.textColor = UIColor.darkText
                artistLabel.textColor = UIColor.darkText
            }
        }
    }
}

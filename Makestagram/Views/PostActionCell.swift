//
//  PostActionCell.swift
//  Makestagram
//
//  Created by Scott P. Chow on 6/10/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import UIKit

protocol PostActionCellDelegate: class {
    func didTapLikeButton(_ likeButton: UIButton, on cell: PostActionCell)
}

class PostActionCell: UITableViewCell {
    // Mark - Properties
    static let height: CGFloat = 46
    weak var delegate: PostActionCellDelegate?
    
    // MARK - Subviews
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    // MARK - Cell lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // MARK - IBActions
    @IBAction func likeButtonTouchUpInside(_ sender: Any) {
        delegate?.didTapLikeButton(likeButton, on: self)
    }

}


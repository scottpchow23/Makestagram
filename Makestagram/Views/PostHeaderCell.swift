//
//  PostHeaderCell.swift
//  Makestagram
//
//  Created by Scott P. Chow on 6/10/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import UIKit

class PostHeaderCell: UITableViewCell {
    
    static let height: CGFloat = 54

    @IBOutlet weak var usernameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func optionsButtonTouchUpInside(_ sender: Any) {
        print("options button tapped")
    }

}

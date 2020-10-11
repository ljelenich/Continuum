//
//  PostTableViewCell.swift
//  Continuum
//
//  Created by LAURA JELENICH on 10/6/20.
//  Copyright © 2020 trevorAdcock. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
    
    //MARK: - Outlets
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    //MARK: - Properties
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    //MARK: - Helper Functions
    func updateViews() {
        postImageView.image = post?.photo
        captionLabel.text = post?.caption
        commentCountLabel.text = "\(post?.comments.count ?? 0)"
    }
}

//
//  HomeViewController.swift
//  Makestagram
//
//  Created by Scott P. Chow on 6/9/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import UIKit
import Kingfisher

class HomeViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    let paginationHelper = MGPaginationHelper<Post>(serviceMethod: UserService.timeline)
    let refreshControl = UIRefreshControl()
    var posts = [Post]()
    let timestampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
            return dateFormatter
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        reloadTimeline()

        // Do any additional setup after loading the view.
    }

    func reloadTimeline() {
        self.paginationHelper.reloadData { [unowned self] (posts) in
            self.posts = posts
            
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            self.tableView.reloadData()
        }
    }
    
    func configureTableView() {
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        refreshControl.addTarget(self, action: #selector(reloadTimeline), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }

}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section >= posts.count - 1 {
            paginationHelper.paginate(completion: { [unowned self] (posts) in
                self.posts.append(contentsOf: posts)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return posts.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        switch indexPath.row {
        case 0:
            let cell : PostHeaderCell = tableView.dequeueReusableCell()
            cell.usernameLabel.text = post.poster.username
            return cell
        case 1:
            let cell : PostImageCell = tableView.dequeueReusableCell()
            let imageURL = URL(string: post.imageURL)
            cell.postImageView.kf.setImage(with: imageURL)
            return cell
        case 2:
            let cell : PostActionCell = tableView.dequeueReusableCell()
            cell.delegate = self
            configureCell(cell, with: post)
            return cell
        default:
            fatalError("Error: unexpected indexPath.")
        }
    }
    
    func configureCell(_ cell: PostActionCell, with post: Post) {
        cell.timeLabel.text = timestampFormatter.string(from: post.creationDate)
        cell.likeButton.isSelected = post.isLiked
        cell.likesLabel.text = "\(post.likeCount) Likes"
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return PostHeaderCell.height
        case 1:
            let post = posts[indexPath.section]
            return post.imageHeight
        case 2:
            return PostActionCell.height
        default:
            fatalError("Error: unexpected indexPath.")
        }
    }
}

extension HomeViewController: PostActionCellDelegate {
    func didTapLikeButton(_ likeButton: UIButton, on cell: PostActionCell) {
        guard let indexPath = tableView.indexPath(for: cell)
            else { return }
        likeButton.isUserInteractionEnabled = false
        let post = posts[indexPath.section]
        LikeService.setLiked(!post.isLiked, for: post) { (success) in
            defer {
                likeButton.isUserInteractionEnabled = true
            }
            guard success else { return }
            
            post.likeCount += !post.isLiked ? 1 : -1
            post.isLiked = !post.isLiked
            
            guard let cell = self.tableView.cellForRow(at: indexPath) as? PostActionCell
                else { return }
            DispatchQueue.main.async {
                self.configureCell(cell, with: post)
            }
        }
    }
}

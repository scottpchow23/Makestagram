//
//  ProfileViewController.swift
//  Makestagram
//
//  Created by Scott P. Chow on 6/11/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ProfileViewController: UIViewController {

    var user: User!
    var posts = [Post]()
    
    var profileHandle: DatabaseHandle = 0
    var profileRef: DatabaseReference?
    
    var authHandle: AuthStateDidChangeListenerHandle?
    
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        user = user ?? User.current
        navigationItem.title = user.username
        
        profileHandle = UserService.observeProfile(for: user, completion: { [unowned self](ref, user, posts) in
            self.profileRef = ref
            self.user = user
            self.posts = posts
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        })
        
        authHandle = Auth.auth().addStateDidChangeListener({ [unowned self] (auth, user) in
            guard user == nil else { return }
            let loginViewController = UIStoryboard.instantiateInitialViewController(for: .login)
            self.view.window?.rootViewController = loginViewController
            self.view.window?.makeKeyAndVisible()
        })
    }
    
    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
        
        profileRef?.removeObserver(withHandle: profileHandle)
    }

}

extension ProfileViewController: ProfileHeaderViewDelegate {
    func didTapSettingsButton(_ button: UIButton, on headerView: ProfileHeaderView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let signOutAction = UIAlertAction(title: "Sign Out", style: .default) { (_) in
            do {
                try Auth.auth().signOut()
            } catch let error as NSError {
                assertionFailure("Error signing out: \(error.localizedDescription)")
            }
        }
        alertController.addAction(signOutAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

extension ProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader else {
            fatalError("Unexpected element kind.")
        }
        
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ProfileHeaderView", for: indexPath) as! ProfileHeaderView
        
        let postCount = user.postCount ?? 0
        headerView.postCountLabel.text = "\(postCount)"
        let followerCount = user.followerCount ?? 0
        headerView.followerCountLabel.text = "\(followerCount)"
        let followingCount = user.followingCount ?? 0
        headerView.followingCountLabel.text = "\(followingCount)"
        
        headerView.delegate = self
        
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostThumbImageCell", for: indexPath) as! PostThumbImageCell
        let post = posts[indexPath.row]
        let imageURL = URL(string: post.imageURL)
        cell.thumbImageView.kf.setImage(with: imageURL)
        
        return cell
    }
}

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 3
        let spacing: CGFloat = 1.5
        let totalHorizontalSpacing = (columns - 1) * spacing
        let itemWidth = (collectionView.bounds.size.width - totalHorizontalSpacing) / columns
        let itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        return itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.5
    }
    
}

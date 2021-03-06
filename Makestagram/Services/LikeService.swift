//
//  LikeService.swift
//  Makestagram
//
//  Created by Scott P. Chow on 6/10/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct LikeService {
    static func create(for post: Post, success: @escaping (Bool) -> Void) {
        guard let key = post.key else {
            return success(false)
        }
        let currentUID = User.current.uid
        
        let likesRef = DatabaseReference.toLocation(.likes(postKey: key, currentUID:
            currentUID))
        likesRef.setValue(true) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return success(false)
            }
            
            let likeCountRef = DatabaseReference.toLocation(.likesCount(posterUID: post.poster.uid, postKey: key))
            likeCountRef.runTransactionBlock ({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                
                mutableData.value = currentCount + 1
                return TransactionResult.success(withValue: mutableData)
            }, andCompletionBlock: { (error, _, _) in
                if let error = error {
                    print(error.localizedDescription)
                    success(false)
                } else {
                    success(true)
                }
            })
        }
        
        
    }
    
    static func delete(for post: Post, success: @escaping (Bool) -> Void) {
        guard let key = post.key else {
            return success(false)
        }
        let currentUID = User.current.uid
        let likesRef = DatabaseReference.toLocation(.likes(postKey: key, currentUID: currentUID))
        likesRef.setValue(nil) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return success(false)
            }
            let likesCountRef = DatabaseReference.toLocation(.likesCount(posterUID: post.poster.uid, postKey: key))
            likesCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                mutableData.value = currentCount - 1
                return TransactionResult.success(withValue: mutableData)
            }) { (error, _, _) in
                if let error = error {
                    print(error.localizedDescription)
                    return success(false)
                }
                return success(true)
            }
        }
        
    }
    
    static func isPostLiked(_ post: Post, byCurrentUserWithCompletion completion: @escaping (Bool) -> Void) {
        guard let postKey = post.key else {
            assertionFailure("Error: post must key")
            return completion(false)
        }
        let likesRef = Database.database().reference().child("postLikes").child(postKey)
        likesRef.queryStarting(atValue: nil, childKey: User.current.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? [String :Bool] {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    static func setLiked(_ isLiked: Bool, for post: Post, success: @escaping (Bool)->Void) {
        if isLiked {
            create(for: post, success: success)
        } else {
            delete(for: post, success: success)
        }
    }
}

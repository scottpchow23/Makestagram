//
//  FollowService.swift
//  Makestagram
//
//  Created by Scott P. Chow on 6/10/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct FollowSerivce {
    
    private static func followUser(_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let followData = ["followers/\(user.uid)/\(currentUID)" : true,
                          "following/\(currentUID)/\(user.uid)" : true]
        
        let ref = Database.database().reference()
        ref.updateChildValues(followData) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
            }
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            let followingCountRef = DatabaseReference.toLocation(.showUser(uid: currentUID)).child("following_count")
            followingCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                mutableData.value = currentCount + 1
                
                return TransactionResult.success(withValue: mutableData)
            })
            
            dispatchGroup.enter()
            
            let followerCountRef = DatabaseReference.toLocation(.showUser(uid: currentUID)).child("follower_count")
            followerCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                mutableData.value = currentCount + 1
                
                return TransactionResult.success(withValue: mutableData)
            })
            
            dispatchGroup.enter()
            UserService.posts(for: user, completion: { (posts) in
                let postKeys = posts.flatMap{ $0.key }
                
                var followData = [String : Any]()
                let timelinePostDict = ["poster_uid" : user.uid]
                postKeys.forEach{ followData["timeline/\(currentUID)/\($0)"] = timelinePostDict }
                
                ref.updateChildValues(followData, withCompletionBlock: { (error, _) in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                    }
                    dispatchGroup.leave()
                    success(error == nil)
                })
            })
            
            dispatchGroup.notify(queue: .main, execute: { 
                success(true)
            })
        }
    }
    
    private static func unfollowUser (_ user: User, forCurrentUserWithSuccess success: @escaping (Bool) -> Void) {
        let currentUID = User.current.uid
        let followData = ["followers/\(user.uid)/\(currentUID)" : NSNull(),
                          "following/\(currentUID)/\(user.uid)" : NSNull()]
        let ref = Database.database().reference()
        ref.updateChildValues(followData) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
            }
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            let followingCountRef = DatabaseReference.toLocation(.showUser(uid: currentUID)).child("following_count")
            followingCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                mutableData.value = currentCount - 1
                
                return TransactionResult.success(withValue: mutableData)
            })
            
            dispatchGroup.enter()
            
            let followerCountRef = DatabaseReference.toLocation(.showUser(uid: currentUID)).child("follower_count")
            followerCountRef.runTransactionBlock({ (mutableData) -> TransactionResult in
                let currentCount = mutableData.value as? Int ?? 0
                mutableData.value = currentCount - 1
                
                return TransactionResult.success(withValue: mutableData)
            })
            
            dispatchGroup.enter()
            
            UserService.posts(for: user, completion: { (posts) in
                let postKeys = posts.flatMap{ $0.key }
                
                var unfollowData = [String : Any]()
                postKeys.forEach{ unfollowData["timeline/\(currentUID)/\($0)"] = NSNull() }
                
                ref.updateChildValues(unfollowData, withCompletionBlock: { (error, _) in
                    if let error = error {
                        assertionFailure(error.localizedDescription)
                    }
                    dispatchGroup.leave()
                    success(error == nil)
                })
            })
            dispatchGroup.notify(queue: .main, execute: {
                success(true)
            })
        }
    }
    
    static func setIsFollowing(_ isFollowing: Bool, fromCurrentUserTo followee: User, success: @escaping (Bool) -> Void) {
        if isFollowing {
            followUser(followee, forCurrentUserWithSuccess: success)
        } else {
            unfollowUser(followee, forCurrentUserWithSuccess: success)
        }
    }
    
    static func isFollowing(_ user: User, byCurrentUserWithCompletion completion: @escaping (Bool) ->Void) {
        let currentUID = User.current.uid
        let ref = Database.database().reference().child("followers").child(user.uid)
        ref.queryEqual(toValue: nil, childKey: currentUID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? [String: Bool] {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
}

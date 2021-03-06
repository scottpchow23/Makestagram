//
//  UserService.swift
//  Makestagram
//
//  Created by Scott P. Chow on 6/9/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import Foundation
import FirebaseAuth.FIRUser
import FirebaseDatabase

struct UserService {
    static func create(_ firUser: FIRUser, username: String, completion: @escaping (User?) -> Void) {
        let userAttrs = ["username" : username,
                         "follower_count" : 0,
                         "following_count" : 0,
                         "post_count" : 0] as [String : Any]
        
        let ref = Database.database().reference().child("users").child(firUser.uid)
        ref.setValue(userAttrs) { (error, ref) in
            if let error = error {
                print(error.localizedDescription)
            }
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                let user = User(snapshot: snapshot)
                completion(user)
            })
        }
    }
    
    static func show(forUID uid: String, completion: @escaping (User?)->Void) {
        let ref = DatabaseReference.toLocation(.showUser(uid: uid))
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let user = User(snapshot: snapshot) else {
                return completion(nil)
            }
            completion(user)
        })
    }
    
    static func posts(for user: User, completion: @escaping ([Post]) -> Void) {
        let ref = DatabaseReference.toLocation(.posts(uid: user.uid))
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion([])
            }
            let dispatchGroup = DispatchGroup()
            let posts = snapshot.reversed().flatMap({ (snapshot) -> Post? in
                guard let post = Post(snapshot: snapshot)
                    else { return nil}
                dispatchGroup.enter()
                
                LikeService.isPostLiked(post, byCurrentUserWithCompletion: { (isLiked) in
                    post.isLiked = isLiked
                    dispatchGroup.leave()
                })
                
                return post
            })
            dispatchGroup.notify(queue: .main, execute: { 
                completion(posts)
            })
        })
    }
    
    static func usersExcludingCurrentUser(completion: @escaping ([User]) ->Void) {
        let currentUser = User.current
        
        let ref = DatabaseReference.toLocation(.users)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                else { return completion([]) }
            let users = snapshot.flatMap(User.init).filter { $0.uid != currentUser.uid }
            
            let dispatchGroup = DispatchGroup()
            users.forEach({ (user) in
                dispatchGroup.enter()
                
                FollowSerivce.isFollowing(user, byCurrentUserWithCompletion: { (isFollowed) in
                    user.isFollowed = isFollowed
                    dispatchGroup.leave()
                })
            })
            dispatchGroup.notify(queue: .main, execute: { 
                completion(users)
            })
        })
    }
    
    static func followers(for user: User, completion: @escaping ([String]) -> Void) {
        let followersRef = DatabaseReference.toLocation(.followers(uid: user.uid))
        
        followersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let followersDict = snapshot.value as? [String: Bool] else {
                return completion([])
            }
            
            let followersKeys = Array(followersDict.keys)
            completion(followersKeys)
        })
    }
    
    static func timeline(pageSize: UInt, lastPostKey: String? = nil, completion: @escaping ([Post]) -> Void) {
        let currentUser = User.current
        
        let timelineRef = DatabaseReference.toLocation(.timeline(uid: currentUser.uid))
        var query = timelineRef.queryOrderedByKey().queryLimited(toLast: pageSize)
        if let lastPostKey = lastPostKey {
            query = query.queryEnding(atValue: lastPostKey)
        }
        query.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot]
                else { return completion([]) }
            let dispatchGroup = DispatchGroup()
            
            var posts = [Post]()
            
            for postSnap in snapshot {
                guard let postDict = postSnap.value as? [String :Any],
                    let posterUID = postDict["poster_uid"] as? String
                    else { continue }
                
                dispatchGroup.enter()
                PostService.show(forKey: postSnap.key, posterUID: posterUID, completion: { (post) in
                    if let post = post {
                        posts.append(post)
                    }
                    dispatchGroup.leave()
                })
            }
            dispatchGroup.notify(queue: .main, execute: { 
                completion(posts.reversed())
            })
        })
    }
    
    static func observeProfile(for user: User, completion: @escaping (DatabaseReference, User?, [Post]) -> Void) -> DatabaseHandle {
        let userRef = DatabaseReference.toLocation(.showUser(uid: user.uid))
        
        return userRef.observe(.value, with: { (snapshot) in
            guard let user = User(snapshot: snapshot) else {
                return completion(userRef, nil, [])
            }
            
            posts(for: user, completion: { (posts) in
                completion(userRef,user, posts)
            })
        })
    }
}

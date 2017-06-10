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
        let userAttrs = ["username" : username]
        
        let ref = Database.database().reference().child("Users").child(firUser.uid)
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
        let ref = Database.database().reference().child("Users").child(uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let user = User(snapshot: snapshot) else {
                return completion(nil)
            }
            completion(user)
        })
    }
    
    static func posts(for user: User, completion: @escaping ([Post]) -> Void) {
        let ref = Database.database().reference().child("Posts").child(user.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let snapshot = snapshot.children.allObjects as? [DataSnapshot] else {
                return completion([])
            }
            let posts = snapshot.reversed().flatMap(Post.init)
            print(posts)
            completion(posts)
        })
    }
}

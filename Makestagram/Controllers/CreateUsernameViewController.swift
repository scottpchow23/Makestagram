//
//  CreateUsernameViewController.swift
//  Makestagram
//
//  Created by Scott P. Chow on 6/9/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CreateUsernameViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func nextButtonTouchUpInside(_ sender: Any) {
        guard let firUser = Auth.auth().currentUser,
            let username = usernameTextField.text,
            !username.isEmpty
            else { return }
        UserService.create(firUser, username: username) { (user) in
            guard let user = user else {
                return
            }
            User.setCurrent(user, writeToUserDefaults: true)
            
            let initialViewController = UIStoryboard.instantiateInitialViewController(for: .main)
            self.view.window?.rootViewController = initialViewController
            self.view.window?.makeKeyAndVisible()
        }
        
    }
}

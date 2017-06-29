//
//  MainTabBarViewController.swift
//  Makestagram
//
//  Created by Scott P. Chow on 6/10/17.
//  Copyright © 2017 Make School. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController {

    let photoHelper = MGPhotoHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.unselectedItemTintColor = .black
        photoHelper.completionHandler = { image in
            PostService.create(for: image)
        }
    }
}

extension MainTabBarViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem.tag == 1 {
            photoHelper.presentActionSheet(from: self)
            return false
        }
        return true
    }
//    Lets see git can track this change
    
}

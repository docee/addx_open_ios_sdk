//
//  AppDelegate.swift
//  A4xDevice_Demo
//
//  Created by addx-wjin on 2021/6/30.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 创建window
        self.window = UIWindow(frame: UIScreen.main.bounds)
        // 创建UINavigationController
        let rootVC = MainViewController()
        let nav = UINavigationController(rootViewController: rootVC)

        self.window?.rootViewController = nav
        self.window?.makeKeyAndVisible()
        return true
    }
}


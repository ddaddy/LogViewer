//
//  AppDelegate.swift
//  LogViewer
//
//  Created by Darren Jones on 14/06/2022.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Ensure the URL is a file URL
        guard inputURL.isFileURL else { return false }
        
        // Reveal / import the document at the URL
        guard let nav = window?.rootViewController as? UINavigationController,
              let webView = nav.viewControllers.first as? WebViewController else { return false }
        webView.documentURL = inputURL
        
        return true
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        for context in URLContexts {
            let url = context.url
            
            // Ensure the URL is a file URL
            guard url.isFileURL else { return }
            
            // Reveal / import the document at the URL
            guard let nav = window?.rootViewController as? UINavigationController,
                  let webView = nav.viewControllers.first as? WebViewController else { return }
            webView.documentURL = url
        }
    }
}


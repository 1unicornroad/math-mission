//
//  AppDelegate.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import UIKit
import SwiftUI
import SwiftData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register custom fonts
        registerFonts()
        
        // Launch SwiftUI MenuView
        window = UIWindow(frame: UIScreen.main.bounds)
        let menuView = MenuView()
            .modelContainer(PlayerProfileStore.shared.modelContainer)
        let hostingController = UIHostingController(rootView: menuView)
        window?.rootViewController = hostingController
        window?.makeKeyAndVisible()
        return true
    }
    
    func registerFonts() {
        let fontNames = [
            "Orbitron-Regular.ttf",
            "Orbitron-Medium.ttf",
            "Orbitron-Bold.ttf",
            "Exo2-Regular.ttf",
            "Exo2-Medium.ttf",
            "Exo2-SemiBold.ttf",
            "Exo2-Bold.ttf"
        ]
        
        for fontName in fontNames {
            guard let fontURL = Bundle.main.url(forResource: fontName.replacingOccurrences(of: ".ttf", with: ""), withExtension: "ttf") else {
                print("⚠️ Failed to load font: \(fontName)")
                continue
            }
            
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                print("⚠️ Failed to register font \(fontName): \(error.debugDescription)")
            } else {
                print("✅ Registered font: \(fontName)")
            }
        }
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


}


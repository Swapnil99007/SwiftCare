//
//  EyeTracApp.swift
//  EyeTrac
//
//  Created by Deep Rodge on 9/28/24.
//

import SwiftUI
import UIKit
import Firebase
import FirebaseMessaging

@main
struct EyeTracApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

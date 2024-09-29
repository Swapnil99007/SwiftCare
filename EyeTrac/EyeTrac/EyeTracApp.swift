//
//  EyeTracApp.swift
//  EyeTrac
//
//  Created by Deep Rodge on 9/28/24.
//

import SwiftUI
import UIKit
import ARKit
import Vision
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

class EyeTrackingManager: NSObject, ARSessionDelegate {
    static let shared = EyeTrackingManager()
    
    private var arSession: ARSession?
    private var eyeTrackingRequest: VNDetectFaceRectanglesRequest?
    
    private override init() {
        super.init()
        setupARSession()
        setupVisionRequest()
    }
    
    private func setupARSession() {
        arSession = ARSession()
        arSession?.delegate = self
        
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking is not supported on this device.")
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        arSession?.run(configuration)
    }
    
    private func setupVisionRequest() {
        eyeTrackingRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let observations = request.results as? [VNFaceObservation] else { return }
            self?.processEyeTrackingResults(observations)
        }
    }
    
    private func processEyeTrackingResults(_ observations: [VNFaceObservation]) {
        // Simulated eye tracking processing
        guard let face = observations.first else { return }
        let eyePosition = CGPoint(x: face.boundingBox.midX, y: face.boundingBox.midY)
        print("Simulated eye position: \(eyePosition)")
    }
    
    func startEyeTracking() {
        print("Eye tracking started")
    }
    
    func stopEyeTracking() {
        print("Eye tracking stopped")
    }
}

extension AppDelegate {
    func applicationDidBecomeActive(_ application: UIApplication) {
        EyeTrackingManager.shared.startEyeTracking()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        EyeTrackingManager.shared.stopEyeTracking()
    }
}

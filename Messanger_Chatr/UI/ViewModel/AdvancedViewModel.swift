//
//  AdvancedViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/14/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Combine
import Contacts
import CoreLocation
import NotificationCenter
import Photos

class AdvancedViewModel: ObservableObject {
    var locationManager: CLLocationManager = CLLocationManager()
    @Published var contactsPermission: Bool = false
    @Published var locationPermission: Bool = false
    @Published var notificationPermission: Bool = false
    @Published var photoPermission: Bool = false
    @Published var cameraPermission: Bool = false
    @Published var micPermission: Bool = false
    
    func checkContactsPermission() {
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            self.contactsPermission = false
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            self.contactsPermission = true
        }
    }
    
    func requestContacts() {
        let store = CNContactStore()
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            store.requestAccess(for: .contacts){succeeded, err in
                guard err == nil && succeeded else {
                    self.contactsPermission = false
                    return
                }
                if succeeded {
                    self.contactsPermission = true
                }
            }
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            self.contactsPermission = true

        } else if CNContactStore.authorizationStatus(for: .contacts) == .denied {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            self.contactsPermission = false
        }
    }
    
    func requestLocationPermission() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationPermission = true
    }
    
    func checkLocationPermission() {
        let manager = CLLocationManager()
        
        DispatchQueue.main.async {
            if CLLocationManager.locationServicesEnabled() {
                switch manager.authorizationStatus {
                    case .notDetermined, .restricted, .denied:
                        DispatchQueue.main.async {
                            self.locationPermission = false
                        }
                    case .authorizedAlways, .authorizedWhenInUse:
                        DispatchQueue.main.async {
                            self.locationPermission = true
                        }
                    @unknown default:
                    break
                }
            } else {
                print("Location services are not enabled")
                DispatchQueue.main.async {
                    self.locationPermission = false
                }
            }
        }
    }
    
    func checkNotiPermission() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .notDetermined {
                self.notificationPermission = false
            } else if settings.authorizationStatus == .denied {
                self.notificationPermission = false
            } else if settings.authorizationStatus == .authorized {
                self.notificationPermission = true
            }
        })
    }
    
    func checkPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        if (status == PHAuthorizationStatus.authorized) {
            self.photoPermission = true
        } else if (status == PHAuthorizationStatus.denied) {
            self.photoPermission = false
        }
    }
    
    func checkCameraPermission() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            self.cameraPermission = true
        } else {
            self.cameraPermission = false
        }
    }
    
    func checkMicPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            self.micPermission = true
        case AVAudioSession.RecordPermission.denied:
            self.micPermission = false
        case AVAudioSession.RecordPermission.undetermined:
            self.micPermission = false
        @unknown default:
            self.micPermission = false
        }
    }
}

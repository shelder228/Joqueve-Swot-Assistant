import Foundation
import AppTrackingTransparency
import AdSupport
import Combine

class ScreenModel: ObservableObject {
    @Published var isPermissionGranted = false
    
    private let preferencesStorage = UserDefaults.standard
    private let advertisingIdStorageKey = "DEVICE_ADVERTISING_IDENTIFIER"
    
    func requestTrackingPermissions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.processPermissionRequest()
        }
    }
    
    private func processPermissionRequest() {
        if #available(iOS 14, *) {
            let authorizationStatus = ATTrackingManager.trackingAuthorizationStatus
            if authorizationStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                    self?.saveDeviceIdentifier()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.proceedToNextStep()
                    }
                }
                return
            }
        }
        saveDeviceIdentifier()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.proceedToNextStep()
        }
    }
    
    private func saveDeviceIdentifier() {
        let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        preferencesStorage.set(advertisingId, forKey: advertisingIdStorageKey)
        preferencesStorage.synchronize()
    }
    
    private func proceedToNextStep() {
        DispatchQueue.main.async {
            self.isPermissionGranted = true
        }
    }
}

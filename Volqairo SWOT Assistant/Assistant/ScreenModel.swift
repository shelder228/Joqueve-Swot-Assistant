import Foundation
import AppTrackingTransparency
import AdSupport
import Combine

class ScreenModel: ObservableObject {
    @Published var isPermissionGranted = false
    
    private let userDefaultsManager = UserDefaults.standard
    private let deviceAdvertisingIdKey = "DEVICE_ADVERTISING_IDENTIFIER"
    
    func requestTrackingPermissions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.handleTrackingPermissionRequest()
        }
    }
    
    private func handleTrackingPermissionRequest() {
        if #available(iOS 14, *) {
            let currentStatus = ATTrackingManager.trackingAuthorizationStatus
            if currentStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                    self?.persistAdvertisingIdentifier()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.advanceToNextPhase()
                    }
                }
                return
            }
        }
        persistAdvertisingIdentifier()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.advanceToNextPhase()
        }
    }
    
    private func persistAdvertisingIdentifier() {
        let deviceID = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        userDefaultsManager.set(deviceID, forKey: deviceAdvertisingIdKey)
        userDefaultsManager.synchronize()
    }
    
    private func advanceToNextPhase() {
        DispatchQueue.main.async {
            self.isPermissionGranted = true
        }
    }
}

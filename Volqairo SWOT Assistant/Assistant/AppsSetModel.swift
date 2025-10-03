import UIKit
import AppsFlyerLib

class AppsSetModel: NSObject, AppsFlyerLibDelegate {
    static let sharedInstance = AppsSetModel()
    
    private let trackingApiKey = "PK67HPkiTnrhFMowkyubfY"
    private let appStoreId = "6753177811"
    private let debugModeActive = false
    private let conversionTrackingEnabled = true
    
    private override init() {
        super.init()
        setupTrackingSDK()
    }
    
    private func setupTrackingSDK() {
        AppsFlyerLib.shared().appsFlyerDevKey = trackingApiKey
        AppsFlyerLib.shared().appleAppID = appStoreId
        AppsFlyerLib.shared().isDebug = debugModeActive
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
    }
    
    func onConversionDataSuccess(_ attributionData: [AnyHashable : Any]) {
        var enrichedData = attributionData
        enrichedData["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        enrichedData["locale"] = Locale.current.identifier
        enrichedData["store_id"] = "id6753177811"
        enrichedData["os"] = "iOS"
        enrichedData["bundle_id"] = "com.toxismtieqjocota.uvesfaspswasivxon"
        
        storeTrackingData(enrichedData)
    }
    
    func onConversionDataFail(_ error: Error) {
        storeTrackingData(nil)
    }
    
    func onAppOpenAttribution(_ deepLinkData: [AnyHashable : Any]) {
        storeTrackingData(nil)
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
        storeTrackingData(nil)
    }
    
    private func storeTrackingData(_ data: [AnyHashable : Any]?) {
        guard let data = data else {
            UserDefaults.standard.removeObject(forKey: "ANALYTICS_DATA_STRING")
            return
        }
        
        do {
            let serializedData = try JSONSerialization.data(withJSONObject: data, options: [])
            let dataString = String(data: serializedData, encoding: .utf8)
            UserDefaults.standard.set(dataString, forKey: "ANALYTICS_DATA_STRING")
        } catch {
        }
    }
}

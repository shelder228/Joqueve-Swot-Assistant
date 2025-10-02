import UIKit
import AppsFlyerLib

class AppsSetModel: NSObject, AppsFlyerLibDelegate {
    static let sharedInstance = AppsSetModel()
    
    private let developerApiKey = "PK67HPkiTnrhFMowkyubfY"
    private let applicationBundleId = "6753177811"
    private let isDebugModeEnabled = false
    private let shouldTrackConversions = true
    
    private override init() {
        super.init()
        initializeAnalytics()
    }
    
    private func initializeAnalytics() {
        AppsFlyerLib.shared().appsFlyerDevKey = developerApiKey
        AppsFlyerLib.shared().appleAppID = applicationBundleId
        AppsFlyerLib.shared().isDebug = isDebugModeEnabled
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
    }
    
    func onConversionDataSuccess(_ conversionData: [AnyHashable : Any]) {
        var enhancedData = conversionData
        enhancedData["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        enhancedData["locale"] = Locale.current.identifier
        enhancedData["store_id"] = "id6753177811"
        enhancedData["os"] = "iOS"
        enhancedData["bundle_id"] = "com.toxismtieqjocota.uvesfaspswasivxon"
        
        persistAnalyticsData(enhancedData)
    }
    
    func onConversionDataFail(_ error: Error) {
        persistAnalyticsData(nil)
    }
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable : Any]) {
        persistAnalyticsData(nil)
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
        persistAnalyticsData(nil)
    }
    
    private func persistAnalyticsData(_ data: [AnyHashable : Any]?) {
        guard let data = data else {
            UserDefaults.standard.removeObject(forKey: "ANALYTICS_DATA_STRING")
            return
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            UserDefaults.standard.set(jsonString, forKey: "ANALYTICS_DATA_STRING")
        } catch {
        }
    }
}

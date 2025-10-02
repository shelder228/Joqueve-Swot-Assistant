import Foundation

class TimeManage {
    static func retrieveCurrentUnixTimestamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
}

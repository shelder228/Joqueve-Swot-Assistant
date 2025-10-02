import Foundation

class TimeManage {
    static func getCurrentEpochTime() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
}

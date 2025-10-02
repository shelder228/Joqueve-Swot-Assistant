import Foundation

class MafiaTimeManager {
    static func retrieveCurrentUnixTimestamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
}

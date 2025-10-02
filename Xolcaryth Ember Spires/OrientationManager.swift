import UIKit

class OrientationManager {
    static var allowedOrientations: UIInterfaceOrientationMask = .all
    
    static func setAllOrientations() {
        allowedOrientations = .all
    }
    
    static func setLandscapeOnly() {
        allowedOrientations = [.landscapeLeft, .landscapeRight]
    }
    
    static func setPortraitOnly() {
        allowedOrientations = [.portrait, .portraitUpsideDown]
    }
}

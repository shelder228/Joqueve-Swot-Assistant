import UIKit

class OrientationManager {
    static var supportedOrientations: UIInterfaceOrientationMask = .all
    
    static func enableAllOrientations() {
        supportedOrientations = .all
    }
    
    static func restrictToLandscape() {
        supportedOrientations = [.landscapeLeft, .landscapeRight]
    }
    
    static func restrictToPortrait() {
        supportedOrientations = [.portrait, .portraitUpsideDown]
    }
}

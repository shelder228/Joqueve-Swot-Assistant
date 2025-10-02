import Foundation
import SwiftUI

struct AnalysisSection: Identifiable {
    let id = UUID()
    let title: String
    let content: [String]
    let color: Color
    let icon: String
}

import Foundation

struct SWOTAnalysis: Identifiable, Codable {
    let id = UUID()
    let title: String
    let strengths: String
    let weaknesses: String
    let opportunities: String
    let threats: String
    let analysisResult: String
    let createdAt: Date
    
    init(title: String, strengths: String, weaknesses: String, opportunities: String, threats: String, analysisResult: String) {
        self.title = title
        self.strengths = strengths
        self.weaknesses = weaknesses
        self.opportunities = opportunities
        self.threats = threats
        self.analysisResult = analysisResult
        self.createdAt = Date()
    }
}

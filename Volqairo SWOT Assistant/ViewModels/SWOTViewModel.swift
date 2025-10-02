import Foundation
import SwiftUI

class SWOTViewModel: ObservableObject {
    @Published var strengths = ""
    @Published var weaknesses = ""
    @Published var opportunities = ""
    @Published var threats = ""
    @Published var analysisResult = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var errorRecoverySuggestion: String?
    @Published var showErrorAlert = false
    @Published var retryCount = 0
    private let maxRetries = 3
    @Published var savedAnalyses: [SWOTAnalysis] = []
    @Published var currentAnalysisTitle = ""
    @Published var showOnboarding = true
    
    private let geminiAPI = GeminiAPI()
    
    init() {
        loadSavedAnalyses()
        checkOnboardingStatus()
    }
    
    func generateAnalysis() {
        guard !strengths.isEmpty || !weaknesses.isEmpty || !opportunities.isEmpty || !threats.isEmpty else {
            errorMessage = "Please fill in at least one field"
            errorRecoverySuggestion = "Add some strengths, weaknesses, opportunities, or threats to get started."
            showErrorAlert = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        errorRecoverySuggestion = nil
        showErrorAlert = false
        analysisResult = ""
        
        Task {
            await performAnalysisWithRetry()
        }
    }
    
    private func performAnalysisWithRetry() async {
        do {
            let result = try await geminiAPI.generateSWOTAnalysis(
                strengths: strengths,
                weaknesses: weaknesses,
                opportunities: opportunities,
                threats: threats
            )
            
            await MainActor.run {
                self.analysisResult = result
                self.isLoading = false
                self.retryCount = 0
                self.saveCurrentAnalysis()
                print("Analysis generated and saved: \(result.prefix(100))...")
                self.objectWillChange.send()
            }
        } catch let apiError as APIError {
            await MainActor.run {
                self.handleAPIError(apiError)
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                self.errorRecoverySuggestion = "Please try again. If the problem persists, contact support."
                self.showErrorAlert = true
                print("Unexpected error: \(error)")
            }
        }
    }
    
    private func handleAPIError(_ apiError: APIError) {
        // Check if we should retry for server errors
        if shouldRetry(for: apiError) && retryCount < maxRetries {
            retryCount += 1
            print("Retrying API call (attempt \(retryCount)/\(maxRetries))")
            
            // Wait before retry (exponential backoff)
            let delay = pow(2.0, Double(retryCount)) // 2, 4, 8 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                Task {
                    await self.performAnalysisWithRetry()
                }
            }
        } else {
            self.isLoading = false
            self.errorMessage = apiError.localizedDescription
            self.errorRecoverySuggestion = apiError.recoverySuggestion
            self.showErrorAlert = true
            self.retryCount = 0
            print("API Error: \(apiError.localizedDescription)")
        }
    }
    
    private func shouldRetry(for error: APIError) -> Bool {
        switch error {
        case .serverError(let code):
            return code >= 500 && code < 600 // Retry for 5xx errors
        case .timeout, .networkError:
            return true
        default:
            return false
        }
    }
    
    func clearError() {
        errorMessage = nil
        errorRecoverySuggestion = nil
        showErrorAlert = false
    }
    
    func saveCurrentAnalysis() {
        guard !analysisResult.isEmpty else { return }
        
        let title = currentAnalysisTitle.isEmpty ? "SWOT Analysis \(DateFormatter.shortDate.string(from: Date()))" : currentAnalysisTitle
        
        let analysis = SWOTAnalysis(
            title: title,
            strengths: strengths,
            weaknesses: weaknesses,
            opportunities: opportunities,
            threats: threats,
            analysisResult: analysisResult
        )
        
        savedAnalyses.append(analysis)
        saveToUserDefaults()
    }
    
    func loadAnalysis(_ analysis: SWOTAnalysis) {
        strengths = analysis.strengths
        weaknesses = analysis.weaknesses
        opportunities = analysis.opportunities
        threats = analysis.threats
        analysisResult = analysis.analysisResult
        currentAnalysisTitle = analysis.title
    }
    
    func deleteAnalysis(_ analysis: SWOTAnalysis) {
        savedAnalyses.removeAll { $0.id == analysis.id }
        saveToUserDefaults()
    }
    
    func clearAllData() {
        strengths = ""
        weaknesses = ""
        opportunities = ""
        threats = ""
        analysisResult = ""
        currentAnalysisTitle = ""
        savedAnalyses.removeAll()
        saveToUserDefaults()
    }
    
    func completeOnboarding() {
        showOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
    
    private func loadSavedAnalyses() {
        if let data = UserDefaults.standard.data(forKey: "savedAnalyses"),
           let analyses = try? JSONDecoder().decode([SWOTAnalysis].self, from: data) {
            savedAnalyses = analyses
        }
    }
    
    private func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(savedAnalyses) {
            UserDefaults.standard.set(data, forKey: "savedAnalyses")
        }
    }
    
    private func checkOnboardingStatus() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

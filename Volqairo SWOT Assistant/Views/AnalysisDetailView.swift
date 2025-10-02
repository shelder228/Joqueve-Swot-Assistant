import SwiftUI

struct AnalysisDetailView: View {
    let analysis: SWOTAnalysis
    @State private var parsedSections: [AnalysisSection] = []
    @State private var showingShareSheet = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(analysis.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Created \(analysis.createdAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // SWOT Matrix
                    SWOTMatrixView(
                        strengths: analysis.strengths,
                        weaknesses: analysis.weaknesses,
                        opportunities: analysis.opportunities,
                        threats: analysis.threats
                    )
                    
                    // Analysis sections
                    if parsedSections.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Analysis Results")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(analysis.analysisResult)
                                .font(.body)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                        )
                    } else {
                        ForEach(parsedSections, id: \.title) { section in
                            AnalysisSectionCard(section: section)
                        }
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.black, Color(red: 0.1, green: 0, blue: 0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Analysis Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.orange)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        showingShareSheet = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [analysis.analysisResult])
            }
        }
        .onAppear {
            // Устанавливаем портретную ориентацию
            OrientationManager.setPortraitOnly()
            
            print("AnalysisDetailView appeared for: \(analysis.title)")
            print("Analysis result length: \(analysis.analysisResult.count)")
            print("Analysis result: \(analysis.analysisResult)")
            parseAnalysisResult()
        }
    }
    
    private func parseAnalysisResult() {
        parsedSections = SWOTParser.shared.parseAnalysisResult(analysis.analysisResult)
    }
    
}

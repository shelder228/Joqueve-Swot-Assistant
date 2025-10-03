import SwiftUI

struct AnalysisResultsSheet: View {
    @ObservedObject var viewModel: SWOTViewModel
    @Binding var isPresented: Bool
    @State private var parsedSections: [AnalysisSection] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [.black, Color(red: 0.1, green: 0, blue: 0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Analysis Results")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Generated on \(Date(), style: .date)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // SWOT Matrix
                        SWOTMatrixView(
                            strengths: viewModel.strengths,
                            weaknesses: viewModel.weaknesses,
                            opportunities: viewModel.opportunities,
                            threats: viewModel.threats
                        )
                        
                        // Analysis sections
                        if parsedSections.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Analysis Results")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(viewModel.analysisResult)
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
            }
            .navigationTitle("SWOT Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            // Устанавливаем портретную ориентацию
            OrientationManager.restrictToPortrait()
            
            parseAnalysisResult()
        }
    }
    
    private func parseAnalysisResult() {
        parsedSections = SWOTParser.shared.parseAnalysisResult(viewModel.analysisResult)
    }
    
}

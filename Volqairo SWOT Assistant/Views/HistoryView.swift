import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: SWOTViewModel
    @State private var showingDeleteAlert = false
    @State private var analysisToDelete: SWOTAnalysis?
    @State private var selectedAnalysis: SWOTAnalysis?
    @State private var showingAnalysisDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Image("BG_1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                
                // Dark overlay for better text readability
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                if viewModel.savedAnalyses.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("No Analyses Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Generate your first SWOT analysis to see it here")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 600 : 400)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 16), 
                                        count: UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1),
                            spacing: 16
                        ) {
                            ForEach(viewModel.savedAnalyses.reversed()) { analysis in
                                AnalysisCard(
                                    analysis: analysis,
                                    onTap: {
                                        selectedAnalysis = analysis
                                        showingAnalysisDetail = true
                                    },
                                    onLoad: {
                                        viewModel.loadAnalysis(analysis)
                                    },
                                    onDelete: {
                                        analysisToDelete = analysis
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 800 : 400)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Delete Analysis", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let analysis = analysisToDelete {
                        viewModel.deleteAnalysis(analysis)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this analysis? This action cannot be undone.")
            }
            .sheet(item: $selectedAnalysis) { analysis in
                AnalysisDetailView(analysis: analysis)
            }
        }
        .onAppear {
            // Устанавливаем портретную ориентацию
            OrientationManager.restrictToPortrait()
        }
    }
}

struct AnalysisCard: View {
    let analysis: SWOTAnalysis
    let onTap: () -> Void
    let onLoad: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(analysis.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(analysis.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.1))
                    )
                }
                
                // Preview of analysis content
                Text("Tap to view full analysis")
                    .font(.body)
                    .foregroundColor(.gray)
                    .italic()
                    .multilineTextAlignment(.leading)
                
                // SWOT indicators
                HStack(spacing: 12) {
                    SWOTIndicator(
                        title: "S",
                        count: analysis.strengths.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count,
                        color: .green
                    )
                    
                    SWOTIndicator(
                        title: "W",
                        count: analysis.weaknesses.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count,
                        color: .red
                    )
                    
                    SWOTIndicator(
                        title: "O",
                        count: analysis.opportunities.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count,
                        color: .blue
                    )
                    
                    SWOTIndicator(
                        title: "T",
                        count: analysis.threats.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count,
                        color: .orange
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Load Analysis", action: onLoad)
        }
    }
}

struct SWOTIndicator: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.2))
        )
    }
}

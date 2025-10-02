import SwiftUI

struct InputView: View {
    @ObservedObject var viewModel: SWOTViewModel
    @State private var showResults = false
    
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Analysis Title")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter analysis title (optional)", text: $viewModel.currentAnalysisTitle)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.purple.opacity(0.6), lineWidth: 1.5)
                                        )
                                )
                                .foregroundColor(.white)
                        }
                        
                        // SWOT Input Fields
                        VStack(alignment: .leading, spacing: 16) {
                            SWOTInputField(
                                title: "Strengths",
                                placeholder: "What are your strengths?",
                                text: $viewModel.strengths,
                                color: .red
                            )
                            
                            SWOTInputField(
                                title: "Weaknesses", 
                                placeholder: "What are your weaknesses?",
                                text: $viewModel.weaknesses,
                                color: .purple
                            )
                            
                            SWOTInputField(
                                title: "Opportunities",
                                placeholder: "What opportunities do you see?",
                                text: $viewModel.opportunities,
                                color: .yellow
                            )
                            
                            SWOTInputField(
                                title: "Threats",
                                placeholder: "What threats do you face?",
                                text: $viewModel.threats,
                                color: .green
                            )
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            // Clear All Button
                            Button(action: {
                                clearAllFields()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear All")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.2, green: 0.1, blue: 0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.red)
                            }
                            .disabled(viewModel.isLoading)
                            
                            // Generate Button
                            Button(action: {
                                viewModel.generateAnalysis()
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        if viewModel.retryCount > 0 {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Retrying... (\(viewModel.retryCount)/3)")
                                                .fontWeight(.semibold)
                                        } else {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Generating...")
                                                .fontWeight(.semibold)
                                        }
                                    } else {
                                        Image(systemName: "theatermasks.fill")
                                        Text("Generate Analysis")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: viewModel.isLoading ? [.gray, .gray] : [.purple, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                        }
                        
                        // Examples Section
                        ExamplesView(viewModel: viewModel)
                    }
                    .padding()
                    .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 600 : 400)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("SWOT Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: viewModel.isLoading) { isLoading in
                print("isLoading changed to: \(isLoading)")
                if !isLoading && !viewModel.analysisResult.isEmpty {
                    print("Loading finished, showing results: \(viewModel.analysisResult.prefix(100))...")
                    showResults = true
                }
            }
            .onChange(of: viewModel.analysisResult) { newValue in
                print("analysisResult changed, isEmpty: \(newValue.isEmpty)")
                if !newValue.isEmpty && !viewModel.isLoading {
                    print("Analysis result available, showing results")
                    showResults = true
                }
            }
            .onReceive(viewModel.$isLoading) { isLoading in
                if !isLoading && !viewModel.analysisResult.isEmpty {
                    print("onReceive: Loading finished, showing results")
                    showResults = true
                }
            }
            .onReceive(viewModel.$analysisResult) { newValue in
                if !newValue.isEmpty && !viewModel.isLoading {
                    print("onReceive: Analysis result available, showing results")
                    showResults = true
                }
            }
            .sheet(isPresented: $showResults) {
                AnalysisResultsSheet(viewModel: viewModel, isPresented: $showResults)
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                VStack(alignment: .leading) {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                    }
                    if let recoverySuggestion = viewModel.errorRecoverySuggestion {
                        Text(recoverySuggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // Устанавливаем портретную ориентацию
            OrientationManager.setPortraitOnly()
        }
    }
    
    private func clearAllFields() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.currentAnalysisTitle = ""
            viewModel.strengths = ""
            viewModel.weaknesses = ""
            viewModel.opportunities = ""
            viewModel.threats = ""
        }
    }
}


struct SWOTInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(color.opacity(0.6), lineWidth: 1.5)
                        )
                )
                .foregroundColor(.white)
                .overlay(
                    Group {
                        if text.isEmpty {
                            VStack {
                                HStack {
                                    Text(placeholder)
                                        .foregroundColor(.gray.opacity(0.7))
                                        .padding(.leading, 16)
                                        .padding(.top, 12)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )
        }
    }
}

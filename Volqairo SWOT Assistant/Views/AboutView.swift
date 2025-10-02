import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
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
                    // App Icon and Title
                    VStack(spacing: 16) {
                        Image(systemName: "theatermasks.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        
                        Text("Joqueve SWOT Assistant")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        AboutSection(
                            title: "About",
                            content: "Joqueve SWOT Assistant is an AI-powered tool that helps you create comprehensive SWOT analyses with circus magic! Built with SwiftUI and powered by Google's Gemini AI, it provides strategic insights to help you make better business decisions."
                        )
                        
                        AboutSection(
                            title: "Features",
                            content: "• AI-powered SWOT analysis\n• Beautiful, intuitive interface\n• Save and organize analyses\n• Export and share results\n• Offline data storage\n• Privacy-focused design"
                        )
                        
                        AboutSection(
                            title: "Technology",
                            content: "Built with SwiftUI for iOS, using Google's Gemini 2.0 Flash AI for analysis generation. All data is stored locally on your device for maximum privacy."
                        )
                        
                        AboutSection(
                            title: "Privacy",
                            content: "Your data stays on your device. We only send your SWOT inputs to Google's AI service for analysis, and this data is not stored by Google."
                        )
                        
                        AboutSection(
                            title: "Developer",
                            content: "Developed with ❤️ for strategic thinking and business analysis. Built using modern iOS development practices and AI integration."
                        )
                    }
                }
                .padding()
                .frame(maxWidth: 400) // Ограничиваем ширину контента
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            // Устанавливаем портретную ориентацию
            OrientationManager.restrictToPortrait()
        }
    }
}

struct AboutSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.orange)
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
        )
    }
}

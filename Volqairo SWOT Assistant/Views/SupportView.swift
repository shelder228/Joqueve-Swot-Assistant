import SwiftUI

struct SupportView: View {
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
                    Text("Support")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("We're here to help!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SupportSection(
                            title: "Getting Started",
                            content: "1. Fill in your SWOT analysis fields\n2. Tap 'Generate Analysis' to get AI insights\n3. View results and save for later reference"
                        )
                        
                        SupportSection(
                            title: "Tips for Better Results",
                            content: "• Be specific and detailed in your inputs\n• Include concrete examples\n• Consider both internal and external factors\n• Think about short-term and long-term perspectives"
                        )
                        
                        SupportSection(
                            title: "Troubleshooting",
                            content: "• Ensure you have internet connection for AI analysis\n• Try refreshing if analysis fails\n• Check that at least one field is filled\n• Restart the app if issues persist"
                        )
                        
                        SupportSection(
                            title: "Features",
                            content: "• AI-powered SWOT analysis\n• Save and organize analyses\n• Export and share results\n• Beautiful, intuitive interface"
                        )
                        
                        SupportSection(
                            title: "Contact Support",
                            content: "If you need additional help, please contact us through the app store or email us at support@volqairo.com"
                        )
                    }
                }
                .padding()
                .frame(maxWidth: 400) // Ограничиваем ширину контента
                }
            }
            .navigationTitle("Support")
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

struct SupportSection: View {
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

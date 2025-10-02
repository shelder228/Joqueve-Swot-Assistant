import SwiftUI

struct PrivacyPolicyView: View {
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
            Text("Privacy Policy")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Last updated: \(Date(), formatter: dateFormatter)")
                .font(.caption)
                .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PolicySection(
                            title: "Data Collection",
                            content: "We collect only the SWOT analysis data you voluntarily provide. No personal information is collected without your consent."
                        )
                        
                        PolicySection(
                            title: "Data Usage",
                            content: "Your SWOT data is used solely to generate AI-powered analysis. We do not share, sell, or use your data for any other purposes."
                        )
                        
                        PolicySection(
                            title: "Data Storage",
                            content: "All data is stored locally on your device. We do not store your information on external servers."
                        )
                        
                        PolicySection(
                            title: "AI Processing",
                            content: "Your SWOT data is sent to Google's Gemini AI service for analysis. This data is not stored by Google and is processed securely."
                        )
                        
                        PolicySection(
                            title: "Data Security",
                            content: "We implement appropriate security measures to protect your data. However, no method of transmission over the internet is 100% secure."
                        )
                        
                        PolicySection(
                            title: "Your Rights",
                            content: "You have the right to access, modify, or delete your data at any time through the app's settings."
                        )
                        
                        PolicySection(
                            title: "Contact Us",
                            content: "If you have any questions about this Privacy Policy, please contact us through the app's support section."
                        )
                    }
                }
                .padding()
                .frame(maxWidth: 400) // Ограничиваем ширину контента
                }
            }
            .navigationTitle("Privacy Policy")
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
            OrientationManager.setPortraitOnly()
        }
    }
}

struct PolicySection: View {
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter
}()

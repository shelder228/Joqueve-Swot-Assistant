import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject var viewModel: SWOTViewModel
    @State private var showingShareSheet = false
    
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
                
                GeometryReader { geometry in
                    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                    ScrollView {
                        VStack(spacing: 20) {
                            // App Info Section
                            VStack(spacing: 16) {
                                Image(systemName: "theatermasks.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.purple)
                                
                                Text("Joqueve SWOT Assistant")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Version 1.0")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                            )
                            
                            // Settings Sections
                            VStack(spacing: 12) {
                                SettingsRow(
                                    icon: "doc.text",
                                    title: "Privacy Policy",
                                    action: { openPrivacyPolicy() }
                                )
                                
                                SettingsRow(
                                    icon: "questionmark.circle",
                                    title: "Support",
                                    action: { openSupport() }
                                )
                                
                                SettingsRow(
                                    icon: "star.fill",
                                    title: "Rate App",
                                    action: { requestAppStoreReview() }
                                )
                            }
                        }
                        .padding()
                        .frame(maxWidth: isIPad ? 600 : 400)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingShareSheet) {
                ShareAppView()
            }
        }
        .onAppear {
            // Устанавливаем портретную ориентацию
            OrientationManager.setPortraitOnly()
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://joqueveswotassistant.com/privacy-policy.html") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSupport() {
        if let url = URL(string: "https://joqueveswotassistant.com/support.html") {
            UIApplication.shared.open(url)
        }
    }
    
    private func requestAppStoreReview() {
        // Используем стандартный алерт iOS для оценки
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    private func openAppStoreRating() {
        // Fallback функция для прямого открытия App Store
        if let url = URL(string: "https://apps.apple.com/app/id6753177811") {
            UIApplication.shared.open(url)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

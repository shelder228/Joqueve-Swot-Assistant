import SwiftUI

struct ShareAppView: View {
    @Environment(\.presentationMode) var presentationMode
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
                
                VStack(spacing: 30) {
                // App Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: "theatermasks.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                    
                    Text("Rate & Share")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Help us grow by rating and sharing the app!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                )
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Open App Store rating
                        if let url = URL(string: "itms-apps://itunes.apple.com/app/id6753177811?action=write-review"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else {
                            // Fallback на Safari
                            if let url = URL(string: "https://apps.apple.com/app/id6753177811") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Rate on App Store")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }
                    
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                            Text("Share with Friends")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                    }
                }
                
                Spacer()
                }
                .padding()
                .frame(maxWidth: 500) // Увеличиваем максимальную ширину для iPad
            }
            .navigationTitle("Rate & Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [
                    "Check out Joqueve SWOT Assistant - AI-powered strategic analysis with circus magic! 🎭\n\nDownload it here: https://apps.apple.com/app/id6753177811"
                ])
            }
        }
        .onAppear {
            // Устанавливаем портретную ориентацию
            OrientationManager.restrictToPortrait()
        }
    }
}

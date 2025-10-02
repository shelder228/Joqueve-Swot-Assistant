import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: SWOTViewModel
    @State private var currentPage = 0
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            // Background
            Image("BG_1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Dark overlay for better text readability
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "GameName",
                        title: "Welcome to Joqueve",
                        description: "Your AI-powered SWOT analysis assistant with circus magic!",
                        color: .orange
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "brain.head.profile",
                        title: "AI-Powered Analysis",
                        description: "Get comprehensive SWOT analysis using advanced AI technology.",
                        color: .yellow
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "star.fill",
                        title: "Strategic Insights",
                        description: "Discover opportunities and threats with detailed recommendations.",
                        color: .red
                    )
                    .tag(2)
                    
                    OnboardingPage(
                        icon: "ticket.fill",
                        title: "Save & Track",
                        description: "Keep all your analyses organized and accessible anytime.",
                        color: .purple
                    )
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxWidth: 400) // Ограничиваем ширину контента
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == currentPage ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 30)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        }) {
                            Text("Previous")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                )
                        }
                    }
                    
                    Button(action: {
                        if currentPage < totalPages - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        } else {
                            viewModel.completeOnboarding()
                        }
                    }) {
                        Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: 400) // Ограничиваем ширину кнопок
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Устанавливаем портретную ориентацию
            OrientationManager.setPortraitOnly()
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 30) {
            // Check if it's a system icon or asset image
            if icon.contains(".") {
                // System icon
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(color)
            } else {
                // Asset image
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
            }
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SWOTViewModel()
    
    var body: some View {
        Group {
            if viewModel.showOnboarding {
                OnboardingView(viewModel: viewModel)
            } else if viewModel.isLoading {
                LoadingView()
            } else {
                TabView {
                    InputView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "theatermasks")
                            Text("Input")
                        }
                    
                    HistoryView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "ticket")
                            Text("History")
                        }
                    
                    TipsView()
                        .tabItem {
                            Image(systemName: "star")
                            Text("Tips")
                        }
                    
                    SettingsView(viewModel: viewModel)
                        .tabItem {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                }
                .accentColor(.purple)
                .background(
                    ZStack {
                        Image("BG_1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .ignoresSafeArea()
                        
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                    }
                )
                .onAppear {
                    // Устанавливаем портретную ориентацию
                    OrientationManager.restrictToPortrait()
                    
                    // Настройки для iPad
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        // Дополнительные настройки для iPad при необходимости
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

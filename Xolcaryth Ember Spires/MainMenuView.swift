
import SwiftUI

struct MainMenuView: View {
    @StateObject private var gameState = GameState()
    @StateObject private var soundManager = SoundManager.shared
    @State private var showingGameSetup = false
    @State private var showingSettings = false
    @State private var showingInstructions = false
    @State private var showingStatistics = false
    
    var body: some View {
        ZStack {
            // Background with the BackGround sprite
            GameBackgroundView()
            
            HStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 80 : 40) {
                // Left side - Game Title and Stats
                VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 50 : 30) {
                    Spacer()
                    
                    // Game Title
                    VStack(spacing: 15) {
                        Text("XOLCARYTH")
                            .gameText(size: UIDevice.current.userInterfaceIdiom == .pad ? .extraLarge : .large, weight: .bold)
                            .shadow(color: GameColorScheme.shadowColor, radius: 4, x: 0, y: 2)
                        
                        Text("EMBER SPIRES")
                            .gameText(size: UIDevice.current.userInterfaceIdiom == .pad ? .large : .medium, weight: .bold)
                            .foregroundColor(GameColorScheme.accentColor)
                            .shadow(color: GameColorScheme.shadowColor, radius: 4, x: 0, y: 2)
                        
                        Text("A Mafia Game of Shadows")
                            .gameText(size: UIDevice.current.userInterfaceIdiom == .pad ? .medium : .small, weight: .regular)
                            .foregroundColor(GameColorScheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Game Stats
                    VStack(spacing: 20) {
                        Text("Game Statistics")
                            .gameText(size: .medium, weight: .bold)
                            .foregroundColor(GameColorScheme.accentColor)
                        
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(gameState.totalGames)")
                                    .gameText(size: .large, weight: .bold)
                                    .foregroundColor(GameColorScheme.accentColor)
                                Text("Games Played")
                                    .gameText(size: .small, weight: .regular)
                                    .foregroundColor(GameColorScheme.secondaryText)
                            }
                            
                            VStack {
                                Text("\(gameState.mafiaWins)")
                                    .gameText(size: .large, weight: .bold)
                                    .foregroundColor(GameColorScheme.dangerColor)
                                Text("Mafia Wins")
                                    .gameText(size: .small, weight: .regular)
                                    .foregroundColor(GameColorScheme.secondaryText)
                            }
                            
                            VStack {
                                Text("\(gameState.villagerWins)")
                                    .gameText(size: .large, weight: .bold)
                                    .foregroundColor(GameColorScheme.successColor)
                                Text("Villager Wins")
                                    .gameText(size: .small, weight: .regular)
                                    .foregroundColor(GameColorScheme.secondaryText)
                            }
                        }
                    }
                    .gameCard()
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Menu Buttons
                VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 40 : 25) {
                    Spacer()
                    
                    Text("Main Menu")
                        .gameText(size: UIDevice.current.userInterfaceIdiom == .pad ? .extraLarge : .large, weight: .bold)
                        .foregroundColor(GameColorScheme.accentColor)
                        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20)
                    
                    // Menu Buttons
                    VStack(spacing: UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20) {
                        // New Game Button
                        Button(action: {
                            soundManager.playButtonTap()
                            gameState.resetGame()
                            showingGameSetup = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                Text("New Game")
                                    .font(.headline)
                            }
                        }
                        .gameButton(isPrimary: true)
                        
                        // Continue Game Button (disabled if no saved game)
                        Button(action: {
                            // TODO: Implement continue game functionality
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                Text("Continue")
                                    .font(.headline)
                            }
                        }
                        .gameButton(isPrimary: false)
                        .disabled(true) // Disabled until save/load is implemented
                        .opacity(0.6)
                        
                        // Settings Button
                        Button(action: {
                            soundManager.playButtonTap()
                            showingSettings = true
                        }) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                Text("Settings")
                                    .font(.headline)
                            }
                        }
                        .gameButton(isPrimary: false)
                        
                        // Instructions Button
                        Button(action: {
                            soundManager.playButtonTap()
                            showingInstructions = true
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.title2)
                                Text("Instructions")
                                    .font(.headline)
                            }
                        }
                        .gameButton(isPrimary: false)
                        
                        // Statistics Button
                        Button(action: {
                            soundManager.playButtonTap()
                            showingStatistics = true
                        }) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                Text("Statistics")
                                    .font(.headline)
                            }
                        }
                        .gameButton(isPrimary: false)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showingGameSetup) {
            GameSetupView(gameState: gameState)
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(gameState: gameState)
                .interactiveDismissDisabled()
        }
        .fullScreenCover(isPresented: $showingInstructions) {
            TutorialView()
                .interactiveDismissDisabled()
        }
        .fullScreenCover(isPresented: $showingStatistics) {
            StatisticsView(gameState: gameState)
                .interactiveDismissDisabled()
        }
    }
    }


// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundManager = SoundManager.shared
    // Vibration is now handled by SoundManager
    @AppStorage("discussionTime") private var discussionTime = 300
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("Back") {
                        soundManager.playButtonTap()
                        dismiss()
                    }
                    .gameButton(isPrimary: false)
                    
                    Spacer()
                    
                    Text("Settings")
                        .gameText(size: UIDevice.current.userInterfaceIdiom == .pad ? .extraLarge : .large, weight: .bold)
                        .foregroundColor(GameColorScheme.accentColor)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("Back") {
                        soundManager.playButtonTap()
                        dismiss()
                    }
                    .gameButton(isPrimary: false)
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Settings Content
                ScrollView {
                    VStack(spacing: 20) {
                            // Audio Settings
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Audio")
                                    .gameText(size: .medium, weight: .bold)
                                
                                Toggle("Sound Effects", isOn: $soundManager.isSoundEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: GameColorScheme.accentColor))
                                    .foregroundColor(GameColorScheme.primaryText)
                            }
                            .gameCard()
                            
                            // Haptic Settings
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Haptics")
                                    .gameText(size: .medium, weight: .bold)
                                
                                Toggle("Vibration", isOn: $soundManager.isVibrationEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: GameColorScheme.accentColor))
                                    .foregroundColor(GameColorScheme.primaryText)
                            }
                            .gameCard()
                            
                            // Game Settings
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Game")
                                    .gameText(size: .medium, weight: .bold)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Discussion Time: \(discussionTime / 60) minutes")
                                        .gameText(size: .small, weight: .regular)
                                    
                                    Slider(value: Binding(
                                        get: { Double(discussionTime) },
                                        set: { 
                                            discussionTime = Int($0)
                                            gameState.updateDiscussionTime(Int($0))
                                        }
                                    ), in: 60...600, step: 30)
                                    .accentColor(GameColorScheme.accentColor)
                                }
                            }
                            .gameCard()
                            
                            // Privacy Policy and Support
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Legal & Support")
                                    .gameText(size: .medium, weight: .bold)
                                
                                VStack(spacing: 10) {
                                    Button(action: {
                                        soundManager.playButtonTap()
                                        if let url = URL(string: "https://xolcarythemberspires.com/privacy-policy.html") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.text")
                                                .font(.title3)
                                            Text("Privacy Policy")
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.caption)
                                        }
                                    }
                                    .gameButton(isPrimary: false)
                                    
                                    Button(action: {
                                        soundManager.playButtonTap()
                                        if let url = URL(string: "https://xolcarythemberspires.com/support.html") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "questionmark.circle")
                                                .font(.title3)
                                            Text("Support")
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.caption)
                                        }
                                    }
                                    .gameButton(isPrimary: false)
                                }
                            }
                            .gameCard()
                            
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    }



struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
    }


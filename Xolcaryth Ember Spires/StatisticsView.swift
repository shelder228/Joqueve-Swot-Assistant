
import SwiftUI

struct StatisticsView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var soundManager = SoundManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    private let tabs = ["Overview", "Performance"]
    
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
                    
                    Text("Statistics")
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
                
                ScrollView {
                    HStack(spacing: 20) {
                        // Left side - Tabs and Navigation
                        VStack(spacing: 10) {
                    
                    // Tab Selector
                    VStack(spacing: 10) {
                        ForEach(0..<tabs.count, id: \.self) { index in
                            Button(action: {
                                soundManager.playButtonTap()
                                selectedTab = index
                            }) {
                                Text(tabs[index])
                                    .gameText(size: .medium, weight: .medium)
                                    .foregroundColor(selectedTab == index ? GameColorScheme.accentColor : GameColorScheme.secondaryText)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedTab == index ? GameColorScheme.accentColor.opacity(0.2) : Color.clear)
                                    )
                            }
                        }
                    }
                    .gameCard()
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Content
                VStack(spacing: 20) {
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case 0:
                                OverviewTab(gameState: gameState)
                            case 1:
                                PerformanceTab(gameState: gameState)
                            default:
                                OverviewTab(gameState: gameState)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Устанавливаем landscape ориентацию для экрана статистики
            OrientationManager.setLandscapeOnly()
        }
    }
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 20) {
            // Game Summary
            VStack(spacing: 15) {
                Text("Game Summary")
                    .gameText(size: .medium, weight: .bold)
                    .foregroundColor(GameColorScheme.accentColor)
                
                HStack(spacing: 30) {
                    VStack {
                        Text("\(gameState.totalGames)")
                            .gameText(size: .large, weight: .bold)
                            .foregroundColor(GameColorScheme.accentColor)
                        Text("Total Games")
                            .gameText(size: .small, weight: .regular)
                    }
                    
                    VStack {
                        Text("\(gameState.mafiaWins)")
                            .gameText(size: .large, weight: .bold)
                            .foregroundColor(GameColorScheme.dangerColor)
                        Text("Mafia Wins")
                            .gameText(size: .small, weight: .regular)
                    }
                    
                    VStack {
                        Text("\(gameState.villagerWins)")
                            .gameText(size: .large, weight: .bold)
                            .foregroundColor(GameColorScheme.successColor)
                        Text("Villager Wins")
                            .gameText(size: .small, weight: .regular)
                    }
                }
            }
            .gameCard()
            
            // Win Rate Chart
            VStack(spacing: 15) {
                Text("Win Rate Distribution")
                    .gameText(size: .medium, weight: .bold)
                    .foregroundColor(GameColorScheme.accentColor)
                
                if gameState.totalGames > 0 {
                    HStack(spacing: 20) {
                        // Mafia Win Rate
                        VStack(spacing: 8) {
                            Text("Mafia")
                                .gameText(size: .small, weight: .medium)
                                .foregroundColor(GameColorScheme.dangerColor)
                            
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(GameColorScheme.overlayBackground)
                                    .frame(width: 40, height: 100)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(GameColorScheme.dangerColor)
                                    .frame(width: 40, height: CGFloat(gameState.mafiaWins) / CGFloat(gameState.totalGames) * 100)
                                    .animation(.easeInOut(duration: 1.0), value: gameState.mafiaWins)
                            }
                            
                            Text("\(Int(Double(gameState.mafiaWins) / Double(gameState.totalGames) * 100))%")
                                .gameText(size: .small, weight: .bold)
                        }
                        
                        // Villager Win Rate
                        VStack(spacing: 8) {
                            Text("Villagers")
                                .gameText(size: .small, weight: .medium)
                                .foregroundColor(GameColorScheme.successColor)
                            
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(GameColorScheme.overlayBackground)
                                    .frame(width: 40, height: 100)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(GameColorScheme.successColor)
                                    .frame(width: 40, height: CGFloat(gameState.villagerWins) / CGFloat(gameState.totalGames) * 100)
                                    .animation(.easeInOut(duration: 1.0), value: gameState.villagerWins)
                            }
                            
                            Text("\(Int(Double(gameState.villagerWins) / Double(gameState.totalGames) * 100))%")
                                .gameText(size: .small, weight: .bold)
                        }
                    }
                } else {
                    Text("No games played yet")
                        .gameText(size: .small, weight: .regular)
                        .foregroundColor(GameColorScheme.secondaryText)
                }
            }
            .gameCard()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    }



// MARK: - Performance Tab
struct PerformanceTab: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 20) {
            // Performance Metrics
            VStack(spacing: 15) {
                Text("Performance Metrics")
                    .gameText(size: .medium, weight: .bold)
                    .foregroundColor(GameColorScheme.accentColor)
                
                LazyVStack(spacing: 15) {
                    // Average Game Duration
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Average Game Duration")
                                .gameText(size: .small, weight: .medium)
                            
                            Text("Based on discussion time")
                                .gameText(size: .small, weight: .regular)
                                .foregroundColor(GameColorScheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Text("\(gameState.discussionTimeRemaining / 60) min")
                            .gameText(size: .medium, weight: .bold)
                            .foregroundColor(GameColorScheme.accentColor)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(GameColorScheme.buttonBackground)
                    )
                    
                }
            }
            .gameCard()
            
            // Achievements
            VStack(spacing: 15) {
                Text("Achievements")
                    .gameText(size: .medium, weight: .bold)
                    .foregroundColor(GameColorScheme.accentColor)
                
                LazyVStack(spacing: 10) {
                    AchievementRow(
                        title: "First Game",
                        description: "Complete your first game",
                        isUnlocked: gameState.achievements.contains("first_game"),
                        icon: "trophy.fill"
                    )
                    
                    AchievementRow(
                        title: "First Win",
                        description: "Win your first game",
                        isUnlocked: gameState.achievements.contains("first_win"),
                        icon: "star.fill"
                    )
                    
                    AchievementRow(
                        title: "Mafia Master",
                        description: "Win 5 games as Mafia",
                        isUnlocked: gameState.achievements.contains("mafia_master"),
                        icon: "person.fill.badge.minus"
                    )
                    
                    AchievementRow(
                        title: "Villager Hero",
                        description: "Win 5 games as Villager",
                        isUnlocked: gameState.achievements.contains("villager_hero"),
                        icon: "person.fill"
                    )
                    
                    AchievementRow(
                        title: "Game Master",
                        description: "Play 10 games total",
                        isUnlocked: gameState.achievements.contains("game_master"),
                        icon: "crown.fill"
                    )
                    
                    AchievementRow(
                        title: "Perfect Detective",
                        description: "Win 3 games as Villager",
                        isUnlocked: gameState.achievements.contains("perfect_detective"),
                        icon: "magnifyingglass"
                    )
                }
            }
            .gameCard()
        }
    }
    }


// MARK: - Achievement Row
struct AchievementRow: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? GameColorScheme.accentColor : GameColorScheme.secondaryText)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .gameText(size: .small, weight: .bold)
                    .foregroundColor(isUnlocked ? GameColorScheme.primaryText : GameColorScheme.secondaryText)
                
                Text(description)
                    .gameText(size: .small, weight: .regular)
                    .foregroundColor(GameColorScheme.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                .font(.title3)
                .foregroundColor(isUnlocked ? GameColorScheme.successColor : GameColorScheme.secondaryText)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isUnlocked ? GameColorScheme.accentColor.opacity(0.1) : GameColorScheme.overlayBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isUnlocked ? GameColorScheme.accentColor : GameColorScheme.borderColor, lineWidth: 1)
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
    }


struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        gameState.totalGames = 10
        gameState.mafiaWins = 4
        gameState.villagerWins = 6
        
        return StatisticsView(gameState: gameState)
    }
    }



import SwiftUI

struct ResultsView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var geminiService = GeminiService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var narrationText = ""
    @State private var showingMainMenu = false
    @State private var showingNextRound = false
    @State private var revealAnimations: [UUID: Bool] = [:]
    @State private var currentRevealIndex = 0
    @State private var isRevealing = false
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            ScrollView {
                HStack(spacing: 20) {
                    // Left side - Results and Info
                    VStack(spacing: 10) {
                    // Header
                    HStack {
                        Button("Menu") {
                            showingMainMenu = true
                        }
                        .gameButton(isPrimary: false)
                        
                        Spacer()
                        
                        Text("Game Results")
                            .gameText(size: .large, weight: .bold)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Button("Menu") {
                            showingMainMenu = true
                        }
                        .gameButton(isPrimary: false)
                        .opacity(0)
                    }
                    .padding(.top, 20)
                    
                    // Winner Announcement
                    VStack(spacing: 15) {
                        Text("Winner: \(gameState.winner)")
                            .gameText(size: .large, weight: .bold)
                            .foregroundColor(getWinnerColor())
                            .multilineTextAlignment(.center)
                        
                        Text(getWinnerMessage())
                            .gameText(size: .medium, weight: .regular)
                            .foregroundColor(GameColorScheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .gameCard()
                    
                    // Narration
                    if !narrationText.isEmpty {
                        ScrollView {
                            Text(narrationText)
                                .gameText(size: .medium, weight: .regular)
                                .multilineTextAlignment(.center)
                                .padding()
                                .gameCard()
                        }
                        .frame(maxHeight: 120)
                    }
                    
                    // Game Statistics
                    VStack(spacing: 15) {
                        Text("Game Statistics")
                            .gameText(size: .medium, weight: .bold)
                            .foregroundColor(GameColorScheme.accentColor)
                        
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(gameState.getMafiaPlayers().count)")
                                    .gameText(size: .large, weight: .bold)
                                    .foregroundColor(GameColorScheme.dangerColor)
                                Text("Mafia")
                                    .gameText(size: .small, weight: .regular)
                            }
                            
                            VStack {
                                Text("\(gameState.getVillagerPlayers().count)")
                                    .gameText(size: .large, weight: .bold)
                                    .foregroundColor(GameColorScheme.successColor)
                                Text("Villagers")
                                    .gameText(size: .small, weight: .regular)
                            }
                            
                            VStack {
                                Text("\(gameState.players.count)")
                                    .gameText(size: .large, weight: .bold)
                                    .foregroundColor(GameColorScheme.accentColor)
                                Text("Total")
                                    .gameText(size: .small, weight: .regular)
                            }
                        }
                    }
                    .gameCard()
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        if !isRevealing {
                            Button(action: startReveals) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text("Reveal Roles")
                                }
                            }
                            .gameButton(isPrimary: true)
                        } else {
                            Button(action: nextReveal) {
                                HStack {
                                    Image(systemName: "arrow.right")
                                    Text("Next Reveal")
                                }
                            }
                            .gameButton(isPrimary: true)
                            .disabled(currentRevealIndex >= gameState.players.count)
                        }
                        
                        // Next Round Button
                        Button(action: {
                            // Reset game state for new round
                            gameState.resetGame()
                            showingNextRound = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Next Round")
                            }
                        }
                        .gameButton(isPrimary: false)
                        .disabled(isRevealing && currentRevealIndex < gameState.players.count)
                        
                        // Main Menu Button
                        Button(action: {
                            showingMainMenu = true
                        }) {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("Main Menu")
                            }
                        }
                        .gameButton(isPrimary: false)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Role Reveals
                VStack(spacing: 20) {
                    Text("Role Reveals")
                        .gameText(size: .large, weight: .bold)
                        .foregroundColor(GameColorScheme.accentColor)
                        .padding(.top, 20)
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            ForEach(Array(gameState.players.enumerated()), id: \.element.id) { index, player in
                                RoleRevealCard(
                                    player: player,
                                    isRevealed: revealAnimations[player.id] ?? false,
                                    isAnimating: isRevealing && currentRevealIndex == index
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Устанавливаем landscape ориентацию для экрана результатов
            OrientationManager.setLandscapeOnly()
            print("DEBUG: ResultsView appeared - Winner: '\(gameState.winner)'")
            print("DEBUG: Total games: \(gameState.totalGames), Mafia wins: \(gameState.mafiaWins), Villager wins: \(gameState.villagerWins)")
            
            // Statistics should already be updated before reaching ResultsView
            
            generateResultsNarration()
        }
        .navigationDestination(isPresented: $showingMainMenu) {
            MainMenuView()
        }
        .navigationDestination(isPresented: $showingNextRound) {
            GameSetupView(gameState: gameState)
        }
    }
    
    private func generateResultsNarration() {
        Task {
            let narration = await geminiService.generateGameEndNarration(
                winner: gameState.winner,
                players: gameState.players
            )
            await MainActor.run {
                narrationText = narration
            }
        }
    }
    
    private func getWinnerColor() -> Color {
        switch gameState.winner {
        case "Mafia":
            return GameColorScheme.dangerColor
        case "Villagers":
            return GameColorScheme.successColor
        default:
            return GameColorScheme.accentColor
        }
    }
    
    private func getWinnerMessage() -> String {
        switch gameState.winner {
        case "Mafia":
            return "The shadows have triumphed over the light. The mafia has eliminated all threats and now controls the village."
        case "Villagers":
            return "Justice has been served! The villagers have successfully identified and eliminated the mafia members."
        default:
            return "The game has ended in an unexpected way."
        }
    }
    
    private func startReveals() {
        isRevealing = true
        currentRevealIndex = 0
        nextReveal()
    }
    
    private func nextReveal() {
        if currentRevealIndex < gameState.players.count {
            let player = gameState.players[currentRevealIndex]
            revealAnimations[player.id] = true
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                // Reveal animation
            }
            
            currentRevealIndex += 1
        } else {
            isRevealing = false
        }
    }
    }


// MARK: - Role Reveal Card
struct RoleRevealCard: View {
    let player: Player
    let isRevealed: Bool
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // Player Avatar
            Image(systemName: player.avatar)
                .font(.title2)
                .foregroundColor(GameColorScheme.primaryText)
                .padding(10)
                .background(
                    Circle()
                        .fill(getBackgroundColor())
                        .overlay(
                            Circle()
                                .stroke(getBorderColor(), lineWidth: 2)
                        )
                )
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
            
            // Player Name
            Text(player.name)
                .gameText(size: .small, weight: .bold)
                .multilineTextAlignment(.center)
            
            // Status
            HStack(spacing: 4) {
                Image(systemName: player.isAlive ? "heart.fill" : "heart.slash.fill")
                    .font(.caption)
                Text(player.isAlive ? "Alive" : "Dead")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(player.isAlive ? GameColorScheme.aliveColor : GameColorScheme.deadColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill((player.isAlive ? GameColorScheme.aliveColor : GameColorScheme.deadColor).opacity(0.2))
            )
            
            // Role Reveal
            if isRevealed, let role = player.role {
                VStack(spacing: 6) {
                    Image(systemName: role.icon)
                        .font(.title3)
                        .foregroundColor(role.gameColor)
                    
                    Text(role.rawValue)
                        .gameText(size: .small, weight: .bold)
                        .foregroundColor(role.gameColor)
                        .multilineTextAlignment(.center)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(role.gameColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(role.gameColor, lineWidth: 1)
                        )
                )
                .scaleEffect(isRevealed ? 1.0 : 0.8)
                .opacity(isRevealed ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isRevealed)
            } else {
                // Hidden role
                RoundedRectangle(cornerRadius: 8)
                    .fill(GameColorScheme.overlayBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GameColorScheme.borderColor, lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "questionmark")
                            .font(.title3)
                            .foregroundColor(GameColorScheme.secondaryText)
                    )
                    .frame(height: 60)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(GameColorScheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getCardBorderColor(), lineWidth: 1)
                )
        )
        .scaleEffect(isRevealed ? 1.0 : 0.9)
        .opacity(isRevealed ? 1.0 : 0.7)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isRevealed)
    }
    
    private func getBackgroundColor() -> Color {
        if isRevealed {
            return player.role?.gameColor.opacity(0.2) ?? GameColorScheme.buttonBackground
        } else {
            return GameColorScheme.buttonBackground
        }
    }
    
    private func getBorderColor() -> Color {
        if isRevealed {
            return player.role?.gameColor ?? GameColorScheme.borderColor
        } else {
            return GameColorScheme.borderColor
        }
    }
    
    private func getCardBorderColor() -> Color {
        if isRevealed {
            return player.role?.gameColor ?? GameColorScheme.borderColor
        } else {
            return GameColorScheme.borderColor
        }
    }
    }


struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        gameState.addPlayer(Player(name: "Alice", avatar: "person.fill"))
        gameState.addPlayer(Player(name: "Bob", avatar: "star.fill"))
        gameState.addPlayer(Player(name: "Charlie", avatar: "heart.fill"))
        gameState.assignRoles()
        gameState.winner = "Villagers"
        
        return ResultsView(gameState: gameState)
    }
}

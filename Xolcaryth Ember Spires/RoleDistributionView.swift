
import SwiftUI

struct RoleDistributionView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var geminiService = GeminiService()
    @StateObject private var soundManager = SoundManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentDealingIndex = 0
    @State private var isDealing = false
    @State private var showingRole = false
    @State private var narrationText = ""
    @State private var showingNightCycle = false
    @State private var dealtCards: [UUID: Bool] = [:]
    @State private var isGeneratingNarration = false
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            ScrollView {
                HStack(spacing: 20) {
                    // Left side - Narration and Controls
                    VStack(spacing: 10) {
                    // Header
                    HStack {
                        Button("Back") {
                            soundManager.playButtonTap()
                            dismiss()
                        }
                        .gameButton(isPrimary: false)
                        .opacity(isDealing ? 0.5 : 1.0)
                        .disabled(isDealing)
                        
                        Spacer()
                        
                        Text("Role Distribution")
                            .gameText(size: .large, weight: .bold)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Button("Back") {
                            dismiss()
                        }
                        .gameButton(isPrimary: false)
                        .opacity(0)
                    }
                    .padding(.top, 20)
                
                    // Narration Text
                    if !narrationText.isEmpty {
                        ScrollView {
                            Text(narrationText)
                                .gameText(size: .medium, weight: .regular)
                                .multilineTextAlignment(.center)
                                .padding()
                                .gameCard()
                        }
                        .frame(maxHeight: 200)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        if !isDealing && !showingRole {
                            // Start dealing button
                            Button(action: startDealing) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Deal Roles")
                                }
                            }
                            .gameButton(isPrimary: true)
                            .disabled(geminiService.isLoading || isGeneratingNarration)
                        } else if isDealing && !showingRole {
                            // Deal next card button
                            Button(action: dealNextCard) {
                                HStack {
                                    Image(systemName: "arrow.right")
                                    Text("Deal Next Card")
                                }
                            }
                            .gameButton(isPrimary: true)
                            .disabled(geminiService.isLoading)
                        } else if showingRole && currentDealingIndex < gameState.players.count - 1 {
                            // Next player button
                            Button(action: nextPlayer) {
                                HStack {
                                    Image(systemName: "arrow.right")
                                    Text("Next Player")
                                }
                            }
                            .gameButton(isPrimary: true)
                        } else if showingRole && currentDealingIndex == gameState.players.count - 1 {
                            // Start game button
                            Button(action: startGame) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start Game")
                                }
                            }
                            .gameButton(isPrimary: true)
                        }
                        
                        // Loading indicator
                        if geminiService.isLoading || isGeneratingNarration {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: GameColorScheme.accentColor))
                                Text("Generating narration...")
                                    .gameText(size: .small, weight: .regular)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Role Cards Area
                VStack(spacing: 20) {
                    if isDealing {
                        // Show current player info
                        if currentDealingIndex < gameState.players.count {
                            let currentPlayer = gameState.players[currentDealingIndex]
                            
                            VStack(spacing: 10) {
                                Text("Player \(currentDealingIndex + 1) of \(gameState.players.count)")
                                    .gameText(size: .medium, weight: .bold)
                                    .foregroundColor(GameColorScheme.accentColor)
                                
                                Text(currentPlayer.name)
                                    .gameText(size: .small, weight: .regular)
                                    .foregroundColor(GameColorScheme.secondaryText)
                            }
                            .padding(.bottom, 10)
                        }
                        
                        // Show current player's card being dealt
                        if currentDealingIndex < gameState.players.count {
                            let currentPlayer = gameState.players[currentDealingIndex]
                            RoleCardView(
                                player: currentPlayer,
                                isDealt: dealtCards[currentPlayer.id] ?? false,
                                isShowing: showingRole
                            )
                            .scaleEffect(showingRole ? 1.0 : 0.8)
                            .opacity(showingRole ? 1.0 : 0.7)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingRole)
                        }
                    } else {
                        // Static role cards - show all players
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(Array(gameState.players.enumerated()), id: \.element.id) { index, player in
                                    RoleCardView(
                                        player: player,
                                        isDealt: true,
                                        isShowing: true
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
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
            // Устанавливаем landscape ориентацию для распределения ролей
            OrientationManager.setLandscapeOnly()
            // Only generate narration if not already generated
            if narrationText.isEmpty && !isGeneratingNarration {
                generateInitialNarration()
            }
        }
        .navigationDestination(isPresented: $showingNightCycle) {
            NightCycleView(gameState: gameState)
        }
    }
    
    private func generateInitialNarration() {
        // Prevent multiple simultaneous generation calls
        guard !isGeneratingNarration else { return }
        
        isGeneratingNarration = true
        Task {
            let narration = await geminiService.generateRoleAssignment(for: gameState.players)
            await MainActor.run {
                narrationText = narration
                isGeneratingNarration = false
            }
        }
    }
    
    private func startDealing() {
        soundManager.playGameStart()
        isDealing = true
        currentDealingIndex = 0
        dealtCards = [:]
        gameState.assignRoles()
        
        // Reset narration for new game
        narrationText = ""
        isGeneratingNarration = false
        
        // Start dealing the first card
        dealNextCard()
    }
    
    private func dealNextCard() {
        print("Dealing card for player \(currentDealingIndex) of \(gameState.players.count)")
        if currentDealingIndex < gameState.players.count {
            soundManager.playCardDeal()
            dealtCards[gameState.players[currentDealingIndex].id] = true
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                // Card dealing animation
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("Showing role for player \(currentDealingIndex)")
                showingRole = true
            }
        }
    }
    
    private func nextPlayer() {
        print("Next player called. Current index: \(currentDealingIndex), Total players: \(gameState.players.count)")
        showingRole = false
        currentDealingIndex += 1
        
        if currentDealingIndex < gameState.players.count {
            // Continue dealing to next player
            print("Continuing to next player: \(currentDealingIndex)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dealNextCard()
            }
        } else {
            // All players have been dealt cards
            print("All players dealt cards. Ending dealing phase.")
            isDealing = false
        }
    }
    
    private func startGame() {
        soundManager.playGameStart()
        gameState.currentPhase = .night
        showingNightCycle = true
    }
    }


// MARK: - Role Card View
struct RoleCardView: View {
    let player: Player
    let isDealt: Bool
    let isShowing: Bool
    
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 10) {
            // Player Avatar
            Image(systemName: player.avatar)
                .font(.system(size: 40))
                .foregroundColor(GameColorScheme.accentColor)
                .padding(15)
                .background(
                    Circle()
                        .fill(GameColorScheme.buttonBackground)
                        .overlay(
                            Circle()
                                .stroke(GameColorScheme.borderColor, lineWidth: 2)
                        )
                )
            
            // Player Name
            Text(player.name)
                .gameText(size: .small, weight: .bold)
                .multilineTextAlignment(.center)
            
            // Role Card (only show when dealt and showing)
            if isDealt && isShowing {
                VStack(spacing: 8) {
                    if let role = player.role {
                        // Role Icon
                        Image(systemName: role.icon)
                            .font(.title2)
                            .foregroundColor(role.gameColor)
                        
                        // Role Name
                        Text(role.rawValue)
                            .gameText(size: .small, weight: .bold)
                            .foregroundColor(role.gameColor)
                        
                        // Role Description (truncated)
                        Text(role.description)
                            .gameText(size: .small, weight: .regular)
                            .foregroundColor(GameColorScheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GameColorScheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(player.role?.gameColor ?? GameColorScheme.borderColor, lineWidth: 2)
                        )
                )
                .scaleEffect(isShowing ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowing)
            } else if isDealt {
                // Card back when dealt but not showing
                RoundedRectangle(cornerRadius: 12)
                    .fill(GameColorScheme.buttonBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(GameColorScheme.borderColor, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "questionmark")
                            .font(.title)
                            .foregroundColor(GameColorScheme.accentColor)
                    )
                    .frame(width: 120, height: 80)
            } else {
                // Empty card slot
                RoundedRectangle(cornerRadius: 12)
                    .fill(GameColorScheme.overlayBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(GameColorScheme.borderColor, lineWidth: 1)
                    )
                    .frame(width: 120, height: 80)
            }
        }
        .frame(width: 140)
        .scaleEffect(isDealt ? 1.0 : 0.8)
        .opacity(isDealt ? 1.0 : 0.6)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isDealt)
    }
    }


struct RoleDistributionView_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        gameState.addPlayer(Player(name: "Alice", avatar: "person.fill"))
        gameState.addPlayer(Player(name: "Bob", avatar: "star.fill"))
        gameState.addPlayer(Player(name: "Charlie", avatar: "heart.fill"))
        
        return RoleDistributionView(gameState: gameState)
    }
}

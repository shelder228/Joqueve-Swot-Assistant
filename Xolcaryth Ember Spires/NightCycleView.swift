
import SwiftUI

struct NightCycleView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var geminiService = GeminiService()
    @StateObject private var soundManager = SoundManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentActionPhase = 0
    @State private var narrationText = ""
    @State private var selectedTarget: Player?
    @State private var mafiaTarget: Player?
    @State private var doctorTarget: Player?
    @State private var detectiveTarget: Player?
    @State private var showingDayCycle = false
    @State private var showingResults = false
    @State private var isProcessingActions = false
    @State private var actionAnimations: [UUID: Bool] = [:]
    
    private let actionPhases = ["Mafia", "Doctor", "Detective"]
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            ScrollView {
                HStack(spacing: 20) {
                    // Left side - Controls and Info
                    VStack(spacing: 10) {
                    // Header
                    HStack {
                        Spacer()
                        
                        Text("Night Phase")
                            .gameText(size: .large, weight: .bold)
                        
                        Spacer()
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
                        .frame(maxHeight: 120)
                    }
                    
                    // Current Action Phase
                    if currentActionPhase < actionPhases.count {
                        VStack(spacing: 15) {
                            Text("\(actionPhases[currentActionPhase]) Action")
                                .gameText(size: .medium, weight: .bold)
                                .foregroundColor(GameColorScheme.accentColor)
                            
                            Text(getActionDescription())
                                .gameText(size: .small, weight: .regular)
                                .foregroundColor(GameColorScheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .gameCard()
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        if currentActionPhase < actionPhases.count {
                            // Confirm Action Button
                            Button(action: {
                                soundManager.playButtonHaptic()
                                confirmAction()
                            }) {
                                HStack {
                                    Image(systemName: getActionIcon())
                                    Text("Confirm \(actionPhases[currentActionPhase]) Action")
                                }
                            }
                            .gameButton(isPrimary: true)
                            .disabled(selectedTarget == nil || isProcessingActions)
                            
                            // Skip Action Button
                            Button(action: {
                                soundManager.playButtonHaptic()
                                skipAction()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right")
                                    Text("Skip \(actionPhases[currentActionPhase]) Action")
                                }
                            }
                            .gameButton(isPrimary: false)
                            .disabled(isProcessingActions)
                        } else {
                            // Process Actions Button
                            Button(action: {
                                soundManager.playPhaseTransitionHaptic()
                                processActions()
                            }) {
                                HStack {
                                    Image(systemName: "moon.fill")
                                    Text("Process Night Actions")
                                }
                            }
                            .gameButton(isPrimary: true)
                            .disabled(isProcessingActions)
                        }
                        
                        // Loading indicator
                        if geminiService.isLoading || isProcessingActions {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: GameColorScheme.accentColor))
                                Text("Processing...")
                                    .gameText(size: .small, weight: .regular)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Players Grid
                VStack(spacing: 20) {
                    Text("Select Target")
                        .gameText(size: .large, weight: .bold)
                        .foregroundColor(GameColorScheme.accentColor)
                        .padding(.top, 20)
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                            ForEach(gameState.getAlivePlayers()) { player in
                                PlayerActionCard(
                                    player: player,
                                    isSelected: selectedTarget?.id == player.id,
                                    canSelect: canSelectPlayer(player),
                                    actionType: getCurrentActionType(),
                                    isAnimating: actionAnimations[player.id] ?? false
                                ) {
                                    selectPlayer(player)
                                }
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
            // Устанавливаем landscape ориентацию для ночной фазы
            OrientationManager.setLandscapeOnly()
            generateNightNarration()
        }
        .navigationDestination(isPresented: $showingDayCycle) {
            DayCycleView(gameState: gameState)
        }
        .navigationDestination(isPresented: $showingResults) {
            ResultsView(gameState: gameState)
        }
    }
    
    private func generateNightNarration() {
        Task {
            let narration = await geminiService.generateNightNarration(for: .night, players: gameState.getAlivePlayers())
            await MainActor.run {
                narrationText = narration
            }
        }
    }
    
    private func getActionDescription() -> String {
        switch currentActionPhase {
        case 0: // Mafia
            return "Choose a target to eliminate. Work together with other mafia members."
        case 1: // Doctor
            return "Choose a player to protect from elimination. You cannot protect yourself."
        case 2: // Detective
            return "Choose a player to investigate. You'll learn if they're mafia or not."
        default:
            return "All actions have been completed."
        }
    }
    
    private func getCurrentActionType() -> ActionType {
        switch currentActionPhase {
        case 0: return .mafia
        case 1: return .doctor
        case 2: return .detective
        default: return .none
        }
    }
    
    private func getActionIcon() -> String {
        switch currentActionPhase {
        case 0: return "person.fill.badge.minus"
        case 1: return "cross.fill"
        case 2: return "magnifyingglass"
        default: return "checkmark"
        }
    }
    
    private func canSelectPlayer(_ player: Player) -> Bool {
        switch currentActionPhase {
        case 0: // Mafia
            return player.role != .mafia
        case 1: // Doctor
            return player.id != getCurrentPlayer()?.id // Can't protect self
        case 2: // Detective
            return true
        default:
            return false
        }
    }
    
    private func getCurrentPlayer() -> Player? {
        // In a real game, this would be the current player's turn
        // For now, we'll use the first player of each role type
        switch currentActionPhase {
        case 0: // Mafia
            return gameState.getMafiaPlayers().first
        case 1: // Doctor
            return gameState.players.first { $0.role == .doctor && $0.isAlive }
        case 2: // Detective
            return gameState.players.first { $0.role == .detective && $0.isAlive }
        default:
            return nil
        }
    }
    
    private func selectPlayer(_ player: Player) {
        selectedTarget = player
        soundManager.playCardHaptic()
        
        // Animate selection
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            actionAnimations[player.id] = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            actionAnimations[player.id] = false
        }
    }
    
    private func confirmAction() {
        guard let target = selectedTarget else { return }
        
        switch currentActionPhase {
        case 0: // Mafia
            mafiaTarget = target
        case 1: // Doctor
            doctorTarget = target
        case 2: // Detective
            detectiveTarget = target
        default:
            break
        }
        
        nextActionPhase()
    }
    
    private func skipAction() {
        nextActionPhase()
    }
    
    private func nextActionPhase() {
        selectedTarget = nil
        currentActionPhase += 1
    }
    
    private func processActions() {
        isProcessingActions = true
        
        // Process mafia elimination
        if let target = mafiaTarget {
            // Check if doctor protected the target
            if doctorTarget?.id != target.id {
                gameState.eliminatedPlayer = target
                // Find and update the player in gameState
                if let playerIndex = gameState.players.firstIndex(where: { $0.id == target.id }) {
                    gameState.players[playerIndex].isAlive = false
                }
            }
        }
        
        // Process detective investigation
        if let target = detectiveTarget {
            // Find and update the player in gameState
            if let playerIndex = gameState.players.firstIndex(where: { $0.id == target.id }) {
                gameState.players[playerIndex].isInvestigated = true
            }
        }
        
        // Add game action
        let action = GameAction(
            phase: .night,
            description: "Night actions completed",
            playerName: nil
        )
        gameState.gameHistory.append(action)
        
        // Check win condition after night actions
        gameState.updateGameStatistics()
        
        // Reset night action states
        mafiaTarget = nil
        doctorTarget = nil
        detectiveTarget = nil
        selectedTarget = nil
        currentActionPhase = 0
        
        // Check if game ended after night actions
        if !gameState.winner.isEmpty {
            print("DEBUG: Game ended after night actions with winner: \(gameState.winner)")
            // Game ended, navigate to results
            showingResults = true
            return
        }
        
        // Reset discussion timer for new day phase
        // Load discussion time from settings
        let savedDiscussionTime = UserDefaults.standard.integer(forKey: "discussionTime")
        gameState.discussionTimeRemaining = savedDiscussionTime > 0 ? savedDiscussionTime : 300
        
        // Transition to day phase immediately
        gameState.currentPhase = .day
        showingDayCycle = true
    }
    }


// MARK: - Action Types
enum ActionType {
    case mafia, doctor, detective, none
    }


// MARK: - Player Action Card
struct PlayerActionCard: View {
    let player: Player
    let isSelected: Bool
    let canSelect: Bool
    let actionType: ActionType
    let isAnimating: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Player Avatar
                Image(systemName: player.avatar)
                    .font(.title2)
                    .foregroundColor(getAvatarColor())
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
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
                
                // Player Name
                Text(player.name)
                    .gameText(size: .small, weight: .medium)
                    .multilineTextAlignment(.center)
                
                // Role Indicator (if revealed)
                if let role = player.role {
                    HStack(spacing: 4) {
                        Image(systemName: role.icon)
                            .font(.caption)
                        Text(role.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(role.gameColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(role.gameColor.opacity(0.2))
                    )
                }
                
                // Status Indicators
                HStack(spacing: 4) {
                    if player.isProtected {
                        Image(systemName: "shield.fill")
                            .font(.caption)
                            .foregroundColor(GameColorScheme.protectedColor)
                    }
                    if player.isInvestigated {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundColor(GameColorScheme.investigatedColor)
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(getCardBackgroundColor())
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(getCardBorderColor(), lineWidth: 2)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .disabled(!canSelect)
        .opacity(canSelect ? 1.0 : 0.5)
    }
    
    private func getAvatarColor() -> Color {
        if isSelected {
            return GameColorScheme.accentColor
        } else if !canSelect {
            return GameColorScheme.secondaryText
        } else {
            return GameColorScheme.primaryText
        }
    }
    
    private func getBackgroundColor() -> Color {
        if isSelected {
            return GameColorScheme.accentColor.opacity(0.2)
        } else {
            return GameColorScheme.buttonBackground
        }
    }
    
    private func getBorderColor() -> Color {
        if isSelected {
            return GameColorScheme.accentColor
        } else {
            return GameColorScheme.borderColor
        }
    }
    
    private func getCardBackgroundColor() -> Color {
        if isSelected {
            return GameColorScheme.accentColor.opacity(0.1)
        } else {
            return GameColorScheme.cardBackground
        }
    }
    
    private func getCardBorderColor() -> Color {
        if isSelected {
            return GameColorScheme.accentColor
        } else {
            return GameColorScheme.borderColor
        }
    }
    }


struct NightCycleView_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        gameState.addPlayer(Player(name: "Alice", avatar: "person.fill"))
        gameState.addPlayer(Player(name: "Bob", avatar: "star.fill"))
        gameState.addPlayer(Player(name: "Charlie", avatar: "heart.fill"))
        gameState.assignRoles()
        
        return NightCycleView(gameState: gameState)
    }
}

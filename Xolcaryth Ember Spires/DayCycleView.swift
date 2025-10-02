
import SwiftUI

struct DayCycleView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var geminiService = GeminiService()
    @StateObject private var soundManager = SoundManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var narrationText = ""
    @State private var discussionPrompt = ""
    @State private var selectedVote: Player?
    @State private var showingVotingResults = false
    @State private var showingResults = false
    @State private var showingNightCycle = false
    @State private var isVoting = false
    @State private var voteAnimations: [UUID: Bool] = [:]
    @State private var timer: Timer?
    @State private var isTie = false
    @State private var isProcessingVoting = false
    @State private var isGeneratingContent = false
    @State private var maxDiscussionTime = 300
    
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
                        
                        Text("Day Phase")
                            .gameText(size: .large, weight: .bold)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Timer Bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("Discussion Time")
                                .gameText(size: .small, weight: .bold)
                            
                            Spacer()
                            
                            Text(formatTime(gameState.discussionTimeRemaining))
                                .gameText(size: .medium, weight: .bold)
                                .foregroundColor(GameColorScheme.timerColor)
                        }
                        
                        ProgressView(value: Double(min(max(gameState.discussionTimeRemaining, 0), maxDiscussionTime)), total: Double(maxDiscussionTime))
                            .progressViewStyle(LinearProgressViewStyle(tint: GameColorScheme.timerColor))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    }
                    .gameCard()
                    
                    // Narration Text
                    if !narrationText.isEmpty {
                        ScrollView {
                            Text(narrationText)
                                .gameText(size: .small, weight: .regular)
                                .multilineTextAlignment(.center)
                                .padding()
                                .gameCard()
                        }
                        .frame(maxHeight: 100)
                    }
                    
                    // Discussion Prompt (only during discussion phase)
                    if !discussionPrompt.isEmpty && !isVoting {
                        VStack(spacing: 10) {
                            Text("Discussion Prompt")
                                .gameText(size: .medium, weight: .bold)
                                .foregroundColor(GameColorScheme.accentColor)
                            
                            Text(discussionPrompt)
                                .gameText(size: .small, weight: .regular)
                                .multilineTextAlignment(.center)
                        }
                        .gameCard()
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        if !isVoting {
                            // Start Voting Button
                            Button(action: {
                                soundManager.playButtonHaptic()
                                startVoting()
                            }) {
                                HStack {
                                    Image(systemName: "hand.raised.fill")
                                    Text("Start Voting")
                                }
                            }
                            .gameButton(isPrimary: true)
                            .disabled(geminiService.isLoading)
                        } else {
                            // Cast Vote Button
                            Button(action: {
                                soundManager.playVoteHaptic()
                                castVote()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Cast Vote")
                                }
                            }
                            .gameButton(isPrimary: true)
                            .disabled(selectedVote == nil)
                            
                            // End Voting Button
                            Button(action: {
                                soundManager.playButtonHaptic()
                                isTie ? handleTieVote() : endVoting()
                            }) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text(isTie ? "Tie - Vote Again" : "End Voting")
                                }
                            }
                            .gameButton(isPrimary: false)
                        }
                        
                        // Tie message
                        if isTie {
                            Text("All votes are equal! Please vote again to break the tie.")
                                .gameText(size: .small, weight: .medium)
                                .foregroundColor(GameColorScheme.dangerColor)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(GameColorScheme.dangerColor.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(GameColorScheme.dangerColor, lineWidth: 1)
                                        )
                                )
                        }
                        
                        // Loading indicator
                        if geminiService.isLoading || isGeneratingContent {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: GameColorScheme.accentColor))
                                Text("Generating content...")
                                    .gameText(size: .small, weight: .regular)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Players Grid for Voting
                VStack(spacing: 20) {
                    Text("Vote for Elimination")
                        .gameText(size: .large, weight: .bold)
                        .foregroundColor(GameColorScheme.accentColor)
                        .padding(.top, 20)
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                            ForEach(gameState.getAlivePlayers()) { player in
                                VotingCard(
                                    player: player,
                                    isSelected: selectedVote?.id == player.id,
                                    voteCount: gameState.votes[player.id.uuidString] ?? 0,
                                    isAnimating: voteAnimations[player.id] ?? false
                                ) {
                                    selectVote(player)
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
            // Устанавливаем landscape ориентацию для дневной фазы
            OrientationManager.setLandscapeOnly()
            // Check win condition first
            gameState.updateGameStatistics()
            
            // If game ended, navigate to results
            if !gameState.winner.isEmpty {
                showingResults = true
                return
            }
            
            // Reset discussion timer to ensure it starts fresh
            // Load discussion time from settings
            let savedDiscussionTime = UserDefaults.standard.integer(forKey: "discussionTime")
            let discussionTime = savedDiscussionTime > 0 ? savedDiscussionTime : 300
            gameState.discussionTimeRemaining = discussionTime
            maxDiscussionTime = discussionTime
            
            // Reset content for new day phase
            narrationText = ""
            discussionPrompt = ""
            isGeneratingContent = false
            
            // Generate content for new day
            generateDayContent()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .sheet(isPresented: $showingVotingResults) {
            VotingResultsView(gameState: gameState, onComplete: {
                // Reset voting results state
                showingVotingResults = false
                isProcessingVoting = false
                
                // Check if game ended or should continue to night
                if !gameState.winner.isEmpty {
                    showingResults = true
                } else {
                    // Reset day phase states and transition to night
                    selectedVote = nil
                    isVoting = false
                    isTie = false
                    voteAnimations = [:]
                    
                    // Reset content for next day phase
                    narrationText = ""
                    discussionPrompt = ""
                    isGeneratingContent = false
                    
                    showingNightCycle = true
                }
            })
            .interactiveDismissDisabled()
        }
        .navigationDestination(isPresented: $showingResults) {
            ResultsView(gameState: gameState)
        }
        .navigationDestination(isPresented: $showingNightCycle) {
            NightCycleView(gameState: gameState)
        }
    }
    
    private func generateDayContent() {
        // Prevent multiple simultaneous generation calls
        guard !isGeneratingContent else { return }
        
        isGeneratingContent = true
        Task {
            let narration = await geminiService.generateDayNarration(
                for: .day,
                players: gameState.getAlivePlayers(),
                eliminatedPlayer: gameState.eliminatedPlayer
            )
            let prompt = await geminiService.generateDiscussionPrompt(for: gameState.getAlivePlayers())
            
            await MainActor.run {
                narrationText = narration
                discussionPrompt = prompt
                isGeneratingContent = false
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if gameState.discussionTimeRemaining > 0 {
                gameState.discussionTimeRemaining -= 1
            } else {
                stopTimer()
                // Auto-start voting when time runs out
                if !isVoting {
                    startVoting()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func startVoting() {
        isVoting = true
        stopTimer()
    }
    
    private func selectVote(_ player: Player) {
        selectedVote = player
        soundManager.playCardHaptic()
        
        // Animate selection
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            voteAnimations[player.id] = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            voteAnimations[player.id] = false
        }
    }
    
    private func castVote() {
        guard let target = selectedVote else { return }
        
        // In a real game, this would be the current player's vote
        // For now, we'll simulate voting
        let currentVotes = gameState.votes[target.id.uuidString] ?? 0
        gameState.votes[target.id.uuidString] = currentVotes + 1
        
        // Reset selection
        selectedVote = nil
    }
    
    private func endVoting() {
        // Prevent multiple calls
        guard !isProcessingVoting else { return }
        
        print("DEBUG: endVoting called")
        print("DEBUG: Current votes: \(gameState.votes)")
        
        isProcessingVoting = true
        
        // Check if there's a tie (multiple players with same max votes)
        let voteValues = Array(gameState.votes.values)
        if !voteValues.isEmpty {
            let maxVotes = voteValues.max() ?? 0
            let playersWithMaxVotes = gameState.votes.filter { $0.value == maxVotes }
            
            // If more than one player has the maximum votes, it's a tie
            if playersWithMaxVotes.count > 1 {
                print("DEBUG: Tie detected - \(playersWithMaxVotes.count) players with \(maxVotes) votes each")
                isTie = true
                isProcessingVoting = false
                return
            }
        }
        
        // Reset tie state if voting can proceed
        isTie = false
        showingVotingResults = true
        print("DEBUG: showingVotingResults set to true")
    }
    
    private func handleTieVote() {
        print("DEBUG: handleTieVote called")
        
        // Clear all votes for tie-breaking
        gameState.votes.removeAll()
        
        // Reset tie state
        isTie = false
        
        // Reset selection
        selectedVote = nil
        
        // Reset processing state
        isProcessingVoting = false
        
        print("DEBUG: Tie vote handled - votes cleared, ready for new voting")
    }
    }


// MARK: - Voting Card
struct VotingCard: View {
    let player: Player
    let isSelected: Bool
    let voteCount: Int
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
                
                // Vote Count
                if voteCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.caption)
                        Text("\(voteCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(GameColorScheme.voteColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(GameColorScheme.voteColor.opacity(0.2))
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
    }
    
    private func getAvatarColor() -> Color {
        if isSelected {
            return GameColorScheme.accentColor
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


// MARK: - Voting Results View
struct VotingResultsView: View {
    @ObservedObject var gameState: GameState
    let onComplete: () -> Void
    @StateObject private var geminiService = GeminiService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var narrationText = ""
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Voting Results")
                        .gameText(size: .large, weight: .bold)
                        .padding(.top, 20)
                    
                    // Narration
                    if !narrationText.isEmpty {
                        Text(narrationText)
                            .gameText(size: .medium, weight: .regular)
                            .multilineTextAlignment(.center)
                            .padding()
                            .gameCard()
                            .padding(.horizontal, 20)
                    }
                    
                    // Vote Results
                    VStack(spacing: 15) {
                        Text("Vote Count")
                            .gameText(size: .medium, weight: .bold)
                            .foregroundColor(GameColorScheme.accentColor)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                            ForEach(gameState.getAlivePlayers()) { player in
                                let voteCount = gameState.votes[player.id.uuidString] ?? 0
                                
                                VStack(spacing: 8) {
                                    Image(systemName: player.avatar)
                                        .font(.title2)
                                        .foregroundColor(GameColorScheme.primaryText)
                                    
                                    Text(player.name)
                                        .gameText(size: .small, weight: .medium)
                                    
                                    Text("\(voteCount) votes")
                                        .gameText(size: .small, weight: .bold)
                                        .foregroundColor(GameColorScheme.voteColor)
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(GameColorScheme.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(GameColorScheme.borderColor, lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .gameCard()
                    .padding(.horizontal, 20)
                    
                    // Continue Button
                    Button(action: {
                        processVotingResults()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right")
                            Text("Continue")
                        }
                    }
                    .gameButton(isPrimary: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            generateVotingNarration()
        }
    }
    
    private func generateVotingNarration() {
        Task {
            let narration = await geminiService.generateVotingResults(
                for: gameState.votes,
                players: gameState.getAlivePlayers()
            )
            await MainActor.run {
                narrationText = narration
            }
        }
    }
    
    private func processVotingResults() {
        print("DEBUG: processVotingResults called")
        
        // Find player with most votes
        let maxVotes = gameState.votes.values.max() ?? 0
        let eliminatedPlayer = gameState.votes.first { $0.value == maxVotes }?.key
        
        print("DEBUG: Max votes: \(maxVotes)")
        print("DEBUG: Eliminated player ID: \(eliminatedPlayer ?? "none")")
        
        if let playerId = eliminatedPlayer,
           let playerIndex = gameState.players.firstIndex(where: { $0.id.uuidString == playerId }) {
            gameState.players[playerIndex].isAlive = false
            gameState.eliminatedPlayer = gameState.players[playerIndex]
            print("DEBUG: Player \(gameState.players[playerIndex].name) eliminated")
        }
        
        // Update game statistics and check win condition
        print("DEBUG: Before updateGameStatistics - Winner: '\(gameState.winner)'")
        print("DEBUG: Alive players: \(gameState.getAlivePlayers().count)")
        print("DEBUG: Mafia players: \(gameState.getMafiaPlayers().count)")
        print("DEBUG: Villager players: \(gameState.getVillagerPlayers().count)")
        
        gameState.updateGameStatistics()
        
        print("DEBUG: After updateGameStatistics - Winner: '\(gameState.winner)'")
        
        // Only navigate to results if there's a winner
        if !gameState.winner.isEmpty {
            print("DEBUG: Game ended with winner: \(gameState.winner), navigating to results")
            // Close the sheet first, then navigate
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onComplete()
            }
        } else {
            print("DEBUG: Game continues, transitioning to night phase")
            // Reset votes and transition to night phase
            gameState.votes = [:]
            gameState.eliminatedPlayer = nil
            gameState.currentPhase = .night
            
            // Close the sheet and call onComplete to transition to night phase
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onComplete()
            }
        }
    }
    }


struct DayCycleView_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        gameState.addPlayer(Player(name: "Alice", avatar: "person.fill"))
        gameState.addPlayer(Player(name: "Bob", avatar: "star.fill"))
        gameState.addPlayer(Player(name: "Charlie", avatar: "heart.fill"))
        gameState.assignRoles()
        
        return DayCycleView(gameState: gameState)
    }
    }


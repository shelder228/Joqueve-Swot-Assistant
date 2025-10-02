
import SwiftUI

struct GameSetupView: View {
    @ObservedObject var gameState: GameState
    @StateObject private var soundManager = SoundManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var playerCount = 6
    @State private var playerName = ""
    @State private var selectedAvatar = AvatarOption.allAvatars[0]
    @State private var showingRoleDistribution = false
    @State private var currentPlayerIndex = 0
    
    private let minPlayers = 4
    private let maxPlayers = 12
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            ScrollView {
                HStack(spacing: 20) {
                    // Left side - Player Count and Current Player Setup
                    VStack(spacing: 10) {
                    // Header
                    HStack {
                        NavigationLink(destination: MainMenuView()) {
                            Text("Cancel")
                        }
                        .gameButton(isPrimary: false)
                        
                        Spacer()
                        
                        Text("Game Setup")
                            .gameText(size: .medium, weight: .bold)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        NavigationLink(destination: MainMenuView()) {
                            Text("Cancel")
                        }
                        .gameButton(isPrimary: false)
                        .opacity(0)
                    }
                    .padding(.top, 10)
                    
                    // Player Count Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Number of Players")
                            .gameText(size: .small, weight: .bold)
                        
                        HStack {
                            Button(action: {
                                soundManager.playButtonTap()
                                if playerCount > minPlayers {
                                    playerCount -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                            }
                            .disabled(playerCount <= minPlayers)
                            .foregroundColor(playerCount <= minPlayers ? GameColorScheme.secondaryText : GameColorScheme.accentColor)
                            
                            Spacer()
                            
                            Text("\(playerCount)")
                                .gameText(size: .medium, weight: .bold)
                                .foregroundColor(GameColorScheme.accentColor)
                            
                            Spacer()
                            
                            Button(action: {
                                soundManager.playButtonTap()
                                if playerCount < maxPlayers {
                                    playerCount += 1
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                            }
                            .disabled(playerCount >= maxPlayers)
                            .foregroundColor(playerCount >= maxPlayers ? GameColorScheme.secondaryText : GameColorScheme.accentColor)
                        }
                        .padding(.horizontal, 15)
                    }
                    .gameCard()
                    
                    // Current Player Setup
                    if currentPlayerIndex < playerCount {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Player \(currentPlayerIndex + 1) of \(playerCount)")
                                .gameText(size: .medium, weight: .bold)
                            
                            // Player Name Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .gameText(size: .small, weight: .medium)
                                
                                TextField("Enter player name", text: $playerName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .foregroundColor(.black)
                                    .background(Color.white)
                            }
                            
                            // Avatar Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Avatar")
                                    .gameText(size: .small, weight: .medium)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(AvatarOption.allAvatars) { avatar in
                                            Button(action: {
                                                soundManager.playButtonTap()
                                                selectedAvatar = avatar
                                            }) {
                                                VStack(spacing: 5) {
                                                    Image(systemName: avatar.systemImage)
                                                        .font(.title)
                                                        .foregroundColor(selectedAvatar.id == avatar.id ? GameColorScheme.accentColor : GameColorScheme.primaryText)
                                                        .padding(10)
                                                        .background(
                                                            Circle()
                                                                .fill(selectedAvatar.id == avatar.id ? GameColorScheme.accentColor.opacity(0.2) : Color.clear)
                                                                .overlay(
                                                                    Circle()
                                                                        .stroke(selectedAvatar.id == avatar.id ? GameColorScheme.accentColor : GameColorScheme.borderColor, lineWidth: 2)
                                                                )
                                                        )
                                                    
                                                    Text(avatar.name)
                                                        .gameText(size: .small, weight: .regular)
                                                        .foregroundColor(selectedAvatar.id == avatar.id ? GameColorScheme.accentColor : GameColorScheme.secondaryText)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                }
                            }
                            
                            // Add Player Button
                            Button(action: {
                                soundManager.playButtonTap()
                                addPlayer()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Player")
                                }
                            }
                            .gameButton(isPrimary: true)
                            .disabled(playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .gameCard()
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // Right side - Players List
                VStack(spacing: 20) {
                    // Players List Header
                    Text("Players (\(gameState.players.count)/\(playerCount))")
                        .gameText(size: .large, weight: .bold)
                        .foregroundColor(GameColorScheme.accentColor)
                        .padding(.top, 20)
                    
                    // Players Grid
                    if !gameState.players.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                                ForEach(Array(gameState.players.enumerated()), id: \.element.id) { index, player in
                                    VStack(spacing: 8) {
                                        Image(systemName: player.avatar)
                                            .font(.title2)
                                            .foregroundColor(GameColorScheme.accentColor)
                                            .padding(8)
                                            .background(
                                                Circle()
                                                    .fill(GameColorScheme.buttonBackground)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(GameColorScheme.borderColor, lineWidth: 1)
                                                    )
                                            )
                                        
                                        Text(player.name)
                                            .gameText(size: .small, weight: .medium)
                                            .multilineTextAlignment(.center)
                                        
                                        Button(action: {
                                            soundManager.playButtonTap()
                                            removePlayer(at: index)
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(GameColorScheme.dangerColor)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(GameColorScheme.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(GameColorScheme.borderColor, lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    } else {
                        VStack {
                            Spacer()
                            Text("No players added yet")
                                .gameText(size: .medium, weight: .regular)
                                .foregroundColor(GameColorScheme.secondaryText)
                            Spacer()
                        }
                    }
                    
                    // Start Game Button
                    if gameState.players.count == playerCount {
                        Button(action: {
                            soundManager.playGameStart()
                            showingRoleDistribution = true
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Game")
                            }
                        }
                        .gameButton(isPrimary: true)
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
            // Устанавливаем landscape ориентацию для настройки игры
            OrientationManager.setLandscapeOnly()
        }
        .navigationDestination(isPresented: $showingRoleDistribution) {
            RoleDistributionView(gameState: gameState)
        }
    }
    
    private func addPlayer() {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let player = Player(name: trimmedName, avatar: selectedAvatar.systemImage)
        gameState.addPlayer(player)
        
        // Reset for next player
        playerName = ""
        selectedAvatar = AvatarOption.allAvatars[0]
        currentPlayerIndex += 1
    }
    
    private func removePlayer(at index: Int) {
        gameState.removePlayer(at: index)
        currentPlayerIndex -= 1
    }
    }


struct GameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        GameSetupView(gameState: GameState())
    }
}


import Foundation
import SwiftUI

// MARK: - Game Roles
enum Role: String, CaseIterable, Codable {
    case mafia = "Mafia"
    case detective = "Detective"
    case doctor = "Doctor"
    case villager = "Villager"
    
    var description: String {
        switch self {
        case .mafia:
            return "Eliminate villagers without being caught. Work with other mafia members."
        case .detective:
            return "Investigate players at night to find mafia members. Share findings during day."
        case .doctor:
            return "Protect one player each night from elimination. Cannot protect yourself."
        case .villager:
            return "Find and vote out mafia members during the day. Survive until mafia is eliminated."
        }
    }
    
    var icon: String {
        switch self {
        case .mafia:
            return "person.fill.badge.minus"
        case .detective:
            return "magnifyingglass"
        case .doctor:
            return "cross.fill"
        case .villager:
            return "person.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .mafia:
            return .red
        case .detective:
            return .blue
        case .doctor:
            return .green
        case .villager:
            return .gray
        }
    }
    }


// MARK: - Player Model
struct Player: Identifiable, Codable {
    let id = UUID()
    var name: String
    var role: Role?
    var isAlive: Bool = true
    var avatar: String
    var isProtected: Bool = false
    var isInvestigated: Bool = false
    
    init(name: String, avatar: String) {
        self.name = name
        self.avatar = avatar
    }
    }


// MARK: - Game State
enum GamePhase: String, CaseIterable, Codable {
    case setup = "Setup"
    case roleDistribution = "Role Distribution"
    case night = "Night"
    case day = "Day"
    case results = "Results"
    case finished = "Finished"
    }


class GameState: ObservableObject {
    @Published var players: [Player] = []
    @Published var currentPhase: GamePhase = .setup
    @Published var currentPlayerIndex: Int = 0
    @Published var nightActions: [String: String] = [:] // role: target
    @Published var votes: [String: Int] = [:] // playerId: voteCount
    @Published var eliminatedPlayer: Player?
    @Published var winner: String = ""
    @Published var gameHistory: [GameAction] = []
    @Published var discussionTimeRemaining: Int = 300 // 5 minutes in seconds
    @Published var isTimerRunning: Bool = false
    
    init() {
        loadStatistics()
        loadSettings()
    }
    
    private func loadStatistics() {
        mafiaWins = UserDefaults.standard.integer(forKey: "mafiaWins")
        villagerWins = UserDefaults.standard.integer(forKey: "villagerWins")
        totalGames = UserDefaults.standard.integer(forKey: "totalGames")
        
        if let achievementsArray = UserDefaults.standard.array(forKey: "achievements") as? [String] {
            achievements = Set(achievementsArray)
        }
        
        print("DEBUG: Loaded statistics - Games: \(totalGames), Mafia: \(mafiaWins), Villager: \(villagerWins), Achievements: \(achievements)")
    }
    
    private func loadSettings() {
        let savedDiscussionTime = UserDefaults.standard.integer(forKey: "discussionTime")
        if savedDiscussionTime > 0 {
            discussionTimeRemaining = savedDiscussionTime
        }
    }
    
    func updateDiscussionTime(_ newTime: Int) {
        discussionTimeRemaining = newTime
        UserDefaults.standard.set(newTime, forKey: "discussionTime")
    }
    
    // Game statistics
    @Published var mafiaWins: Int = 0 {
        didSet {
            UserDefaults.standard.set(mafiaWins, forKey: "mafiaWins")
        }
    }
    @Published var villagerWins: Int = 0 {
        didSet {
            UserDefaults.standard.set(villagerWins, forKey: "villagerWins")
        }
    }
    @Published var totalGames: Int = 0 {
        didSet {
            UserDefaults.standard.set(totalGames, forKey: "totalGames")
        }
    }
    @Published var achievements: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(achievements), forKey: "achievements")
        }
    }
    
    func resetGame() {
        players = []
        currentPhase = .setup
        currentPlayerIndex = 0
        nightActions = [:]
        votes = [:]
        eliminatedPlayer = nil
        winner = ""
        gameHistory = []
        
        // Load discussion time from settings
        let savedDiscussionTime = UserDefaults.standard.integer(forKey: "discussionTime")
        discussionTimeRemaining = savedDiscussionTime > 0 ? savedDiscussionTime : 300
        
        isTimerRunning = false
    }
    
    func addPlayer(_ player: Player) {
        players.append(player)
    }
    
    func removePlayer(at index: Int) {
        players.remove(at: index)
    }
    
    func assignRoles() {
        let playerCount = players.count
        let mafiaCount = max(1, playerCount / 3) // Roughly 1/3 are mafia
        let specialRoles = min(2, playerCount - mafiaCount) // Detective and Doctor
        
        // Reset all roles
        for i in 0..<players.count {
            players[i].role = nil
            players[i].isAlive = true
            players[i].isProtected = false
            players[i].isInvestigated = false
        }
        
        // Assign mafia roles
        var mafiaAssigned = 0
        while mafiaAssigned < mafiaCount {
            let randomIndex = Int.random(in: 0..<players.count)
            if players[randomIndex].role == nil {
                players[randomIndex].role = .mafia
                mafiaAssigned += 1
            }
        }
        
        // Assign special roles
        var specialAssigned = 0
        let specialRoleTypes: [Role] = [.detective, .doctor]
        
        for roleType in specialRoleTypes {
            if specialAssigned < specialRoles {
                var attempts = 0
                while attempts < 100 { // Prevent infinite loop
                    let randomIndex = Int.random(in: 0..<players.count)
                    if players[randomIndex].role == nil {
                        players[randomIndex].role = roleType
                        specialAssigned += 1
                        break
                    }
                    attempts += 1
                }
            }
        }
        
        // Assign remaining as villagers
        for i in 0..<players.count {
            if players[i].role == nil {
                players[i].role = .villager
            }
        }
        
        // Debug: Print assigned roles
        print("DEBUG: Role assignment completed:")
        for (index, player) in players.enumerated() {
            print("DEBUG: Player \(index): \(player.name) - \(player.role?.rawValue ?? "nil")")
        }
    }
    
    func getAlivePlayers() -> [Player] {
        return players.filter { $0.isAlive }
    }
    
    func getMafiaPlayers() -> [Player] {
        return players.filter { $0.isAlive && $0.role == .mafia }
    }
    
    func getVillagerPlayers() -> [Player] {
        return players.filter { $0.isAlive && $0.role != .mafia }
    }
    
    func checkWinCondition() -> String? {
        let aliveMafia = getMafiaPlayers().count
        let aliveVillagers = getVillagerPlayers().count
        
        print("DEBUG: checkWinCondition - Mafia: \(aliveMafia), Villagers: \(aliveVillagers)")
        
        // Villagers win if no mafia left
        if aliveMafia == 0 {
            print("DEBUG: Villagers win - no mafia left")
            return "Villagers"
        }
        
        // Mafia wins if no villagers left
        if aliveVillagers == 0 {
            print("DEBUG: Mafia wins - no villagers left")
            return "Mafia"
        }
        
        // Mafia wins if mafia count >= villager count (tie goes to mafia)
        if aliveMafia >= aliveVillagers {
            print("DEBUG: Mafia wins - mafia >= villagers (\(aliveMafia) >= \(aliveVillagers))")
            return "Mafia"
        }
        
        print("DEBUG: Game continues - mafia (\(aliveMafia)) < villagers (\(aliveVillagers))")
        
        print("DEBUG: No win condition met - game continues")
        return nil
    }
    
    func updateGameStatistics() {
        print("DEBUG: updateGameStatistics called")
        if let winner = checkWinCondition() {
            print("DEBUG: Win condition met, winner: \(winner)")
            // Only update if we haven't already processed this game
            if self.winner.isEmpty {
                print("DEBUG: Winner is empty, updating statistics")
                self.winner = winner
                if winner == "Mafia" {
                    self.mafiaWins += 1
                } else {
                    self.villagerWins += 1
                }
                self.totalGames += 1
                
                // Update achievements
                updateAchievements()
                
                // Force save to UserDefaults
                UserDefaults.standard.synchronize()
                
                print("DEBUG: Game ended! Winner: \(winner)")
                print("DEBUG: Total games: \(totalGames), Mafia wins: \(mafiaWins), Villager wins: \(villagerWins)")
                print("DEBUG: Achievements: \(achievements)")
            } else {
                print("DEBUG: Winner already set to: \(self.winner)")
            }
        } else {
            print("DEBUG: No win condition met")
        }
    }
    
    private func updateAchievements() {
        // First Game achievement
        if totalGames == 1 && !achievements.contains("first_game") {
            achievements.insert("first_game")
            print("DEBUG: Achievement unlocked: First Game!")
        }
        
        // First Win achievement
        if (mafiaWins > 0 || villagerWins > 0) && !achievements.contains("first_win") {
            achievements.insert("first_win")
            print("DEBUG: Achievement unlocked: First Win!")
        }
        
        // Mafia Master achievement
        if mafiaWins >= 5 && !achievements.contains("mafia_master") {
            achievements.insert("mafia_master")
            print("DEBUG: Achievement unlocked: Mafia Master!")
        }
        
        // Villager Hero achievement
        if villagerWins >= 5 && !achievements.contains("villager_hero") {
            achievements.insert("villager_hero")
            print("DEBUG: Achievement unlocked: Villager Hero!")
        }
        
        // Game Master achievement
        if totalGames >= 10 && !achievements.contains("game_master") {
            achievements.insert("game_master")
            print("DEBUG: Achievement unlocked: Game Master!")
        }
        
        // Perfect Detective achievement
        if villagerWins >= 3 && !achievements.contains("perfect_detective") {
            achievements.insert("perfect_detective")
            print("DEBUG: Achievement unlocked: Perfect Detective!")
        }
    }
    }


// MARK: - Game Actions
struct GameAction: Identifiable, Codable {
    let id: UUID
    let phase: GamePhase
    let description: String
    let timestamp: Date
    let playerName: String?
    
    init(phase: GamePhase, description: String, playerName: String? = nil) {
        self.id = UUID()
        self.phase = phase
        self.description = description
        self.timestamp = Date()
        self.playerName = playerName
    }
    
    // Custom Codable implementation to ensure compatibility
    enum CodingKeys: String, CodingKey {
        case id, phase, description, timestamp, playerName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        phase = try container.decode(GamePhase.self, forKey: .phase)
        description = try container.decode(String.self, forKey: .description)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        playerName = try container.decodeIfPresent(String.self, forKey: .playerName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(phase, forKey: .phase)
        try container.encode(description, forKey: .description)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(playerName, forKey: .playerName)
    }
    }


// MARK: - Avatar Options
struct AvatarOption: Identifiable {
    let id = UUID()
    let name: String
    let systemImage: String
    
    static let allAvatars = [
        AvatarOption(name: "Person", systemImage: "person.fill"),
        AvatarOption(name: "Person 2", systemImage: "person.2.fill"),
        AvatarOption(name: "Person 3", systemImage: "person.3.fill"),
        AvatarOption(name: "Crown", systemImage: "crown.fill"),
        AvatarOption(name: "Star", systemImage: "star.fill"),
        AvatarOption(name: "Heart", systemImage: "heart.fill"),
        AvatarOption(name: "Diamond", systemImage: "diamond.fill"),
        AvatarOption(name: "Circle", systemImage: "circle.fill"),
        AvatarOption(name: "Square", systemImage: "square.fill"),
        AvatarOption(name: "Triangle", systemImage: "triangle.fill"),
        AvatarOption(name: "Hexagon", systemImage: "hexagon.fill"),
        AvatarOption(name: "Pentagon", systemImage: "pentagon.fill")
    ]
    }


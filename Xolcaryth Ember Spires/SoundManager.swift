

import AVFoundation
import SwiftUI
import UIKit

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
        }
    }
    
    @Published var isVibrationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isVibrationEnabled, forKey: "vibrationEnabled")
        }
    }
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    private init() {
        self.isSoundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        self.isVibrationEnabled = UserDefaults.standard.bool(forKey: "vibrationEnabled")
        
        // Set default values if not set
        if !UserDefaults.standard.bool(forKey: "soundEnabledSet") {
            self.isSoundEnabled = true
            UserDefaults.standard.set(true, forKey: "soundEnabled")
            UserDefaults.standard.set(true, forKey: "soundEnabledSet")
        }
        
        if !UserDefaults.standard.bool(forKey: "vibrationEnabledSet") {
            self.isVibrationEnabled = true
            UserDefaults.standard.set(true, forKey: "vibrationEnabled")
            UserDefaults.standard.set(true, forKey: "vibrationEnabledSet")
        }
        
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Sound Effects
    func playSound(_ soundName: String) {
        guard isSoundEnabled else { return }
        
        if let player = audioPlayers[soundName] {
            player.stop()
            player.currentTime = 0
            player.play()
        } else {
            // Create system sound for now - in a real app you'd load from bundle
            playSystemSound(soundName)
        }
    }
    
    private func playSystemSound(_ soundName: String) {
        // Map sound names to system sounds
        let systemSoundID: SystemSoundID
        
        switch soundName {
        case "button_tap":
            systemSoundID = 1104 // Tock sound
        case "card_deal":
            systemSoundID = 1105 // Tink sound
        case "game_start":
            systemSoundID = 1106 // Glass sound
        case "game_end":
            systemSoundID = 1107 // Bell sound
        case "vote_cast":
            systemSoundID = 1108 // Click sound
        case "elimination":
            systemSoundID = 1109 // Glass sound
        case "night_phase":
            systemSoundID = 1110 // Glass sound
        case "day_phase":
            systemSoundID = 1111 // Glass sound
        default:
            systemSoundID = 1104 // Default tock sound
        }
        
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    
    // MARK: - Convenience Methods
    func playButtonTap() {
        playSound("button_tap")
    }
    
    func playCardDeal() {
        playSound("card_deal")
    }
    
    func playGameStart() {
        playSound("game_start")
    }
    
    func playGameEnd() {
        playSound("game_end")
    }
    
    func playVoteCast() {
        playSound("vote_cast")
    }
    
    func playElimination() {
        playSound("elimination")
    }
    
    func playNightPhase() {
        playSound("night_phase")
    }
    
    func playDayPhase() {
        playSound("day_phase")
    }
    
    // MARK: - Haptic Feedback
    func playHaptic(_ type: HapticType) {
        guard isVibrationEnabled else { return }
        
        switch type {
        case .light:
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        case .medium:
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        case .heavy:
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        case .success:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        case .selection:
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }
    }
    
    // MARK: - Convenience Haptic Methods
    func playButtonHaptic() {
        playHaptic(.light)
    }
    
    func playCardHaptic() {
        playHaptic(.medium)
    }
    
    func playVoteHaptic() {
        playHaptic(.selection)
    }
    
    func playEliminationHaptic() {
        playHaptic(.heavy)
    }
    
    func playGameStartHaptic() {
        playHaptic(.success)
    }
    
    func playGameEndHaptic() {
        playHaptic(.success)
    }
    
    func playPhaseTransitionHaptic() {
        playHaptic(.medium)
    }
    
    func playTimerTickHaptic() {
        playHaptic(.light)
    }
    }


// MARK: - Sound Effects for Different Actions
extension SoundManager {
    func playRoleAssignment() {
        playCardDeal()
    }
    
    func playPhaseTransition() {
        playSound("phase_transition")
    }
    
    func playTimerTick() {
        // Play a subtle tick sound
        playSound("timer_tick")
    }
    
    func playAchievementUnlock() {
        playSound("achievement")
    }
    }

// MARK: - Haptic Types
enum HapticType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}


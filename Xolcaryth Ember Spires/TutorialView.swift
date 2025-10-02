
import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundManager = SoundManager.shared
    @State private var currentSlide = 0
    @State private var showingRoleDetail = false
    @State private var selectedRole: Role?
    
    private let slides = [
        TutorialSlide(
            title: "Welcome to Xolcaryth Ember Spires",
            content: "A thrilling Mafia game where shadows and light battle for control of the village. Use strategy, deception, and deduction to emerge victorious.",
            icon: "moon.stars.fill",
            color: GameColorScheme.accentColor
        ),
        TutorialSlide(
            title: "Game Overview",
            content: "Players are divided into two teams: Mafia and Villagers. The Mafia tries to eliminate villagers without being caught, while Villagers try to identify and vote out the Mafia members.",
            icon: "person.2.fill",
            color: GameColorScheme.primaryText
        ),
        TutorialSlide(
            title: "Game Phases",
            content: "Each game consists of Night and Day phases. During the night, special roles take actions. During the day, all players discuss and vote to eliminate a suspect.",
            icon: "clock.fill",
            color: GameColorScheme.timerColor
        )
    ]
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            ScrollView {
                VStack(spacing: 15) {
                    // Header
                    HStack {
                        Button("Close") {
                            soundManager.playButtonTap()
                            dismiss()
                        }
                        .gameButton(isPrimary: false)
                        
                        Spacer()
                        
                        Text("Tutorial")
                            .gameText(size: .medium, weight: .bold)
                        
                        Spacer()
                        
                        // Invisible button for balance
                        Button("Close") {
                            soundManager.playButtonTap()
                            dismiss()
                        }
                        .gameButton(isPrimary: false)
                        .opacity(0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(0..<slides.count + Role.allCases.count + 2, id: \.self) { index in
                        Circle()
                            .fill(index <= currentSlide ? GameColorScheme.accentColor : GameColorScheme.secondaryText)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentSlide)
                    }
                }
                .padding(.horizontal, 20)
                
                // Content
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            // Introduction Slides
                            ForEach(0..<slides.count, id: \.self) { index in
                                TutorialSlideView(slide: slides[index])
                                    .frame(width: UIScreen.main.bounds.width - 40)
                                    .id(index)
                            }
                            
                            // Role Explanations
                            ForEach(Array(Role.allCases.enumerated()), id: \.element) { index, role in
                                RoleTutorialView(role: role)
                                    .frame(width: UIScreen.main.bounds.width - 40)
                                    .id(slides.count + index)
                            }
                            
                            // Game Flow
                            GameFlowView()
                                .frame(width: UIScreen.main.bounds.width - 40)
                                .id(slides.count + Role.allCases.count)
                            
                            // Tips and Strategies
                            TipsView()
                                .frame(width: UIScreen.main.bounds.width - 40)
                                .id(slides.count + Role.allCases.count + 1)
                        }
                    }
                    .frame(height: 500)
                    .onChange(of: currentSlide) { newSlide in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(newSlide, anchor: .center)
                        }
                    }
                }
                
                // Navigation Buttons
                HStack(spacing: 20) {
                    Button(action: previousSlide) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                    }
                    .gameButton(isPrimary: false)
                    .disabled(currentSlide == 0)
                    
                    Spacer()
                    
                    Button(action: nextSlide) {
                        HStack {
                            Text(currentSlide == slides.count + Role.allCases.count + 1 ? "Finish" : "Next")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .gameButton(isPrimary: true)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Устанавливаем landscape ориентацию для обучающего экрана
            OrientationManager.setLandscapeOnly()
        }
        .sheet(isPresented: $showingRoleDetail) {
            if let role = selectedRole {
                RoleDetailView(role: role)
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func previousSlide() {
        if currentSlide > 0 {
            soundManager.playButtonTap()
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSlide -= 1
            }
        }
    }
    
    private func nextSlide() {
        let maxSlide = slides.count + Role.allCases.count + 1
        if currentSlide < maxSlide {
            soundManager.playButtonTap()
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSlide += 1
            }
        } else {
            soundManager.playButtonTap()
            dismiss()
        }
    }
    }


// MARK: - Tutorial Slide
struct TutorialSlide {
    let title: String
    let content: String
    let icon: String
    let color: Color
    }


struct TutorialSlideView: View {
    let slide: TutorialSlide
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: slide.icon)
                .font(.system(size: 80))
                .foregroundColor(slide.color)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Title
            Text(slide.title)
                .gameText(size: .large, weight: .bold)
                .multilineTextAlignment(.center)
            
            // Content
            Text(slide.content)
                .gameText(size: .medium, weight: .regular)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
    }


// MARK: - Role Tutorial View
struct RoleTutorialView: View {
    let role: Role
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Role Icon
            Image(systemName: role.icon)
                .font(.system(size: 80))
                .foregroundColor(role.gameColor)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Role Name
            Text(role.rawValue)
                .gameText(size: .large, weight: .bold)
                .foregroundColor(role.gameColor)
            
            // Role Description
            Text(role.description)
                .gameText(size: .medium, weight: .regular)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Role Abilities
            VStack(spacing: 15) {
                Text("Abilities")
                    .gameText(size: .medium, weight: .bold)
                    .foregroundColor(GameColorScheme.accentColor)
                
                VStack(spacing: 10) {
                    ForEach(getRoleAbilities(), id: \.self) { ability in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(role.gameColor)
                            Text(ability)
                                .gameText(size: .small, weight: .regular)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .gameCard()
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func getRoleAbilities() -> [String] {
        switch role {
        case .mafia:
            return [
                "Eliminate one player each night",
                "Work with other mafia members",
                "Win by eliminating all villagers",
                "Must avoid detection during day phase"
            ]
        case .detective:
            return [
                "Investigate one player each night",
                "Learn if target is mafia or villager",
                "Share findings during day phase",
                "Help villagers identify mafia"
            ]
        case .doctor:
            return [
                "Protect one player each night",
                "Prevent mafia elimination",
                "Cannot protect yourself",
                "Help villagers survive"
            ]
        case .villager:
            return [
                "Participate in day discussions",
                "Vote to eliminate suspects",
                "Share information and suspicions",
                "Win by eliminating all mafia"
            ]
        }
    }
    }


// MARK: - Game Flow View
struct GameFlowView: View {
    @State private var currentStep = 0
    @State private var isAnimating = false
    
    private let steps = [
        "Setup: Choose players and assign roles",
        "Night: Special roles take actions",
        "Day: Discuss and vote to eliminate",
        "Repeat: Continue until game ends",
        "Results: Reveal roles and declare winner"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Game Flow")
                .gameText(size: .large, weight: .bold)
                .foregroundColor(GameColorScheme.accentColor)
            
            VStack(spacing: 20) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack {
                        // Step Number
                        Text("\(index + 1)")
                            .gameText(size: .medium, weight: .bold)
                            .foregroundColor(GameColorScheme.primaryText)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(currentStep >= index ? GameColorScheme.accentColor : GameColorScheme.secondaryText)
                            )
                        
                        // Step Description
                        Text(steps[index])
                            .gameText(size: .medium, weight: .regular)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(currentStep >= index ? GameColorScheme.accentColor.opacity(0.1) : GameColorScheme.overlayBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(currentStep >= index ? GameColorScheme.accentColor : GameColorScheme.borderColor, lineWidth: 1)
                            )
                    )
                    .scaleEffect(currentStep >= index ? 1.0 : 0.95)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            animateSteps()
        }
    }
    
    private func animateSteps() {
        for index in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    currentStep = index
                }
            }
        }
    }
    }


// MARK: - Tips View
struct TipsView: View {
    private let tips = [
        "Pay attention to voting patterns and who votes for whom",
        "Look for inconsistencies in players' stories and claims",
        "As mafia, try to blend in and avoid drawing attention",
        "As detective, share your findings strategically",
        "As doctor, protect key players and yourself when possible",
        "Don't reveal your role unless absolutely necessary",
        "Use the discussion time wisely to gather information",
        "Trust your instincts but verify with evidence"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Tips & Strategies")
                .gameText(size: .large, weight: .bold)
                .foregroundColor(GameColorScheme.accentColor)
            
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                        HStack(alignment: .top, spacing: 15) {
                            Text("\(index + 1)")
                                .gameText(size: .small, weight: .bold)
                                .foregroundColor(GameColorScheme.accentColor)
                                .frame(width: 20, height: 20)
                                .background(
                                    Circle()
                                        .fill(GameColorScheme.accentColor.opacity(0.2))
                                )
                            
                            Text(tip)
                                .gameText(size: .small, weight: .regular)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(15)
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
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
    }
    }


// MARK: - Role Detail View
struct RoleDetailView: View {
    let role: Role
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            GameBackgroundView()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .gameButton(isPrimary: false)
                    
                    Spacer()
                    
                    Text(role.rawValue)
                        .gameText(size: .large, weight: .bold)
                        .foregroundColor(role.gameColor)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("Close") {
                        dismiss()
                    }
                    .gameButton(isPrimary: false)
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Role Icon
                        Image(systemName: role.icon)
                            .font(.system(size: 100))
                            .foregroundColor(role.gameColor)
                            .padding(20)
                            .background(
                                Circle()
                                    .fill(role.gameColor.opacity(0.1))
                                    .overlay(
                                        Circle()
                                            .stroke(role.gameColor, lineWidth: 3)
                                    )
                            )
                        
                        // Role Description
                        Text(role.description)
                            .gameText(size: .medium, weight: .regular)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Detailed Information
                        VStack(spacing: 15) {
                            Text("Detailed Information")
                                .gameText(size: .medium, weight: .bold)
                                .foregroundColor(GameColorScheme.accentColor)
                            
                            Text(getDetailedInfo())
                                .gameText(size: .small, weight: .regular)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 20)
                        }
                        .gameCard()
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func getDetailedInfo() -> String {
        switch role {
        case .mafia:
            return "The Mafia is the evil faction trying to take control of the village. You work with other mafia members to eliminate villagers one by one during the night phase. Your goal is to eliminate all villagers without being caught. During the day phase, you must blend in with the villagers and avoid suspicion. Work together with your mafia teammates to coordinate eliminations and create alibis."
        case .detective:
            return "The Detective is a special villager with the ability to investigate other players during the night phase. Each night, you can choose one player to investigate and learn whether they are mafia or villager. Use this information wisely during the day phase to help the villagers identify and vote out mafia members. Be careful not to reveal your identity too early, as the mafia will target you."
        case .doctor:
            return "The Doctor is a special villager with the ability to protect other players during the night phase. Each night, you can choose one player to protect from elimination. If the mafia targets the player you're protecting, they will survive. You cannot protect yourself, so choose your targets wisely. Your goal is to keep key villagers alive and help identify the mafia."
        case .villager:
            return "Villagers are the innocent townspeople trying to identify and eliminate the mafia. You have no special abilities, but you can participate in discussions during the day phase and vote to eliminate suspects. Pay attention to other players' behavior, voting patterns, and claims. Work together with other villagers to gather information and make informed decisions about who to eliminate."
        }
    }
    }


struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}

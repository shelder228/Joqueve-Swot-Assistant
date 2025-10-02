
import SwiftUI

// MARK: - Adaptive Color Scheme
struct GameColorScheme {
    // Primary colors that work well with the background image
    static let primaryText = Color.white
    static let secondaryText = Color.gray.opacity(0.8)
    static let accentColor = Color.orange
    static let dangerColor = Color.red
    static let successColor = Color.green
    static let warningColor = Color.yellow
    
    // Background colors with transparency for readability
    static let cardBackground = Color.black.opacity(0.7)
    static let buttonBackground = Color.white.opacity(0.2)
    static let buttonBackgroundPressed = Color.white.opacity(0.3)
    static let overlayBackground = Color.black.opacity(0.5)
    
    // Role-specific colors
    static let mafiaColor = Color.red
    static let detectiveColor = Color.blue
    static let doctorColor = Color.green
    static let villagerColor = Color.gray
    
    // Status colors
    static let aliveColor = Color.green
    static let deadColor = Color.red
    static let protectedColor = Color.blue.opacity(0.6)
    static let investigatedColor = Color.purple.opacity(0.6)
    
    // UI element colors
    static let borderColor = Color.white.opacity(0.3)
    static let shadowColor = Color.black.opacity(0.5)
    static let timerColor = Color.orange
    static let voteColor = Color.blue
    }


// MARK: - Custom Button Styles
struct GameButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    init(isPrimary: Bool = true) {
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 30 : 20)
            .padding(.vertical, UIDevice.current.userInterfaceIdiom == .pad ? 18 : 12)
            .background(
                RoundedRectangle(cornerRadius: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12)
                    .fill(isPrimary ? GameColorScheme.buttonBackground : GameColorScheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12)
                            .stroke(GameColorScheme.borderColor, lineWidth: 1)
                    )
            )
            .foregroundColor(GameColorScheme.primaryText)
            .font(UIDevice.current.userInterfaceIdiom == .pad ? .title2 : .headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    }


// MARK: - Custom Card Styles
struct GameCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(GameColorScheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(GameColorScheme.borderColor, lineWidth: 1)
                    )
            )
            .shadow(color: GameColorScheme.shadowColor, radius: 8, x: 0, y: 4)
    }
    }


// MARK: - Custom Text Styles
struct GameTextStyle: ViewModifier {
    let size: FontSize
    let weight: FontWeight
    
    enum FontSize {
        case extraLarge, large, medium, small
        
        var font: Font {
            switch self {
            case .extraLarge: return UIDevice.current.userInterfaceIdiom == .pad ? .system(size: 48, weight: .bold) : .largeTitle
            case .large: return UIDevice.current.userInterfaceIdiom == .pad ? .system(size: 36, weight: .bold) : .largeTitle
            case .medium: return UIDevice.current.userInterfaceIdiom == .pad ? .title2 : .headline
            case .small: return UIDevice.current.userInterfaceIdiom == .pad ? .title3 : .body
            }
        }
    }
    
    enum FontWeight {
        case bold, medium, regular
        
        var weight: Font.Weight {
            switch self {
            case .bold: return .bold
            case .medium: return .medium
            case .regular: return .regular
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(size.font.weight(weight.weight))
            .foregroundColor(GameColorScheme.primaryText)
    }
    }


// MARK: - View Extensions
extension View {
    func gameCard() -> some View {
        modifier(GameCardStyle())
    }
    
    func gameText(size: GameTextStyle.FontSize = .medium, weight: GameTextStyle.FontWeight = .regular) -> some View {
        modifier(GameTextStyle(size: size, weight: weight))
    }
    
    func gameButton(isPrimary: Bool = true) -> some View {
        buttonStyle(GameButtonStyle(isPrimary: isPrimary))
    }
    }


// MARK: - Background View
struct GameBackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            Image("BackGround")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(
                    // Dark overlay for better text readability
                    Rectangle()
                        .fill(GameColorScheme.overlayBackground)
                )
        }
        .ignoresSafeArea()
    }
    }


// MARK: - Role Color Extensions
extension Role {
    var gameColor: Color {
        switch self {
        case .mafia:
            return GameColorScheme.mafiaColor
        case .detective:
            return GameColorScheme.detectiveColor
        case .doctor:
            return GameColorScheme.doctorColor
        case .villager:
            return GameColorScheme.villagerColor
        }
    }
    }


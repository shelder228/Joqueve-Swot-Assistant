import Foundation
import SwiftUI

struct SWOTExample: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let category: SWOTCategory
    let strengths: String
    let weaknesses: String
    let opportunities: String
    let threats: String
    let icon: String
    private let colorString: String
    
    // Computed property for SwiftUI Color
    var color: Color {
        return Color.fromString(colorString)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, strengths, weaknesses, opportunities, threats, icon, colorString
    }
    
    init(title: String, description: String, category: SWOTCategory, strengths: String, weaknesses: String, opportunities: String, threats: String, icon: String, color: Color) {
        self.title = title
        self.description = description
        self.category = category
        self.strengths = strengths
        self.weaknesses = weaknesses
        self.opportunities = opportunities
        self.threats = threats
        self.icon = icon
        self.colorString = color.toString()
    }
}

enum SWOTCategory: String, CaseIterable, Codable {
    case business = "Business"
    case personal = "Personal"
    case startup = "Startup"
    case career = "Career"
    case project = "Project"
    case education = "Education"
    case health = "Health"
    case technology = "Technology"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .business:
            return "building.2.fill"
        case .personal:
            return "person.fill"
        case .startup:
            return "paperplane.fill"
        case .career:
            return "briefcase.fill"
        case .project:
            return "folder.fill"
        case .education:
            return "graduationcap.fill"
        case .health:
            return "heart.fill"
        case .technology:
            return "laptopcomputer"
        }
    }
    
    var color: Color {
        switch self {
        case .business:
            return .blue
        case .personal:
            return .green
        case .startup:
            return .orange
        case .career:
            return .purple
        case .project:
            return .cyan
        case .education:
            return .indigo
        case .health:
            return .red
        case .technology:
            return .mint
        }
    }
}

class SWOTExamplesManager: ObservableObject {
    @Published var examples: [SWOTExample] = []
    
    init() {
        loadExamples()
    }
    
    private func loadExamples() {
        examples = [
            // Business Examples
            SWOTExample(
                title: "Local Coffee Shop",
                description: "A small independent coffee shop competing with chains",
                category: .business,
                strengths: "Unique artisanal coffee blends\nPersonal customer relationships\nLocal community support\nFlexible menu changes\nLower overhead costs",
                weaknesses: "Limited marketing budget\nSmall seating capacity\nLimited product range\nDependence on owner expertise\nNo online ordering system",
                opportunities: "Growing coffee culture trend\nLocal delivery partnerships\nCatering services expansion\nMobile app development\nSeasonal menu offerings",
                threats: "Large chain competition\nRising coffee bean prices\nEconomic downturns\nChanging consumer preferences\nRent increases",
                icon: "cup.and.saucer.fill",
                color: .brown
            ),
            
            SWOTExample(
                title: "Tech Startup",
                description: "A new mobile app startup in the fintech space",
                category: .startup,
                strengths: "Innovative technology solution\nStrong technical team\nAgile development process\nFirst-mover advantage\nScalable business model",
                weaknesses: "Limited funding\nNo established customer base\nRegulatory compliance challenges\nLimited brand recognition\nHigh development costs",
                opportunities: "Growing fintech market\nDigital transformation trends\nPartnership opportunities\nGovernment startup incentives\nInternational expansion",
                threats: "Established competitors\nRegulatory changes\nEconomic uncertainty\nTechnology obsolescence\nTalent acquisition challenges",
                icon: "iphone",
                color: .blue
            ),
            
            // Personal Examples
            SWOTExample(
                title: "Career Change",
                description: "Transitioning from marketing to software development",
                category: .career,
                strengths: "Strong communication skills\nCreative problem-solving\nProject management experience\nUnderstanding of user needs\nTransferable soft skills",
                weaknesses: "Limited technical experience\nNo formal CS degree\nLearning curve ahead\nAge factor in tech industry\nSalary reduction initially",
                opportunities: "High demand for developers\nRemote work possibilities\nContinuous learning culture\nFreelance opportunities\nCareer growth potential",
                threats: "Rapid technology changes\nAge discrimination\nMarket saturation\nEconomic downturns\nCompetition from graduates",
                icon: "person.crop.circle.badge.checkmark",
                color: .green
            ),
            
            SWOTExample(
                title: "Personal Fitness",
                description: "Starting a new fitness routine and healthy lifestyle",
                category: .personal,
                strengths: "Strong motivation to change\nAccess to gym facilities\nSupportive family\nPrevious athletic experience\nGood health insurance",
                weaknesses: "Busy work schedule\nLimited cooking skills\nSedentary lifestyle habits\nLack of fitness knowledge\nPrevious failed attempts",
                opportunities: "Home workout options\nOnline fitness programs\nCommunity fitness groups\nWorkplace wellness programs\nSeasonal outdoor activities",
                threats: "Time constraints\nSocial pressure to eat out\nInjury risks\nWeather affecting outdoor activities\nCost of healthy food",
                icon: "figure.run",
                color: .red
            ),
            
            // Project Examples
            SWOTExample(
                title: "Website Redesign",
                description: "Redesigning company website for better user experience",
                category: .project,
                strengths: "Clear project objectives\nDedicated team members\nExisting content and branding\nUser feedback data\nBudget allocation",
                weaknesses: "Tight deadline\nLimited design resources\nTechnical constraints\nStakeholder disagreements\nLegacy system integration",
                opportunities: "Mobile-first design trends\nNew web technologies\nImproved SEO potential\nBetter conversion rates\nCompetitive advantage",
                threats: "Scope creep\nTechnical difficulties\nUser resistance to change\nBudget overruns\nDelayed launch",
                icon: "laptopcomputer",
                color: .purple
            ),
            
            // Education Examples
            SWOTExample(
                title: "Online Learning Platform",
                description: "Developing an online course platform for professionals",
                category: .education,
                strengths: "Experienced instructors\nHigh-quality content\nInteractive learning tools\nFlexible scheduling\nGlobal reach potential",
                weaknesses: "High development costs\nCompetition from established platforms\nTechnical maintenance requirements\nStudent engagement challenges\nLimited offline support",
                opportunities: "Growing online education market\nCorporate training partnerships\nMicro-learning trends\nAI-powered personalization\nInternational expansion",
                threats: "Free online resources\nPlatform security concerns\nEconomic downturns affecting training budgets\nTechnology changes\nRegulatory compliance",
                icon: "graduationcap.fill",
                color: .indigo
            ),
            
            // Health Examples
            SWOTExample(
                title: "Mental Health App",
                description: "Developing a mobile app for mental wellness and therapy",
                category: .health,
                strengths: "Growing mental health awareness\nExperienced development team\nEvidence-based approach\nUser privacy focus\nScalable platform",
                weaknesses: "Regulatory compliance complexity\nHigh development costs\nUser acquisition challenges\nLimited offline functionality\nCompetition from established players",
                opportunities: "Increased mental health focus post-pandemic\nTelehealth adoption\nCorporate wellness programs\nInsurance coverage expansion\nGlobal market potential",
                threats: "Privacy regulations\nMedical liability concerns\nEconomic uncertainty\nTechnology platform changes\nUser retention challenges",
                icon: "heart.fill",
                color: .pink
            ),
            
            // Technology Examples
            SWOTExample(
                title: "AI-Powered Analytics",
                description: "Building an AI solution for business data analysis",
                category: .technology,
                strengths: "Advanced AI algorithms\nStrong technical team\nLarge dataset access\nCloud infrastructure\nIndustry expertise",
                weaknesses: "High computational costs\nData privacy concerns\nComplex user interface\nLimited interpretability\nDependence on data quality",
                opportunities: "Growing AI adoption\nBig data trends\nIndustry 4.0 transformation\nAPI monetization\nInternational markets",
                threats: "AI regulation changes\nCompetition from tech giants\nData security breaches\nAlgorithm bias concerns\nTechnology obsolescence",
                icon: "brain.head.profile",
                color: .cyan
            )
        ]
    }
    
    func getExamples(for category: SWOTCategory) -> [SWOTExample] {
        return examples.filter { $0.category == category }
    }
    
    func getRandomExample() -> SWOTExample? {
        return examples.randomElement()
    }
}

// MARK: - Color Extensions for Codable
extension Color {
    func toString() -> String {
        switch self {
        case .red:
            return "red"
        case .green:
            return "green"
        case .blue:
            return "blue"
        case .orange:
            return "orange"
        case .purple:
            return "purple"
        case .pink:
            return "pink"
        case .brown:
            return "brown"
        case .cyan:
            return "cyan"
        case .indigo:
            return "indigo"
        case .mint:
            return "mint"
        case .gray:
            return "gray"
        default:
            return "blue" // fallback
        }
    }
    
    static func fromString(_ string: String) -> Color {
        switch string.lowercased() {
        case "red":
            return .red
        case "green":
            return .green
        case "blue":
            return .blue
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "brown":
            return .brown
        case "cyan":
            return .cyan
        case "indigo":
            return .indigo
        case "mint":
            return .mint
        case "gray":
            return .gray
        default:
            return .blue // fallback
        }
    }
}

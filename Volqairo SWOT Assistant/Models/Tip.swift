import Foundation
import SwiftUI

struct Tip: Identifiable, Codable {
    let id = UUID()
    let title: String
    let summary: String
    let content: [String]
    let category: TipCategory
    let icon: String
    private let colorString: String
    
    var color: Color {
        return Color.fromString(colorString)
    }
    
    init(title: String, summary: String, content: [String], category: TipCategory, icon: String, color: Color) {
        self.title = title
        self.summary = summary
        self.content = content
        self.category = category
        self.icon = icon
        self.colorString = color.toString()
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, summary, content, category, icon, colorString
    }
}

enum TipCategory: String, CaseIterable, Codable {
    case general = "General"
    case strengths = "Strengths"
    case weaknesses = "Weaknesses"
    case opportunities = "Opportunities"
    case threats = "Threats"
    case analysis = "Analysis"
    case presentation = "Presentation"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .general:
            return "star.fill"
        case .strengths:
            return "checkmark.circle.fill"
        case .weaknesses:
            return "xmark.circle.fill"
        case .opportunities:
            return "arrow.up.circle.fill"
        case .threats:
            return "exclamationmark.triangle.fill"
        case .analysis:
            return "brain.head.profile"
        case .presentation:
            return "doc.text.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .general:
            return .yellow
        case .strengths:
            return .green
        case .weaknesses:
            return .red
        case .opportunities:
            return .blue
        case .threats:
            return .orange
        case .analysis:
            return .purple
        case .presentation:
            return .cyan
        }
    }
}

class TipsManager: ObservableObject {
    @Published var tips: [Tip] = []
    
    static let shared = TipsManager()
    
    private init() {
        loadTips()
    }
    
    private func loadTips() {
        tips = [
            // General Tips
            Tip(
                title: "Start with Brainstorming",
                summary: "Begin your SWOT analysis with a brainstorming session to generate ideas freely",
                content: [
                    "Set aside dedicated time for brainstorming without judgment",
                    "Use techniques like mind mapping or free writing",
                    "Encourage input from different team members or perspectives",
                    "Don't worry about categorization initially - just capture ideas",
                    "Review and refine ideas after the initial brainstorming phase"
                ],
                category: .general,
                icon: "brain.head.profile",
                color: .yellow
            ),
            
            Tip(
                title: "Be Specific and Concrete",
                summary: "Avoid vague statements and focus on specific, measurable factors",
                content: [
                    "Instead of 'good reputation', specify '95% customer satisfaction rate'",
                    "Use concrete examples and data points where possible",
                    "Avoid generic statements that could apply to any business",
                    "Include specific metrics, timelines, or quantifiable results",
                    "Make each point actionable and clear"
                ],
                category: .general,
                icon: "target",
                color: .yellow
            ),
            
            Tip(
                title: "Consider Internal vs External Factors",
                summary: "Distinguish between factors you can control and those you cannot",
                content: [
                    "Strengths and Weaknesses are internal - within your control",
                    "Opportunities and Threats are external - market/environment factors",
                    "Focus on what you can influence when planning actions",
                    "Use external factors to inform your internal strategy",
                    "Remember that some external factors can become internal over time"
                ],
                category: .general,
                icon: "arrow.left.arrow.right",
                color: .yellow
            ),
            
            // Strengths Tips
            Tip(
                title: "Identify Your Unique Value Proposition",
                summary: "Focus on what makes you different from competitors",
                content: [
                    "What do you do better than anyone else?",
                    "What resources or capabilities do you have that others lack?",
                    "What do customers specifically praise about your offering?",
                    "What processes or systems give you an advantage?",
                    "What partnerships or relationships provide value?"
                ],
                category: .strengths,
                icon: "star.fill",
                color: .green
            ),
            
            Tip(
                title: "Leverage Your Core Competencies",
                summary: "Build on your strongest skills and capabilities",
                content: [
                    "Identify your most valuable skills and expertise",
                    "Consider how these competencies can be applied to new opportunities",
                    "Look for ways to strengthen and develop these core areas",
                    "Use competencies as a foundation for strategic planning",
                    "Ensure your team understands and can leverage these strengths"
                ],
                category: .strengths,
                icon: "hammer.fill",
                color: .green
            ),
            
            // Weaknesses Tips
            Tip(
                title: "Be Honest About Limitations",
                summary: "Acknowledge areas that need improvement without being overly critical",
                content: [
                    "Identify specific areas where you fall short of goals",
                    "Consider what customers or stakeholders have complained about",
                    "Look at processes that are inefficient or outdated",
                    "Acknowledge skill gaps or resource limitations",
                    "Focus on areas that are within your power to improve"
                ],
                category: .weaknesses,
                icon: "exclamationmark.triangle",
                color: .red
            ),
            
            Tip(
                title: "Turn Weaknesses into Opportunities",
                summary: "View weaknesses as areas for growth and development",
                content: [
                    "Identify which weaknesses are most critical to address",
                    "Consider what resources or support you need to improve",
                    "Look for training, partnerships, or process improvements",
                    "Set realistic timelines for addressing key weaknesses",
                    "Track progress and celebrate improvements"
                ],
                category: .weaknesses,
                icon: "arrow.up.circle",
                color: .red
            ),
            
            // Opportunities Tips
            Tip(
                title: "Monitor Market Trends",
                summary: "Stay informed about industry changes and emerging opportunities",
                content: [
                    "Follow industry publications and news sources",
                    "Attend conferences and networking events",
                    "Monitor competitor activities and market shifts",
                    "Listen to customer feedback and changing needs",
                    "Consider how technology changes might create opportunities"
                ],
                category: .opportunities,
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            ),
            
            Tip(
                title: "Look for Partnership Opportunities",
                summary: "Identify potential collaborations that could benefit your business",
                content: [
                    "Consider complementary businesses that serve your market",
                    "Look for companies with resources you lack",
                    "Explore joint ventures or strategic alliances",
                    "Consider how partnerships could expand your reach",
                    "Evaluate potential partners' values and culture fit"
                ],
                category: .opportunities,
                icon: "person.2.fill",
                color: .blue
            ),
            
            // Threats Tips
            Tip(
                title: "Identify Potential Risks",
                summary: "Anticipate challenges that could impact your success",
                content: [
                    "Consider economic factors that could affect your market",
                    "Monitor regulatory changes in your industry",
                    "Watch for new competitors entering your space",
                    "Consider how technology changes might disrupt your business",
                    "Think about supply chain or resource availability issues"
                ],
                category: .threats,
                icon: "shield.fill",
                color: .orange
            ),
            
            Tip(
                title: "Develop Contingency Plans",
                summary: "Prepare for potential threats with backup strategies",
                content: [
                    "Create alternative plans for different threat scenarios",
                    "Identify early warning signs for each major threat",
                    "Develop relationships with multiple suppliers or partners",
                    "Maintain financial reserves for challenging times",
                    "Regularly review and update your contingency plans"
                ],
                category: .threats,
                icon: "list.bullet.rectangle",
                color: .orange
            ),
            
            // Analysis Tips
            Tip(
                title: "Prioritize Your Findings",
                summary: "Rank your SWOT factors by importance and urgency",
                content: [
                    "Use a scoring system to evaluate each factor's impact",
                    "Consider both short-term and long-term implications",
                    "Focus on factors that are most actionable",
                    "Consider the resources required to address each factor",
                    "Regularly review and update your priorities"
                ],
                category: .analysis,
                icon: "list.number",
                color: .purple
            ),
            
            Tip(
                title: "Look for Cross-Category Connections",
                summary: "Identify relationships between different SWOT factors",
                content: [
                    "How can strengths help address weaknesses?",
                    "What opportunities can help mitigate threats?",
                    "How might weaknesses prevent you from seizing opportunities?",
                    "Can threats be turned into opportunities with the right approach?",
                    "Look for strategic combinations across all four categories"
                ],
                category: .analysis,
                icon: "link",
                color: .purple
            ),
            
            // Presentation Tips
            Tip(
                title: "Create Clear Visualizations",
                summary: "Use charts and diagrams to make your analysis more compelling",
                content: [
                    "Use a 2x2 matrix to visualize your SWOT factors",
                    "Create charts showing priority levels or impact scores",
                    "Use color coding to distinguish between categories",
                    "Include relevant data and metrics in your visuals",
                    "Keep designs clean and easy to understand"
                ],
                category: .presentation,
                icon: "chart.bar.fill",
                color: .cyan
            ),
            
            Tip(
                title: "Tell a Story with Your Analysis",
                summary: "Present your findings in a narrative that engages your audience",
                content: [
                    "Start with your current situation and challenges",
                    "Explain how your strengths position you for success",
                    "Describe the opportunities you plan to pursue",
                    "Address how you'll handle potential threats",
                    "End with your strategic recommendations and next steps"
                ],
                category: .presentation,
                icon: "book.fill",
                color: .cyan
            ),
            
            // Additional General Tips
            Tip(
                title: "Use the 5 Whys Technique",
                summary: "Dig deeper into each factor by asking 'why' five times",
                content: [
                    "Start with a surface-level observation",
                    "Ask 'why' this is the case",
                    "Continue asking 'why' for each answer",
                    "Stop when you reach the root cause",
                    "This helps identify the real underlying factors"
                ],
                category: .general,
                icon: "questionmark.circle.fill",
                color: .yellow
            ),
            
            Tip(
                title: "Set a Time Limit",
                summary: "Allocate specific time for each SWOT category to maintain focus",
                content: [
                    "Spend 15-20 minutes on each category",
                    "Use a timer to stay on track",
                    "Don't overthink - capture initial thoughts",
                    "You can always refine later",
                    "Time pressure often leads to better insights"
                ],
                category: .general,
                icon: "timer",
                color: .yellow
            ),
            
            // Additional Strengths Tips
            Tip(
                title: "Ask Others for Input",
                summary: "Get external perspectives on your strengths",
                content: [
                    "Ask customers what they value most about you",
                    "Get feedback from team members and partners",
                    "Consider what others consistently praise",
                    "Look at reviews and testimonials",
                    "External validation often reveals hidden strengths"
                ],
                category: .strengths,
                icon: "person.2.fill",
                color: .green
            ),
            
            Tip(
                title: "Document Your Achievements",
                summary: "Keep a record of successes and accomplishments",
                content: [
                    "Maintain a success journal or log",
                    "Document metrics and measurable results",
                    "Record positive feedback and testimonials",
                    "Track awards, recognition, and milestones",
                    "Review regularly to identify patterns"
                ],
                category: .strengths,
                icon: "trophy.fill",
                color: .green
            ),
            
            // Additional Weaknesses Tips
            Tip(
                title: "Conduct a Skills Audit",
                summary: "Systematically assess your team's capabilities",
                content: [
                    "List all required skills for your goals",
                    "Rate current proficiency levels honestly",
                    "Identify critical skill gaps",
                    "Consider training and development needs",
                    "Plan how to address weaknesses over time"
                ],
                category: .weaknesses,
                icon: "list.clipboard.fill",
                color: .red
            ),
            
            Tip(
                title: "Benchmark Against Competitors",
                summary: "Compare your performance with industry standards",
                content: [
                    "Research competitor capabilities and offerings",
                    "Identify areas where you lag behind",
                    "Look for industry best practices",
                    "Consider what customers expect",
                    "Use benchmarks to set improvement targets"
                ],
                category: .weaknesses,
                icon: "chart.bar.fill",
                color: .red
            ),
            
            // Additional Opportunities Tips
            Tip(
                title: "Monitor Industry Trends",
                summary: "Stay ahead by tracking emerging trends and patterns",
                content: [
                    "Follow industry publications and reports",
                    "Attend conferences and networking events",
                    "Join professional associations",
                    "Monitor social media and online discussions",
                    "Look for early signals of change"
                ],
                category: .opportunities,
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            ),
            
            Tip(
                title: "Explore New Markets",
                summary: "Consider expanding into untapped or underserved markets",
                content: [
                    "Research demographic and geographic segments",
                    "Identify underserved customer needs",
                    "Consider international expansion",
                    "Look for adjacent markets",
                    "Evaluate market size and growth potential"
                ],
                category: .opportunities,
                icon: "globe",
                color: .blue
            ),
            
            // Additional Threats Tips
            Tip(
                title: "Scenario Planning",
                summary: "Prepare for different future scenarios",
                content: [
                    "Create best-case, worst-case, and most-likely scenarios",
                    "Identify key variables that could change",
                    "Develop strategies for each scenario",
                    "Monitor leading indicators",
                    "Regularly update scenarios as conditions change"
                ],
                category: .threats,
                icon: "list.bullet.rectangle.fill",
                color: .orange
            ),
            
            Tip(
                title: "Build Defensive Strategies",
                summary: "Develop plans to protect against potential threats",
                content: [
                    "Diversify your customer base and revenue streams",
                    "Build strong relationships with key stakeholders",
                    "Maintain financial reserves for difficult times",
                    "Develop contingency plans for critical risks",
                    "Regularly stress-test your business model"
                ],
                category: .threats,
                icon: "shield.lefthalf.filled",
                color: .orange
            ),
            
            // Additional Analysis Tips
            Tip(
                title: "Use the SOAR Framework",
                summary: "Focus on Strengths, Opportunities, Aspirations, and Results",
                content: [
                    "Strengths: What are you good at?",
                    "Opportunities: What possibilities exist?",
                    "Aspirations: What do you want to achieve?",
                    "Results: What outcomes do you want?",
                    "This positive approach can be more motivating than SWOT"
                ],
                category: .analysis,
                icon: "star.circle.fill",
                color: .purple
            ),
            
            Tip(
                title: "Create Action Plans",
                summary: "Convert your analysis into specific, actionable steps",
                content: [
                    "For each key finding, create specific actions",
                    "Assign responsibilities and deadlines",
                    "Set measurable goals and milestones",
                    "Identify required resources",
                    "Regularly review and update action plans"
                ],
                category: .analysis,
                icon: "checklist",
                color: .purple
            ),
            
            // Additional Presentation Tips
            Tip(
                title: "Use Data Visualization",
                summary: "Make your analysis more compelling with charts and graphs",
                content: [
                    "Create a SWOT matrix diagram",
                    "Use charts to show priority levels",
                    "Include relevant statistics and metrics",
                    "Use color coding for different categories",
                    "Keep visuals clean and easy to understand"
                ],
                category: .presentation,
                icon: "chart.pie.fill",
                color: .cyan
            ),
            
            Tip(
                title: "Practice Your Presentation",
                summary: "Rehearse to deliver your analysis confidently",
                content: [
                    "Practice explaining each section clearly",
                    "Prepare for questions and challenges",
                    "Time your presentation to fit the audience",
                    "Use stories and examples to illustrate points",
                    "Be ready to adapt based on audience feedback"
                ],
                category: .presentation,
                icon: "mic.fill",
                color: .cyan
            )
        ]
    }
    
    func getTips(for category: TipCategory) -> [Tip] {
        return tips.filter { $0.category == category }
    }
    
    func getRandomTip() -> Tip? {
        return tips.randomElement()
    }
}

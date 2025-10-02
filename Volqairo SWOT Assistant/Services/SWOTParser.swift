import Foundation
import SwiftUI

class SWOTParser: ObservableObject {
    
    static let shared = SWOTParser()
    
    private init() {}
    
    func parseAnalysisResult(_ text: String) -> [AnalysisSection] {
        var sections: [AnalysisSection] = []
        var processedSections = Set<String>()
        
        let cleanedText = cleanText(text)
        print("Parsing analysis result: \(cleanedText.prefix(200))...")
        
        // Define comprehensive patterns for each section
        let sectionPatterns: [(String, [String], Color, String)] = [
            ("STRENGTHS", [
                "### STRENGTHS", "**STRENGTHS:**", "STRENGTHS:", "A. STRENGTHS", "STRENGTHS",
                "## STRENGTHS", "**STRENGTHS**", "1. STRENGTHS", "STRENGTHS ANALYSIS",
                "STRENGTHS:", "• STRENGTHS", "- STRENGTHS", "STRENGTHS -"
            ], .green, "checkmark.circle.fill"),
            
            ("WEAKNESSES", [
                "### WEAKNESSES", "**WEAKNESSES:**", "WEAKNESSES:", "B. WEAKNESSES", "WEAKNESSES",
                "## WEAKNESSES", "**WEAKNESSES**", "2. WEAKNESSES", "WEAKNESSES ANALYSIS",
                "WEAKNESSES:", "• WEAKNESSES", "- WEAKNESSES", "WEAKNESSES -"
            ], .red, "xmark.circle.fill"),
            
            ("OPPORTUNITIES", [
                "### OPPORTUNITIES", "**OPPORTUNITIES:**", "OPPORTUNITIES:", "C. OPPORTUNITIES", "OPPORTUNITIES",
                "## OPPORTUNITIES", "**OPPORTUNITIES**", "3. OPPORTUNITIES", "OPPORTUNITIES ANALYSIS",
                "OPPORTUNITIES:", "• OPPORTUNITIES", "- OPPORTUNITIES", "OPPORTUNITIES -"
            ], .blue, "arrow.up.circle.fill"),
            
            ("THREATS", [
                "### THREATS", "**THREATS:**", "THREATS:", "D. THREATS", "THREATS",
                "## THREATS", "**THREATS**", "4. THREATS", "THREATS ANALYSIS",
                "THREATS:", "• THREATS", "- THREATS", "THREATS -"
            ], .orange, "exclamationmark.triangle.fill"),
            
            ("STRATEGIC RECOMMENDATIONS", [
                "### Strategic Recommendations", "**Strategic Recommendations:**", "Strategic Recommendations:",
                "**III. Strategic Recommendations:**", "## Strategic Recommendations", "**Strategic Recommendations**",
                "RECOMMENDATIONS:", "• RECOMMENDATIONS", "- RECOMMENDATIONS", "RECOMMENDATIONS -",
                "### Recommendations", "**Recommendations:**", "Recommendations:"
            ], .purple, "lightbulb.fill"),
            
            ("SUMMARY", [
                "### Summary", "**Summary:**", "Summary:", "**III. Summary:**", "## Summary",
                "**Summary**", "CONCLUSION:", "• SUMMARY", "- SUMMARY", "SUMMARY -",
                "### Conclusion", "**Conclusion:**", "Conclusion:"
            ], .gray, "doc.text.fill"),
            
            ("ANALYSIS", [
                "### Analysis", "**Analysis:**", "Analysis:", "**II. Analysis:**", "## Analysis",
                "**Analysis**", "DETAILED ANALYSIS:", "• ANALYSIS", "- ANALYSIS", "ANALYSIS -"
            ], .cyan, "magnifyingglass")
        ]
        
        // Parse each section
        for (sectionName, patterns, color, icon) in sectionPatterns {
            if let content = findSectionWithPatterns(sectionName, patterns: patterns, in: cleanedText) {
                if !processedSections.contains(sectionName) {
                    processedSections.insert(sectionName)
                    sections.append(AnalysisSection(
                        title: sectionName,
                        content: content,
                        color: color,
                        icon: icon
                    ))
                }
            }
        }
        
        // If no sections found, create a fallback
        if sections.isEmpty {
            sections.append(AnalysisSection(
                title: "Analysis Summary",
                content: [cleanedText],
                color: .orange,
                icon: "doc.text.fill"
            ))
        }
        
        return sections
    }
    
    private func cleanText(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "|", with: "")
            .replacingOccurrences(of: "---", with: "")
            .replacingOccurrences(of: "___", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func findSectionWithPatterns(_ sectionName: String, patterns: [String], in text: String) -> [String]? {
        for pattern in patterns {
            if let range = text.range(of: pattern, options: [.caseInsensitive]) {
                let startIndex = range.upperBound
                let remainingText = String(text[startIndex...])
                
                // Find the next section or end of text
                let nextSectionPatterns = [
                    "### STRENGTHS", "### WEAKNESSES", "### OPPORTUNITIES", "### THREATS",
                    "**STRENGTHS", "**WEAKNESSES", "**OPPORTUNITIES", "**THREATS",
                    "### Strategic", "### Summary", "### Analysis", "### Conclusion",
                    "**Strategic", "**Summary", "**Analysis", "**Conclusion",
                    "## SWOT", "## Analysis", "## Summary", "## Conclusion",
                    "STRENGTHS:", "WEAKNESSES:", "OPPORTUNITIES:", "THREATS:",
                    "RECOMMENDATIONS:", "SUMMARY:", "ANALYSIS:", "CONCLUSION:"
                ]
                
                var endIndex = remainingText.endIndex
                
                for nextPattern in nextSectionPatterns {
                    if let nextRange = remainingText.range(of: nextPattern, options: .caseInsensitive) {
                        endIndex = min(endIndex, nextRange.lowerBound)
                    }
                }
                
                let sectionContent = String(remainingText[..<endIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !sectionContent.isEmpty {
                    return cleanParagraphContent(sectionContent)
                }
            }
        }
        return nil
    }
    
    private func cleanParagraphContent(_ paragraph: String) -> [String] {
        return paragraph.components(separatedBy: .newlines)
            .map { line in
                line.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "### ", with: "")
                    .replacingOccurrences(of: "## ", with: "")
                    .replacingOccurrences(of: "# ", with: "")
            }
            .filter { !$0.isEmpty && $0.count > 3 && !$0.hasPrefix("#") && !$0.hasPrefix("**") }
            .map { line in
                // Clean up markdown formatting and bullet points
                line.replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "*", with: "")
                    .replacingOccurrences(of: "•", with: "")
                    .replacingOccurrences(of: "◦", with: "")
                    .replacingOccurrences(of: "▪", with: "")
                    .replacingOccurrences(of: "▫", with: "")
                    .replacingOccurrences(of: "- ", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }
}

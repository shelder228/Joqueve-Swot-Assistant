import SwiftUI

struct AnalysisSectionCard: View {
    let section: AnalysisSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: section.icon)
                    .foregroundColor(section.color)
                    .font(.title2)
                
                Text(section.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(section.content, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(section.color)
                            .font(.body)
                        
                        Text(item)
                            .font(.body)
                            .foregroundColor(.gray)
                            .lineSpacing(2)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(section.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

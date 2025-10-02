import SwiftUI

struct SWOTMatrixView: View {
    let strengths: String
    let weaknesses: String
    let opportunities: String
    let threats: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text("SWOT Matrix")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                // Top row
                HStack(spacing: 8) {
                    SWOTMatrixCell(
                        title: "Strengths",
                        content: strengths,
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )
                    
                    SWOTMatrixCell(
                        title: "Weaknesses",
                        content: weaknesses,
                        color: .red,
                        icon: "xmark.circle.fill"
                    )
                }
                
                // Bottom row
                HStack(spacing: 8) {
                    SWOTMatrixCell(
                        title: "Opportunities",
                        content: opportunities,
                        color: .blue,
                        icon: "arrow.up.circle.fill"
                    )
                    
                    SWOTMatrixCell(
                        title: "Threats",
                        content: threats,
                        color: .orange,
                        icon: "exclamationmark.triangle.fill"
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SWOTMatrixCell: View {
    let title: String
    let content: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Text(content)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

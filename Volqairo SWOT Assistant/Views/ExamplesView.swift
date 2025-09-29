import SwiftUI

struct ExamplesView: View {
    @StateObject private var examplesManager = SWOTExamplesManager()
    @ObservedObject var viewModel: SWOTViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Quick Fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Clear All") {
                    clearAllFields()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            // Quick Fill Buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2), spacing: 12) {
                ForEach(examplesManager.examples.prefix(8)) { example in
                    QuickFillButton(
                        example: example,
                        onTap: {
                            applyExample(example)
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
        )
    }
    
    private func applyExample(_ example: SWOTExample) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.currentAnalysisTitle = example.title
            viewModel.strengths = example.strengths
            viewModel.weaknesses = example.weaknesses
            viewModel.opportunities = example.opportunities
            viewModel.threats = example.threats
        }
    }
    
    private func clearAllFields() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.currentAnalysisTitle = ""
            viewModel.strengths = ""
            viewModel.weaknesses = ""
            viewModel.opportunities = ""
            viewModel.threats = ""
        }
    }
}

struct QuickFillButton: View {
    let example: SWOTExample
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: example.icon)
                    .font(.title2)
                    .foregroundColor(example.color)
                
                Text(example.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(example.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExamplesView(viewModel: SWOTViewModel())
}
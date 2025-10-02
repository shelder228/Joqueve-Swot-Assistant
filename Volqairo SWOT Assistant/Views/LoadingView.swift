import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var dotOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(red: 0.1, green: 0, blue: 0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Animated flame icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                VStack(spacing: 16) {
                    Text("Generating Analysis")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("AI is analyzing your SWOT data...")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Animated dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .offset(y: dotOffset)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: dotOffset
                            )
                    }
                }
            }
        }
        .onAppear {
            // Устанавливаем портретную ориентацию
            OrientationManager.restrictToPortrait()
            
            isAnimating = true
            dotOffset = -10
        }
    }
}

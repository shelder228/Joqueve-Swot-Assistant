import SwiftUI

struct TipsView: View {
    @State private var selectedCategory: TipCategory = .general
    @State private var showingTipDetail = false
    @State private var selectedTip: Tip?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Image("BG_1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                
                // Dark overlay for better text readability
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.title)
                                        .foregroundColor(.yellow)
                                    
                                    VStack(alignment: .leading) {
                                        Text("SWOT Analysis Tips")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("Master the art of strategic analysis")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                            )
                            
                            // Category Picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(TipCategory.allCases, id: \.self) { category in
                                        CategoryButton(
                                            category: category,
                                            isSelected: selectedCategory == category,
                                            action: { selectedCategory = category }
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            
                            // Tips List
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 12), 
                                            count: isIPad ? 2 : 1),
                                spacing: 12
                            ) {
                                ForEach(TipsManager.shared.getTips(for: selectedCategory)) { tip in
                                    TipCard(
                                        tip: tip,
                                        onTap: {
                                            print("Tip tapped: \(tip.title)")
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedTip = tip
                                                showingTipDetail = true
                                            }
                                            print("selectedTip set to: \(selectedTip?.title ?? "nil")")
                                            print("showingTipDetail: \(showingTipDetail)")
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: isIPad ? 800 : 400)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Tips")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTipDetail) {
                if let tip = selectedTip {
                    TipDetailView(tip: tip)
                } else {
                    VStack {
                        Text("Error: No tip selected")
                            .foregroundColor(.white)
                        Button("Close") {
                            showingTipDetail = false
                        }
                        .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
            .onChange(of: showingTipDetail) { isPresented in
                if !isPresented {
                    selectedTip = nil
                }
            }
        }
    }
}

struct CategoryButton: View {
    let category: TipCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color : Color(red: 0.2, green: 0.2, blue: 0.2))
            )
            .foregroundColor(isSelected ? .white : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TipCard: View {
    let tip: Tip
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: tip.icon)
                    .font(.title2)
                    .foregroundColor(tip.color)
                    .frame(width: 30)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(tip.summary)
                        .font(.body)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(tip.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TipDetailView: View {
    let tip: Tip
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: tip.icon)
                                .font(.title)
                                .foregroundColor(tip.color)
                            
                            VStack(alignment: .leading) {
                                Text(tip.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(tip.category.displayName)
                                    .font(.caption)
                                    .foregroundColor(tip.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(tip.color.opacity(0.2))
                                    )
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    )
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(tip.content, id: \.self) { paragraph in
                            Text(paragraph)
                                .font(.body)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    )
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [.black, Color(red: 0.1, green: 0, blue: 0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Tip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
            .onAppear {
                // Ensure the view is properly loaded
                print("TipDetailView appeared for: \(tip.title)")
            }
        }
    }
}

#Preview {
    TipsView()
}

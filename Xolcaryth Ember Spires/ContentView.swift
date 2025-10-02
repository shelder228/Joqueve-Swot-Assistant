
import SwiftUI

struct ContentView: View {
    @State private var isMainMenuVisible = false
    
    var body: some View {
        NavigationStack {
            MainMenuView()
                .onAppear {
                    // Устанавливаем landscape ориентацию для главного меню
                    OrientationManager.setLandscapeOnly()
                    isMainMenuVisible = true
                }
                .onDisappear {
                    isMainMenuVisible = false
                }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

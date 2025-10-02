import SwiftUI

enum AppState {
    case trackingPermission
    case loading
    case main
}

@main
struct Volqairo_SWOT_AssistantApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var currentAppState: AppState = .trackingPermission
    
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch currentAppState {
                case .trackingPermission:
                    ScreenView(onStateTransition: { newState in
                        currentAppState = newState
                    })
                case .loading:
                    StartingView(onStateTransition: { newState in
                        currentAppState = newState
                    })
                case .main:
                    ContentView()
                        .preferredColorScheme(.dark)
                }
            }
            .onAppear {
                print("App state: \(currentAppState)")
            }
        }
    }
}


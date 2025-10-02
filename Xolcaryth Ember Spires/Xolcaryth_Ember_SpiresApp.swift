import SwiftUI

enum AppState {
    case trackingPermission
    case loading
    case main
}

@main
struct Xolcaryth_Ember_SpiresApp: App {
    @UIApplicationDelegateAdaptor(XolcaryAppDelegate.self) var appDelegate
    @State private var currentAppState: AppState = .trackingPermission
    
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch currentAppState {
                case .trackingPermission:
                    XolcaryFirstView(onStateTransition: { newState in
                        currentAppState = newState
                    })
                case .loading:
                    MafiaLoadingView(onStateTransition: { newState in
                        currentAppState = newState
                    })
                case .main:
                    ContentView()
                }
            }
            .onAppear {
                print("App state: \(currentAppState)")
            }
        }
    }
}

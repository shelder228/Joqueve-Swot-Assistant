import SwiftUI
import AppTrackingTransparency
import AdSupport

struct ScreenView: View {
    @StateObject private var permissionHandler = ScreenModel()
    let onStateTransition: (AppState) -> Void
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
        }
        .onAppear {
            OrientationManager.enableAllOrientations()
            
            permissionHandler.requestTrackingPermissions()
        }
        .onChange(of: permissionHandler.isPermissionGranted) { isGranted in
            if isGranted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onStateTransition(.loading)
                }
            }
        }
    }
}

#Preview {
    ScreenView { _ in }
}

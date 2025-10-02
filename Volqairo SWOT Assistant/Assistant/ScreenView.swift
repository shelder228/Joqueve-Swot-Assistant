import SwiftUI
import AppTrackingTransparency
import AdSupport

struct ScreenView: View {
    @StateObject private var trackingPermissionManager = ScreenModel()
    let onStateTransition: (AppState) -> Void
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
        }
        .onAppear {
            trackingPermissionManager.requestTrackingPermissions()
        }
        .onChange(of: trackingPermissionManager.isPermissionGranted) { isGranted in
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

import SwiftUI
import AppTrackingTransparency
import AdSupport

struct XolcaryFirstView: View {
    @StateObject private var trackingPermissionManager = XolcaryFirstModel()
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
    XolcaryFirstView { _ in }
}

import SwiftUI

struct StartingView: View {
    @ObservedObject private var appManager = StartingModel.sharedController
    @Environment(\.horizontalSizeClass) var screenWidthCategory
    @Environment(\.verticalSizeClass) var screenHeightCategory
    let onStateTransition: (AppState) -> Void
    
    var body: some View {
        if !appManager.isWebViewShown {
            ZStack {
                if appManager.currentDisplayState == .initial {
                    InitialScreenView(appManager: appManager)
                }
                
                if appManager.currentDisplayState == .notification {
                    NotificationScreenView(appManager: appManager)
                }
                
                if appManager.currentDisplayState == .noConnection {
                    ConnectionErrorScreenView(appManager: appManager)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                OrientationManager.enableAllOrientations()
                appManager.startApplicationSequence()
            }
            .onChange(of: appManager.isReadyToProceed) { canProceed in
                if canProceed && !appManager.isWebViewShown {
                    DispatchQueue.main.async {
                        onStateTransition(.main)
                    }
                }
            }
        } else {
            Color.black
                .ignoresSafeArea(.all)
        }
    }
}

struct InitialScreenView: View {
    @ObservedObject var appManager: StartingModel
    @State private var logoAnimationActive = false
    @State private var titleAnimationActive = false
    @State private var logoScaleFactor = 1.0
    @State private var textScaleFactor = 1.0
    @State private var textRotationAngle = 0.0
    @State private var textOpacity = 1.0
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ZStack {
            Image(verticalSizeClass == .compact ? "BG_1" : "BG_1")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(2.5)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image("GameName")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                    .scaleEffect(logoScaleFactor)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: logoScaleFactor
                    )
                    .onAppear {
                        logoScaleFactor = 1.2
                    }
                
                Image("TextImg")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                    .scaleEffect(textScaleFactor)
                    .rotationEffect(.degrees(textRotationAngle))
                    .opacity(textOpacity)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: textScaleFactor
                    )
                    .animation(
                        Animation.linear(duration: 4.0)
                            .repeatForever(autoreverses: false),
                        value: textRotationAngle
                    )
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: textOpacity
                    )
                    .onAppear {
                        textScaleFactor = 1.2
                        textRotationAngle = 360
                        textOpacity = 0.7
                    }
                    .padding(.top, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
        }
    }
}

struct NotificationScreenView: View {
    @ObservedObject var appManager: StartingModel
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ZStack {
            Image(verticalSizeClass == .compact ? "Bg_3" : "Bg_2")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(2.5)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                if geometry.size.height > geometry.size.width {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        Image("Prom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 90)
                            .padding(.bottom, 0)
                        
                        Image("Tun")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 90)
                            .padding(.bottom, 0)
                        
                        Button(action: {
                            appManager.requestPushNotificationPermission()
                        }) {
                            Image("MainButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 120)
                                .padding(.bottom, 20)
                        }
                        
                        Button(action: {
                            appManager.skipPushNotificationRequest()
                        }) {
                            Image("SideButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 15)
                                .padding(.bottom, 50)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        Image("Prom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 70)
                            .padding(.bottom, 0)
                        
                        Image("Tun")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 80)
                            .padding(.bottom, 0)
                        
                        Button(action: {
                            appManager.requestPushNotificationPermission()
                        }) {
                            Image("MainButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 90)
                                .padding(.bottom, 10)
                        }
                        
                        Button(action: {
                            appManager.skipPushNotificationRequest()
                        }) {
                            Image("SideButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 15)
                                .padding(.bottom, 20)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
        }
    }
}

struct ConnectionErrorScreenView: View {
    @ObservedObject var appManager: StartingModel
    
    var body: some View {
        ZStack {
            Image("BG_1")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(2.5)
                .ignoresSafeArea()
            
            Image("Setting")
                .resizable()
                .scaledToFit()
                .frame(width: 400, height: 400)
        }
    }
}

#Preview {
    StartingView { _ in }
}

import SwiftUI

struct MafiaLoadingView: View {
    @ObservedObject private var loadingController = MafiaLoadingModel.sharedController
    @Environment(\.horizontalSizeClass) var deviceWidthClass
    @Environment(\.verticalSizeClass) var deviceHeightClass
    let onStateTransition: (AppState) -> Void
    
    var body: some View {
        if !loadingController.isWebViewShown {
            ZStack {
                if loadingController.currentDisplayState == .initial {
                    InitialScreenView(loadingController: loadingController)
                }
                
                if loadingController.currentDisplayState == .notification {
                    NotificationScreenView(loadingController: loadingController)
                }
                
                if loadingController.currentDisplayState == .noConnection {
                    ConnectionErrorScreenView(loadingController: loadingController)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                // Устанавливаем все ориентации для загрузочного экрана
                OrientationManager.setAllOrientations()
                loadingController.initializeApplicationFlow()
            }
            .onChange(of: loadingController.isReadyToProceed) { canProceed in
                if canProceed && !loadingController.isWebViewShown {
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
    @ObservedObject var loadingController: MafiaLoadingModel
    @State private var isLogoAnimating = false
    @State private var isTitleAnimating = false
    @State private var logoScale = 1.0
    @State private var textScale = 1.0
    @State private var textOffset = 0.0
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        ZStack {
            Image(verticalSizeClass == .compact ? "LandBG" : "PortBG")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(2.5)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image("NameLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                    .scaleEffect(logoScale)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: logoScale
                    )
                    .onAppear {
                        logoScale = 1.2
                    }
                
                Image("LoadText")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                    .scaleEffect(textScale)
                    .offset(y: textOffset)
                    .opacity(isTitleAnimating ? 0.6 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: textScale
                    )
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: textOffset
                    )
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isTitleAnimating
                    )
                    .onAppear {
                        textScale = 1.1
                        textOffset = -5
                        isTitleAnimating = true
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
    @ObservedObject var loadingController: MafiaLoadingModel
    
    var body: some View {
        ZStack {
            Image("SecondBG")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(2.5)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                if geometry.size.height > geometry.size.width {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        Image("AboutGame")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 90)
                            .padding(.bottom, 0)
                        
                        Image("OurGame")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 90)
                            .padding(.bottom, 0)
                        
                        Button(action: {
                            loadingController.requestPushNotificationPermission()
                        }) {
                            Image("CurrentSlide")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 120)
                                .padding(.bottom, 20)
                        }
                        
                        Button(action: {
                            loadingController.skipPushNotificationRequest()
                        }) {
                            Image("Next")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 25)
                                .padding(.bottom, 50)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        Image("AboutGame")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 70)
                            .padding(.bottom, 0)
                        
                        Image("OurGame")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 80)
                            .padding(.bottom, 0)
                        
                        Button(action: {
                            loadingController.requestPushNotificationPermission()
                        }) {
                            Image("CurrentSlide")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 90)
                                .padding(.bottom, 10)
                        }
                        
                        Button(action: {
                            loadingController.skipPushNotificationRequest()
                        }) {
                            Image("Next")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 25)
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
    @ObservedObject var loadingController: MafiaLoadingModel
    
    var body: some View {
        ZStack {
            Image("PortBG")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(2.5)
                .ignoresSafeArea()
            
            Image("Warn")
                .resizable()
                .scaledToFit()
                .frame(width: 400, height: 400)
        }
    }
}

#Preview {
    MafiaLoadingView { _ in }
}

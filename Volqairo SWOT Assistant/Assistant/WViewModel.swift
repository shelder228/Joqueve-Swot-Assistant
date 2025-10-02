import UIKit
@preconcurrency import WebKit
import MobileCoreServices
import UniformTypeIdentifiers
import ObjectiveC
import AVFoundation

class WViewModel: NSObject {
    private var parentController: UIViewController?
    private var browserInstance: WKWebView?
    private var backNavigationItem: UIBarButtonItem!
    private var startingURL: URL?
    private var retryAttempts = 0
    private var lastURLBeforeRedirect: URL?
    private var loadFinishedCallback: (() -> Void)?
    
    struct BrowserSettings {
        static let maxRetryLimit = 3
    }
    
    init(viewController: UIViewController) {
        super.init()
        self.parentController = viewController
    }
    
    deinit {
        browserInstance?.configuration.userContentController.removeScriptMessageHandler(forName: "openUrl")
        NotificationCenter.default.removeObserver(self)
    }
    
    func displayBrowser(url: String, onLoadCompletionHandler: (() -> Void)? = nil){
        self.loadFinishedCallback = onLoadCompletionHandler
        setupBrowserConfiguration()
        setupNavigationControls()
        setupKeyboardHandling()
        navigateToURL(url: url)
    }
    
    func navigateToURL(url: String) {
        guard let url = URL(string: url) else {
            return
        }
        startingURL = url
        retryAttempts = 0
        browserInstance?.load(URLRequest(url: url))
    }
    
    func refreshBrowserLayout() {
        recalculateFrameForRotation()
    }
    
    private func setupBrowserConfiguration() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptEnabled = true
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        config.userContentController.add(self, name: "openUrl")
        let script = WKUserScript(
            source: """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
            window.openExternalUrl = function(url) {
                window.webkit.messageHandlers.openUrl.postMessage(url);
            };
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(script)
        browserInstance = WKWebView(frame: .zero, configuration: config)
        browserInstance?.navigationDelegate = self
        browserInstance?.uiDelegate = self
        browserInstance?.allowsBackForwardNavigationGestures = true
        browserInstance?.scrollView.contentInsetAdjustmentBehavior = .never
        browserInstance?.backgroundColor = UIColor.black
        browserInstance?.scrollView.backgroundColor = UIColor.black
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceRotated),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        guard let browserInstance = browserInstance else { return }
        
        parentController?.view.backgroundColor = UIColor.black
        
        parentController?.view.addSubview(browserInstance)
        browserInstance.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            browserInstance.topAnchor.constraint(equalTo: parentController!.view.safeAreaLayoutGuide.topAnchor),
            browserInstance.bottomAnchor.constraint(equalTo: parentController!.view.safeAreaLayoutGuide.bottomAnchor),
            browserInstance.leadingAnchor.constraint(equalTo: parentController!.view.safeAreaLayoutGuide.leadingAnchor),
            browserInstance.trailingAnchor.constraint(equalTo: parentController!.view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func setupNavigationControls() {
        backNavigationItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(handleBackNavigation))
        backNavigationItem.isEnabled = false
        parentController?.navigationItem.leftBarButtonItem = backNavigationItem
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(keyboardDidAppear),
                                              name: UIResponder.keyboardWillShowNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(keyboardDidDisappear),
                                              name: UIResponder.keyboardWillHideNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(keyboardFrameChanged),
                                              name: UIResponder.keyboardDidChangeFrameNotification,
                                              object: nil)
    }
    
    @objc private func handleBackNavigation() {
        if browserInstance?.canGoBack == true {
            browserInstance?.goBack()
        }
    }
    
    private func restorePreviousLocation() {
        guard let lastURL = lastURLBeforeRedirect else { return }
        guard let browserInstance = browserInstance else { return }
        if browserInstance.url?.absoluteString != lastURL.absoluteString {
            browserInstance.load(URLRequest(url: lastURL))
        }
        lastURLBeforeRedirect = nil
    }
    
    @objc private func deviceRotated() {
        recalculateFrameForRotation()
    }
    
    private func recalculateFrameForRotation() {
        guard let parentController = parentController else { return }
        browserInstance?.frame = parentController.view.safeAreaLayoutGuide.layoutFrame
    }
    
    @objc private func keyboardDidAppear(notification: NSNotification) {
        guard let browserInstance = browserInstance,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        browserInstance.evaluateJavaScript("""
        (function() {
            var activeElement = document.activeElement;
            if (activeElement && (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA')) {
                var rect = activeElement.getBoundingClientRect();
                return rect.bottom;
            }
            return null;
        })();
        """) { [weak self] (result: Any?, error: Error?) in
            guard let bottom = result as? CGFloat else {
                self?.adjustBrowserForKeyboard(keyboardFrame: keyboardFrame, duration: duration, curve: curve)
                return
            }
            let browserHeight = browserInstance.bounds.height
            let keyboardHeight = keyboardFrame.height
            let visibleAreaHeight = browserHeight - keyboardHeight
            if bottom > visibleAreaHeight {
                let scrollOffset = bottom - visibleAreaHeight + 20
                UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
                    browserInstance.scrollView.contentOffset.y += scrollOffset
                }
            }
        }
    }
    
    private func adjustBrowserForKeyboard(keyboardFrame: CGRect, duration: TimeInterval, curve: UInt) {
        guard let browserInstance = browserInstance else { return }
        let scrollOffset = keyboardFrame.height / 3
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
            browserInstance.scrollView.contentOffset.y += scrollOffset
        }
    }
    
    @objc private func keyboardFrameChanged(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        browserInstance?.evaluateJavaScript("document.activeElement.tagName") { [weak self] (result: Any?, error: Error?) in
            if let tagName = result as? String,
               (tagName == "INPUT" || tagName == "TEXTAREA") {
                self?.keyboardDidAppear(notification: notification)
            }
        }
    }
    
    @objc private func keyboardDidDisappear(notification: NSNotification) {
        guard let browserInstance = browserInstance,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
            browserInstance.scrollView.contentOffset.y = 0
        }
    }
    
    private func displayMediaSelector(sourceType: UIImagePickerController.SourceType, completionHandler: @escaping ([URL]?) -> Void) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        imagePicker.videoQuality = .typeMedium
        imagePicker.allowsEditing = false
        imagePicker.modalPresentationStyle = .fullScreen
        
        if sourceType == .camera {
            imagePicker.cameraCaptureMode = .photo
            imagePicker.cameraDevice = .rear
            imagePicker.videoMaximumDuration = 600
            
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                        DispatchQueue.main.async {
                            if audioGranted {
                                self?.mediaSelectionCallback = completionHandler
                                self?.parentController?.present(imagePicker, animated: true)
                            } else {
                                self?.displayPermissionDialog(message: "Microphone access is required for video recording")
                                completionHandler(nil)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.displayPermissionDialog(message: "Camera access is required")
                        completionHandler(nil)
                    }
                }
            }
        } else {
            mediaSelectionCallback = completionHandler
            parentController?.present(imagePicker, animated: true)
        }
    }
    
    private func displayPermissionDialog(message: String) {
        let alert = UIAlertController(
            title: "Permission Required",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        parentController?.present(alert, animated: true)
    }
    
    private func storeImageInTempLocation(_ image: UIImage) -> URL? {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let uniqueFileName = "\(UUID().uuidString).jpg"
        let destinationURL = tempDirectoryURL.appendingPathComponent(uniqueFileName)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: destinationURL)
                return destinationURL
            } catch {
                return nil
            }
        }
        
        return nil
    }
}

extension WViewModel: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        
        preferences.allowsContentJavaScript = true
        
        if let url = navigationAction.request.url {
            if let scheme = url.scheme?.lowercased() {
                if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "blob" || scheme == "data" {
                    decisionHandler(.allow, preferences)
                    return
                }
            }
            if url.scheme != "http" && url.scheme != "https" {
                lastURLBeforeRedirect = webView.url
                UIApplication.shared.open(url, options: [:]) { [weak self] success in
                    if !success {
                        self?.restorePreviousLocation()
                    }
                }
                
                decisionHandler(.cancel, preferences)
                return
            }
        }
        
        decisionHandler(.allow, preferences)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.isHidden = false
        webView.alpha = 1.0
        webView.backgroundColor = UIColor.black
        webView.scrollView.backgroundColor = UIColor.black
        
        backNavigationItem.isEnabled = webView.canGoBack
        loadFinishedCallback?()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        
        if nsError.code == NSURLErrorCancelled {
            return
        }
        
        if retryAttempts < BrowserSettings.maxRetryLimit,
           let url = nsError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String,
           let errorURL = URL(string: url) {
            retryAttempts += 1
            webView.load(URLRequest(url: errorURL))
        } else {
            retryAttempts = 0
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView,
           requestMediaCapturePermissionFor origin: WKSecurityOrigin,
           initiatedByFrame frame: WKFrameInfo,
           type: WKMediaCaptureType,
           decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        
        displayMediaSelector(sourceType: .camera) { [weak self] urls in
        }
        
        decisionHandler(.grant)
    }
    
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: Any?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let alert = UIAlertController(title: "Choose source", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.displayMediaSelector(sourceType: .camera, completionHandler: completionHandler)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
            self?.displayMediaSelector(sourceType: .photoLibrary, completionHandler: completionHandler)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = webView
            popoverController.sourceRect = CGRect(x: webView.bounds.midX, y: webView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        parentController?.present(alert, animated: true)
    }
}

extension WViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "openUrl" {
            if let urlString = message.body as? String,
               let url = URL(string: urlString) {
                lastURLBeforeRedirect = browserInstance?.url
                UIApplication.shared.open(url, options: [:]) { [weak self] success in
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.restorePreviousLocation()
                        }
                    }
                }
            }
        }
    }
}

extension WViewModel: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private struct AssociatedKeys {
        static var callbackHandlerKey = "mediaSelectionCompletionHandler"
    }
    
    private var mediaSelectionCallback: (([URL]?) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.callbackHandlerKey) as? ([URL]?) -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.callbackHandlerKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[.mediaType] as? String
        
        var mediaURL: URL?
        
        if mediaType == "public.movie" {
            if let url = info[.mediaURL] as? URL {
                mediaURL = url
            }
        } else {
            if let image = info[.originalImage] as? UIImage {
                mediaURL = storeImageInTempLocation(image)
            }
        }
        
        DispatchQueue.main.async {
            picker.dismiss(animated: true) { [weak self] in
                if let url = mediaURL {
                    self?.mediaSelectionCallback?([url])
                } else {
                    self?.mediaSelectionCallback?(nil)
                }
                self?.mediaSelectionCallback = nil
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true) { [weak self] in
                self?.mediaSelectionCallback?(nil)
                self?.mediaSelectionCallback = nil
            }
        }
    }
}

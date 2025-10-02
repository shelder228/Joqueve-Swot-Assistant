import UIKit
@preconcurrency import WebKit
import MobileCoreServices
import UniformTypeIdentifiers
import ObjectiveC
import AVFoundation

class WViewModel: NSObject {
    private var hostViewController: UIViewController?
    private var webBrowserView: WKWebView?
    private var navigationBackButton: UIBarButtonItem!
    private var initialURL: URL?
    private var redirectCount = 0
    private var previousURLBeforeDeeplink: URL?
    private var onLoadCompletionHandler: (() -> Void)?
    
    struct ConfigurationConstants {
        static let maximumRedirects = 3
    }
    
    // MARK: - Initialization
    init(viewController: UIViewController) {
        super.init()
        self.hostViewController = viewController
    }
    
    deinit {
        webBrowserView?.configuration.userContentController.removeScriptMessageHandler(forName: "openUrl")
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    func openWebView(url: String, onLoadCompletionHandler: (() -> Void)? = nil){
        self.onLoadCompletionHandler = onLoadCompletionHandler
        configureBrowserView()
        configureNavigationBar()
        configureKeyboardEvents()
        loadWebContent(url: url)
    }
    
    func loadWebContent(url: String) {
        guard let url = URL(string: url) else {
            return
        }
        initialURL = url
        redirectCount = 0
        webBrowserView?.load(URLRequest(url: url))
    }
    
    func updateBrowserFrame() {
        adjustFrameForOrientation()
    }
    
    // MARK: - Setup Methods
    private func configureBrowserView() {
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
        webBrowserView = WKWebView(frame: .zero, configuration: config)
        webBrowserView?.navigationDelegate = self
        webBrowserView?.uiDelegate = self
        webBrowserView?.allowsBackForwardNavigationGestures = true
        webBrowserView?.scrollView.contentInsetAdjustmentBehavior = .never
        webBrowserView?.backgroundColor = UIColor.black
        webBrowserView?.scrollView.backgroundColor = UIColor.black
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationChanged),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        guard let webBrowserView = webBrowserView else { return }
        
        hostViewController?.view.backgroundColor = UIColor.black
        
        hostViewController?.view.addSubview(webBrowserView)
        webBrowserView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webBrowserView.topAnchor.constraint(equalTo: hostViewController!.view.safeAreaLayoutGuide.topAnchor),
            webBrowserView.bottomAnchor.constraint(equalTo: hostViewController!.view.safeAreaLayoutGuide.bottomAnchor),
            webBrowserView.leadingAnchor.constraint(equalTo: hostViewController!.view.safeAreaLayoutGuide.leadingAnchor),
            webBrowserView.trailingAnchor.constraint(equalTo: hostViewController!.view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func configureNavigationBar() {
        navigationBackButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(navigateBack))
        navigationBackButton.isEnabled = false
        hostViewController?.navigationItem.leftBarButtonItem = navigationBackButton
    }
    
    private func configureKeyboardEvents() {
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(keyboardWillShow),
                                              name: UIResponder.keyboardWillShowNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(keyboardWillHide),
                                              name: UIResponder.keyboardWillHideNotification,
                                              object: nil)
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(keyboardDidChangeFrame),
                                              name: UIResponder.keyboardDidChangeFrameNotification,
                                              object: nil)
    }
    
    // MARK: - Navigation Methods
    @objc private func navigateBack() {
        if webBrowserView?.canGoBack == true {
            webBrowserView?.goBack()
        }
    }
    
    private func returnToPreviousPage() {
        guard let lastURL = previousURLBeforeDeeplink else { return }
        guard let webBrowserView = webBrowserView else { return }
        if webBrowserView.url?.absoluteString != lastURL.absoluteString {
            webBrowserView.load(URLRequest(url: lastURL))
        }
        previousURLBeforeDeeplink = nil
    }
    
    // MARK: - Orientation Management
    @objc private func orientationChanged() {
        adjustFrameForOrientation()
    }
    
    private func adjustFrameForOrientation() {
        guard let hostViewController = hostViewController else { return }
        webBrowserView?.frame = hostViewController.view.safeAreaLayoutGuide.layoutFrame
    }
    
    // MARK: - Keyboard Management
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let webBrowserView = webBrowserView,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        webBrowserView.evaluateJavaScript("""
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
                self?.scrollBrowserForKeyboard(keyboardFrame: keyboardFrame, duration: duration, curve: curve)
                return
            }
            let browserHeight = webBrowserView.bounds.height
            let keyboardHeight = keyboardFrame.height
            let visibleAreaHeight = browserHeight - keyboardHeight
            if bottom > visibleAreaHeight {
                let scrollOffset = bottom - visibleAreaHeight + 20
                UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
                    webBrowserView.scrollView.contentOffset.y += scrollOffset
                }
            }
        }
    }
    
    private func scrollBrowserForKeyboard(keyboardFrame: CGRect, duration: TimeInterval, curve: UInt) {
        guard let webBrowserView = webBrowserView else { return }
        let scrollOffset = keyboardFrame.height / 3
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
            webBrowserView.scrollView.contentOffset.y += scrollOffset
        }
    }
    
    @objc private func keyboardDidChangeFrame(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        webBrowserView?.evaluateJavaScript("document.activeElement.tagName") { [weak self] (result: Any?, error: Error?) in
            if let tagName = result as? String,
               (tagName == "INPUT" || tagName == "TEXTAREA") {
                self?.keyboardWillShow(notification: notification)
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let webBrowserView = webBrowserView,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve << 16)) {
            webBrowserView.scrollView.contentOffset.y = 0
        }
    }
    
    // MARK: - Media Picker Methods
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType, completionHandler: @escaping ([URL]?) -> Void) {
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
                                self?.filePickerCompletionHandler = completionHandler
                                self?.hostViewController?.present(imagePicker, animated: true)
                            } else {
                                self?.showPermissionAlert(message: "Microphone access is required for video recording")
                                completionHandler(nil)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showPermissionAlert(message: "Camera access is required")
                        completionHandler(nil)
                    }
                }
            }
        } else {
            filePickerCompletionHandler = completionHandler
            hostViewController?.present(imagePicker, animated: true)
        }
    }
    
    private func showPermissionAlert(message: String) {
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
        
        hostViewController?.present(alert, animated: true)
    }
    
    private func saveImageToTemporaryFile(_ image: UIImage) -> URL? {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
                return fileURL
            } catch {
                return nil
            }
        }
        
        return nil
    }
}

// MARK: - WKNavigationDelegate, WKUIDelegate
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
                
                previousURLBeforeDeeplink = webView.url
                
                UIApplication.shared.open(url, options: [:]) { [weak self] success in
                    if success {
                    } else {
                        self?.returnToPreviousPage()
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
        
        navigationBackButton.isEnabled = webView.canGoBack
        onLoadCompletionHandler?()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        
        if nsError.code == NSURLErrorCancelled {
            return
        }
        
        if redirectCount < ConfigurationConstants.maximumRedirects,
           let url = nsError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String,
           let errorURL = URL(string: url) {
            redirectCount += 1
            webView.load(URLRequest(url: errorURL))
        } else {
            redirectCount = 0
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
        
        presentImagePicker(sourceType: .camera) { [weak self] urls in
            if let url = urls?.first {
            } else {
            }
        }
        
        decisionHandler(.grant)
    }
    
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: Any?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let alert = UIAlertController(title: "Choose source", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera, completionHandler: completionHandler)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary, completionHandler: completionHandler)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = webView
            popoverController.sourceRect = CGRect(x: webView.bounds.midX, y: webView.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        hostViewController?.present(alert, animated: true)
    }
}

// MARK: - WKScriptMessageHandler
extension WViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "openUrl" {
            if let urlString = message.body as? String,
               let url = URL(string: urlString) {
                
                previousURLBeforeDeeplink = webBrowserView?.url
                
                UIApplication.shared.open(url, options: [:]) { [weak self] success in
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.returnToPreviousPage()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension WViewModel: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private struct AssociatedKeys {
        static var completionHandlerKey = "filePickerCompletionHandler"
    }
    
    private var filePickerCompletionHandler: (([URL]?) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.completionHandlerKey) as? ([URL]?) -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.completionHandlerKey, newValue, .OBJC_ASSOCIATION_RETAIN)
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
                mediaURL = saveImageToTemporaryFile(image)
            }
        }
        
        DispatchQueue.main.async {
            picker.dismiss(animated: true) { [weak self] in
                if let url = mediaURL {
                    self?.filePickerCompletionHandler?([url])
                } else {
                    self?.filePickerCompletionHandler?(nil)
                }
                self?.filePickerCompletionHandler = nil
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true) { [weak self] in
                self?.filePickerCompletionHandler?(nil)
                self?.filePickerCompletionHandler = nil
            }
        }
    }
}

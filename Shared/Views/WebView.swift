// https://gist.github.com/swiftui-lab/a873bf413770db6fd1a525fa424ce8cd

import Combine
import SwiftUI
import UniformTypeIdentifiers
import WebKit
import Types

final class WebViewData: ObservableObject {
    @Published var loading: Bool = false
    @Published var scrollPercent: Float = 0
    @Published var url: URL? = nil
    @Published var urlBar: String = "https://nasa.gov"
    @Published var progress: CGFloat = 0
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var webViewId: UUID = UUID()

    var observation: NSKeyValueObservation?
    weak var coordinator: WebViewCoordinator?

    init(url: URL?) {
        _url = Published(initialValue: url)
    }

    var scrollOnLoad: Float?
    
    func goBack() {
        coordinator?.goBack()
    }
    
    func goForward() {
        coordinator?.goForward()
    }
    
    func clearNavigationHistory() {
        webViewId = UUID()  // This will force SwiftUI to recreate the WebView
        canGoBack = false
        canGoForward = false
    }
}

#if os(macOS)
    struct WebView: NSViewRepresentable {
        @ObservedObject var data: WebViewData

        func makeNSView(context: Context) -> WKWebView {
            data.coordinator = context.coordinator
            return context.coordinator.webView
        }

        func updateNSView(_ nsView: WKWebView, context: Context) {
            data.coordinator = context.coordinator
            guard context.coordinator.loadedUrl != data.url else { return }
            nsView.evaluateJavaScript("document.body.remove()")
            data.observation = nsView.observe(\.estimatedProgress) { view, _ in
                data.progress = view.estimatedProgress
            }

            guard context.coordinator.loadedUrl != data.url else { return }
            context.coordinator.loadedUrl = data.url

            if let url = data.url {
                DispatchQueue.main.async {
                    let request = URLRequest(url: url)
                    nsView.load(request)
                }
            }
        }

        func makeCoordinator() -> WebViewCoordinator {
            return WebViewCoordinator(data: data)
        }
    }

#else

    struct WebView: UIViewRepresentable {
        @ObservedObject var data: WebViewData

        func makeUIView(context: Context) -> WKWebView {
            data.coordinator = context.coordinator
            return context.coordinator.webView
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
            data.coordinator = context.coordinator
            guard context.coordinator.loadedUrl != data.url else { return }
            uiView.evaluateJavaScript("document.body.remove()")
            data.observation = uiView.observe(\.estimatedProgress) { view, _ in
                data.progress = view.estimatedProgress
            }

            guard context.coordinator.loadedUrl != data.url else { return }
            context.coordinator.loadedUrl = data.url

            if let url = data.url {
                DispatchQueue.main.async {
                    let request = URLRequest(url: url)
                    uiView.load(request)
                }
            }

            context.coordinator.data.url = data.url
        }

        func makeCoordinator() -> WebViewCoordinator {
            return WebViewCoordinator(data: data)
        }
    }

#endif

final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    @ObservedObject var data: WebViewData

    var webView: WKWebView = .init()
    var loadedUrl: URL?

    init(data: WebViewData) {
        self.data = data

        super.init()

        setupScripts()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Initial navigation state
        updateNavigationState()
    }
    
    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    
    private func updateNavigationState() {
        DispatchQueue.main.async {
            self.data.objectWillChange.send()
            self.data.canGoBack = self.webView.canGoBack
            self.data.canGoForward = self.webView.canGoForward
        }
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        DispatchQueue.main.async {
            if let scrollOnLoad = self.data.scrollOnLoad {
                self.scrollTo(scrollOnLoad)
                self.data.scrollOnLoad = nil
            }

            self.data.loading = false

            if let urlstr = webView.url?.absoluteString {
                self.data.urlBar = urlstr
            }
            
            self.updateNavigationState()
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        DispatchQueue.main.async { 
            self.data.loading = true
            self.updateNavigationState()
        }
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        showError(title: "Navigation Error", message: error.localizedDescription)
        DispatchQueue.main.async { 
            self.data.loading = false
            self.updateNavigationState()
        }
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        showError(title: "Loading Error", message: error.localizedDescription)
        DispatchQueue.main.async { 
            self.data.loading = false
            self.updateNavigationState()
        }
    }

    func scrollTo(_ percent: Float) {
        let js = "scrollToPercent(\(percent))"

        webView.evaluateJavaScript(js)
    }

    func setupScripts() {
//        let monitor = WKUserScript(
//            source: ScrollMonitorScript.monitorScript,
//            injectionTime: .atDocumentEnd,
//            forMainFrameOnly: true
//        )
//
//        let scrollTo = WKUserScript(
//            source: ScrollMonitorScript.scrollTo,
//            injectionTime: .atDocumentEnd,
//            forMainFrameOnly: true
//        )
//
//        webView.configuration.userContentController.addUserScript(monitor)
//        webView.configuration.userContentController.addUserScript(scrollTo)
//
//        let msgHandler = ScrollMonitorScript { percent in
//            DispatchQueue.main.async {
//                self.data.scrollPercent = percent
//            }
//        }
//
//        webView.configuration.userContentController.add(msgHandler, contentWorld: .page, name: "notifyScroll")
    }

    func showError(title: String, message: String) {
        #if os(macOS)
            let alert = NSAlert()

            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning

            alert.runModal()
        #else
            print("\(title): \(message)")
        #endif
    }
}

class ScrollMonitorScript: NSObject, WKScriptMessageHandler {
    let callback: (Float) -> Void

    static var monitorScript: String {
        return """
            let last_known_scroll_position = 0;
            let ticking = false;

            function getScrollPercent() {
                var docu = document.documentElement;
                let t = docu.scrollTop;
                let h = docu.scrollHeight;
                let ch = docu.clientHeight
                return (t / (h - ch)) * 100;
            }

            window.addEventListener('scroll', function(e) {
                window.webkit.messageHandlers.notifyScroll.postMessage(getScrollPercent());
            });
        """
    }

    static var scrollTo: String {
        return """
           function scrollToPercent(pct) {
               var docu = document.documentElement;
               let h = docu.scrollHeight;
               let ch = docu.clientHeight
               let t = (pct * (h - ch)) / 100;
               window.scrollTo(0, t);
           }
        """
    }

    init(callback: @escaping (Float) -> Void) {
        self.callback = callback
    }

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        if let percent = message.body as? NSNumber {
            callback(percent.floatValue)
        }
    }
}

struct DataWebView: View {
    var archiveLink: ArchiveLink
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            #if os(macOS)
            DataWebViewRepresentable(archiveLink: archiveLink, isLoading: $isLoading)
            #else
            DataWebViewRepresentable(archiveLink: archiveLink, isLoading: $isLoading)
            #endif
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.primary.colorInvert().opacity(0.8))
            }
        }
    }
}

#if os(macOS)
    struct DataWebViewRepresentable: NSViewRepresentable {
        var archiveLink: ArchiveLink
        @Binding var isLoading: Bool

        func makeNSView(context: Context) -> WKWebView {
            let webView = WKWebView()
            webView.navigationDelegate = context.coordinator
            return webView
        }

        func updateNSView(_ nsView: WKWebView, context _: Context) {
            DispatchQueue.main.async {
                guard let data = try? Data(contentsOf: archiveLink.dataURL) else { 
                    isLoading = false
                    return 
                }
                let baseURL = URL(string: "about:blank")!
                let mimeType = UTType.webArchive.preferredMIMEType!
                nsView.load(
                    data,
                    mimeType: mimeType,
                    characterEncodingName: "utf-8",
                    baseURL: baseURL
                )
            }
        }
        
        func makeCoordinator() -> DataWebViewCoordinator {
            DataWebViewCoordinator(isLoading: $isLoading)
        }

        private func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }
    }
#else
    struct DataWebViewRepresentable: UIViewRepresentable {
        var archiveLink: ArchiveLink
        @Binding var isLoading: Bool

        func makeUIView(context: Context) -> WKWebView {
            let webView = WKWebView()
            webView.navigationDelegate = context.coordinator
            return webView
        }

        func updateUIView(_ uiView: WKWebView, context _: Context) {
            DispatchQueue.main.async {
                guard let data = try? Data(contentsOf: archiveLink.dataURL) else { 
                    isLoading = false
                    return 
                }
                let baseURL = URL(string: "about:blank")!
                let mimeType = UTType.webArchive.preferredMIMEType!
                uiView.load(
                    data,
                    mimeType: mimeType,
                    characterEncodingName: "utf-8",
                    baseURL: baseURL
                )
            }
        }
        
        func makeCoordinator() -> DataWebViewCoordinator {
            DataWebViewCoordinator(isLoading: $isLoading)
        }

        private func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }
    }
#endif

class DataWebViewCoordinator: NSObject, WKNavigationDelegate {
    @Binding var isLoading: Bool
    
    init(isLoading: Binding<Bool>) {
        self._isLoading = isLoading
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}

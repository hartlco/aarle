// https://gist.github.com/swiftui-lab/a873bf413770db6fd1a525fa424ce8cd

import Combine
import SwiftUI
import UniformTypeIdentifiers
import WebKit
import Types

class WebViewData: ObservableObject {
    @Published var loading: Bool = false
    @Published var scrollPercent: Float = 0
    @Published var url: URL? = nil
    @Published var urlBar: String = "https://nasa.gov"

    init(url: URL?) {
        _url = Published(initialValue: url)
    }

    var scrollOnLoad: Float?
}

#if os(macOS)
    struct WebView: NSViewRepresentable {
        @ObservedObject var data: WebViewData

        func makeNSView(context: Context) -> WKWebView {
            return context.coordinator.webView
        }

        func updateNSView(_ nsView: WKWebView, context: Context) {
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
            return context.coordinator.webView
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
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

class WebViewCoordinator: NSObject, WKNavigationDelegate {
    @ObservedObject var data: WebViewData

    var webView: WKWebView = .init()
    var loadedUrl: URL?

    init(data: WebViewData) {
        self.data = data

        super.init()

        setupScripts()
        webView.navigationDelegate = self
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
        }
    }

    func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        DispatchQueue.main.async { self.data.loading = true }
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        showError(title: "Navigation Error", message: error.localizedDescription)
        DispatchQueue.main.async { self.data.loading = false }
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        showError(title: "Loading Error", message: error.localizedDescription)
        DispatchQueue.main.async { self.data.loading = false }
    }

    func scrollTo(_ percent: Float) {
        let js = "scrollToPercent(\(percent))"

        webView.evaluateJavaScript(js)
    }

    func setupScripts() {
        let monitor = WKUserScript(
            source: ScrollMonitorScript.monitorScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )

        let scrollTo = WKUserScript(
            source: ScrollMonitorScript.scrollTo,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )

        webView.configuration.userContentController.addUserScript(monitor)
        webView.configuration.userContentController.addUserScript(scrollTo)

        let msgHandler = ScrollMonitorScript { percent in
            DispatchQueue.main.async {
                self.data.scrollPercent = percent
            }
        }

        webView.configuration.userContentController.add(msgHandler, contentWorld: .page, name: "notifyScroll")
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

#if os(macOS)
    struct DataWebView: NSViewRepresentable {
        var archiveLink: ArchiveLink

        func makeNSView(context _: Context) -> WKWebView {
            return WKWebView()
        }

        func updateNSView(_ nsView: WKWebView, context _: Context) {
            DispatchQueue.main.async {
                let data = try! Data(contentsOf: archiveLink.dataURL)
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

        private func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }
    }
#else
    struct DataWebView: UIViewRepresentable {
        var archiveLink: ArchiveLink

        func makeUIView(context _: Context) -> WKWebView {
            return WKWebView()
        }

        func updateUIView(_ uiView: WKWebView, context _: Context) {
            DispatchQueue.main.async {
                let data = try! Data(contentsOf: archiveLink.dataURL)
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

        private func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }
    }
#endif

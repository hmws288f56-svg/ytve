import SwiftUI
import WebKit

@main
struct NoCommentTubeApp: App {
    var body: some Scene {
        WindowGroup {
            WebView()
                .ignoresSafeArea(.container, edges: .bottom)
                .background(Color.black)
        }
    }
}

struct WebView: UIViewRepresentable {
    private static let home = URL(string: "https://m.youtube.com/")!

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        config.websiteDataStore = .default()
        // Google refuses sign-in from user agents that look like an embedded web view.
        config.applicationNameForUserAgent = "Version/17.4 Mobile/15E148 Safari/604.1"
        config.userContentController.addUserScript(HideComments.userScript)
        AdBlock.userScripts.forEach(config.userContentController.addUserScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        // The block rules must be in place before the first request goes out.
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: AdBlock.ruleListID,
            encodedContentRuleList: AdBlock.ruleListJSON
        ) { ruleList, _ in
            if let ruleList = ruleList {
                webView.configuration.userContentController.add(ruleList)
            }
            webView.load(URLRequest(url: Self.home))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Stay inside the web view: drop youtube://, itms-apps:// and similar
            // links that would hand off to the official app or the App Store.
            let scheme = navigationAction.request.url?.scheme?.lowercased() ?? ""
            let allowed = ["http", "https", "about", "blob", "data"]
            decisionHandler(allowed.contains(scheme) ? .allow : .cancel)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            // target="_blank" links open in the same view instead of being ignored.
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }
    }
}

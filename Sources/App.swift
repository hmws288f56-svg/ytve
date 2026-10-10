import SwiftUI
import WebKit

@main
struct NoCommentTubeApp: App {
    @StateObject private var browser = Browser()

    var body: some Scene {
        WindowGroup {
            TabView {
                WebView(webView: browser.webView)
                    .background(Color.black)
                    .tabItem { Label("YouTube", systemImage: "play.rectangle.fill") }
                SettingsView(browser: browser)
                    .tabItem { Label("설정", systemImage: "gearshape.fill") }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}

struct SettingsView: View {
    let browser: Browser
    @AppStorage(Shorts.defaultsKey) private var disableShorts = false

    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("하단의 Shorts 탭과 홈·검색에 나오는 쇼츠를 숨깁니다. 쇼츠 링크를 열면 일반 영상 화면으로 재생됩니다.")) {
                    Toggle("쇼츠 비활성화", isOn: $disableShorts)
                }
            }
            .navigationTitle("설정")
        }
        .navigationViewStyle(.stack)
        .onChange(of: disableShorts) { disabled in
            browser.setShortsDisabled(disabled)
        }
    }
}

/// Owns the single web view so the settings tab can change how it behaves.
@MainActor
final class Browser: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    private static let home = URL(string: "https://m.youtube.com/")!

    let webView: WKWebView

    override init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        config.websiteDataStore = .default()
        // Google refuses sign-in from user agents that look like an embedded web view.
        config.applicationNameForUserAgent = "Version/17.4 Mobile/15E148 Safari/604.1"

        webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        installUserScripts()

        // The block rules must be in place before the first request goes out.
        let webView = self.webView
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: AdBlock.ruleListID,
            encodedContentRuleList: AdBlock.ruleListJSON
        ) { ruleList, _ in
            if let ruleList = ruleList {
                webView.configuration.userContentController.add(ruleList)
            }
            webView.load(URLRequest(url: Browser.home))
        }
    }

    func setShortsDisabled(_ disabled: Bool) {
        // Future page loads pick the setting up from the user scripts;
        // the page that is already open is switched in place.
        installUserScripts()
        webView.evaluateJavaScript(
            "window.__nctSetNoShorts && window.__nctSetNoShorts(\(disabled ? "true" : "false"))")
    }

    private func installUserScripts() {
        let controller = webView.configuration.userContentController
        controller.removeAllUserScripts()
        controller.addUserScript(HideComments.userScript)
        AdBlock.userScripts.forEach(controller.addUserScript)
        Shorts.userScripts(disabled: Shorts.isDisabled).forEach(controller.addUserScript)
    }

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

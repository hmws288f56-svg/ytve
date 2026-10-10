import WebKit

enum Injection {
    /// A user script that keeps a `<style>` with the given CSS attached to the page.
    static func styleScript(id: String, css: String) -> WKUserScript {
        let source = """
        (function () {
            var style = document.createElement('style');
            style.id = '\(id)';
            style.textContent = `\(css)`;
            function attach() {
                if (!style.isConnected) {
                    (document.head || document.documentElement).appendChild(style);
                }
            }
            attach();
            new MutationObserver(attach).observe(document.documentElement, { childList: true });
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}

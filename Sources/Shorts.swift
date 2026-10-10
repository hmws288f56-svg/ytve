import WebKit

enum Shorts {
    static let defaultsKey = "disableShorts"

    static var isDisabled: Bool {
        UserDefaults.standard.bool(forKey: defaultsKey)
    }

    // Selectors checked against m.youtube.com on 2026-10-10. The rules only apply
    // while <html> carries the nct-no-shorts attribute, so the setting can be
    // switched without reloading the page.
    static let css = """
    /* 하단 탭의 Shorts */
    html[nct-no-shorts] ytm-pivot-bar-item-renderer:has(.pivot-shorts),
    /* 홈/구독 피드의 쇼츠 묶음 */
    html[nct-no-shorts] ytm-rich-section-renderer:has(ytm-shorts-lockup-view-model),
    html[nct-no-shorts] grid-shelf-view-model:has(ytm-shorts-lockup-view-model),
    html[nct-no-shorts] ytm-reel-shelf-renderer,
    html[nct-no-shorts] ytm-shorts-lockup-view-model,
    /* 검색 결과·추천 목록에 낱개로 섞인 쇼츠 */
    html[nct-no-shorts] ytm-video-with-context-renderer:has(a[href^="/shorts/"]),
    html[nct-no-shorts] ytm-compact-video-renderer:has(a[href^="/shorts/"]),
    html[nct-no-shorts] ytm-rich-item-renderer:has(a[href^="/shorts/"]),
    /* 데스크톱 레이아웃(iPad) */
    html[nct-no-shorts] ytd-reel-shelf-renderer,
    html[nct-no-shorts] ytd-rich-shelf-renderer[is-shorts],
    html[nct-no-shorts] ytd-rich-section-renderer:has(ytd-rich-shelf-renderer[is-shorts]),
    html[nct-no-shorts] ytd-video-renderer:has(a[href^="/shorts/"]),
    html[nct-no-shorts] ytd-guide-entry-renderer:has(a[title="Shorts"]),
    html[nct-no-shorts] ytd-mini-guide-entry-renderer[aria-label="Shorts"] {
        display: none !important;
    }
    """

    // Sets the attribute the CSS keys on, and keeps the Shorts player unreachable:
    // the Shorts feed goes home, a single short opens in the regular player.
    private static let script = #"""
    (function () {
        var on = __DISABLED__;

        function apply() {
            var root = document.documentElement;
            if (!root) return;
            if (on) root.setAttribute('nct-no-shorts', '');
            else root.removeAttribute('nct-no-shorts');
        }

        function redirect() {
            if (!on) return;
            var p = location.pathname;
            if (p === '/shorts' || p.indexOf('/shorts/') === 0) {
                var id = p.split('/')[2];
                location.replace(id ? '/watch?v=' + encodeURIComponent(id) : '/');
            }
        }

        window.__nctSetNoShorts = function (value) {
            on = !!value;
            apply();
            redirect();
        };

        apply();
        redirect();
        setInterval(redirect, 300);
    })();
    """#

    static func userScripts(disabled: Bool) -> [WKUserScript] {
        let source = script.replacingOccurrences(of: "__DISABLED__", with: disabled ? "true" : "false")
        return [
            WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true),
            Injection.styleScript(id: "nct-hide-shorts", css: css),
        ]
    }
}

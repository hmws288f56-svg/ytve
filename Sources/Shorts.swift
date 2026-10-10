import WebKit

enum Shorts {
    // Selectors checked against m.youtube.com on 2026-10-10.
    static let css = """
    /* 하단 탭의 Shorts */
    ytm-pivot-bar-item-renderer:has(.pivot-shorts),
    /* 홈/구독 피드의 쇼츠 묶음 */
    ytm-rich-section-renderer:has(ytm-shorts-lockup-view-model),
    grid-shelf-view-model:has(ytm-shorts-lockup-view-model),
    ytm-reel-shelf-renderer,
    ytm-shorts-lockup-view-model,
    /* 검색 결과·추천 목록에 낱개로 섞인 쇼츠 */
    ytm-video-with-context-renderer:has(a[href^="/shorts/"]),
    ytm-compact-video-renderer:has(a[href^="/shorts/"]),
    ytm-rich-item-renderer:has(a[href^="/shorts/"]),
    /* 데스크톱 레이아웃(iPad) */
    ytd-reel-shelf-renderer,
    ytd-rich-shelf-renderer[is-shorts],
    ytd-rich-section-renderer:has(ytd-rich-shelf-renderer[is-shorts]),
    ytd-video-renderer:has(a[href^="/shorts/"]),
    ytd-guide-entry-renderer:has(a[title="Shorts"]),
    ytd-mini-guide-entry-renderer[aria-label="Shorts"] {
        display: none !important;
    }
    """

    // Keeps the Shorts player unreachable even through a direct link:
    // the Shorts feed goes home, a single short opens in the regular player.
    private static let script = #"""
    (function () {
        function redirect() {
            var p = location.pathname;
            if (p === '/shorts' || p.indexOf('/shorts/') === 0) {
                var id = p.split('/')[2];
                location.replace(id ? '/watch?v=' + encodeURIComponent(id) : '/');
            }
        }
        redirect();
        setInterval(redirect, 300);
    })();
    """#

    static var userScripts: [WKUserScript] {
        [
            WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true),
            Injection.styleScript(id: "nct-hide-shorts", css: css),
        ]
    }
}

import WebKit

enum AdBlock {
    // 피드/검색 결과에 끼어드는 광고 칸. 플레이어 안의 광고 UI는 숨기지 않는다:
    // 자동 건너뛰기가 실패했을 때 직접 누를 건너뛰기 버튼이 남아 있어야 한다.
    static let css = """
    ad-slot-renderer,
    ytm-rich-item-renderer:has(ad-slot-renderer),
    ytm-promoted-video-renderer,
    ytm-promoted-sparkles-web-renderer,
    ytm-promoted-sparkles-text-search-renderer,
    ytm-in-feed-ad-layout-renderer,
    ytm-companion-ad-renderer,
    ytm-companion-slot,
    /* 데스크톱 레이아웃(iPad) */
    ytd-ad-slot-renderer,
    ytd-rich-item-renderer:has(ytd-ad-slot-renderer),
    ytd-in-feed-ad-layout-renderer,
    ytd-promoted-sparkles-web-renderer,
    #player-ads,
    #masthead-ad {
        display: none !important;
    }
    """

    // Checked against m.youtube.com on 2026-10-10. Works in two layers:
    // 1) strip the ad fields from player/shorts responses before YouTube reads them,
    // 2) if an ad still starts, jump to its end and press the skip button.
    static let script = #"""
    (function () {
        if (window.__nctAdBlock) return;
        window.__nctAdBlock = true;

        var AD_KEYS = ['adPlacements', 'playerAds', 'adSlots', 'adBreakHeartbeatParams'];

        function prunePlayer(p) {
            if (!p || typeof p !== 'object') return;
            for (var i = 0; i < AD_KEYS.length; i++) {
                if (AD_KEYS[i] in p) delete p[AD_KEYS[i]];
            }
        }

        function isAdEntry(e) {
            var a = e && e.command && e.command.reelWatchEndpoint &&
                e.command.reelWatchEndpoint.adClientParams;
            return !!(a && a.isAd);
        }

        function prune(o) {
            if (!o || typeof o !== 'object') return o;
            try {
                if (Array.isArray(o)) {
                    for (var i = 0; i < o.length; i++) {
                        if (o[i] && typeof o[i] === 'object') {
                            prunePlayer(o[i]);
                            prunePlayer(o[i].playerResponse);
                        }
                    }
                    return o;
                }
                prunePlayer(o);
                prunePlayer(o.playerResponse);
                // 쇼츠 피드에 섞여 오는 광고 항목
                if (Array.isArray(o.entries)) {
                    o.entries = o.entries.filter(function (e) { return !isAdEntry(e); });
                }
            } catch (e) {}
            return o;
        }

        var nativeParse = JSON.parse;
        JSON.parse = function () {
            return prune(nativeParse.apply(this, arguments));
        };

        var nativeJson = Response.prototype.json;
        Response.prototype.json = function () {
            return nativeJson.apply(this, arguments).then(prune);
        };

        // 첫 페이지 로드 때는 응답이 페이지 안의 전역 변수로 들어온다.
        var initial;
        try {
            Object.defineProperty(window, 'ytInitialPlayerResponse', {
                configurable: true,
                enumerable: true,
                get: function () { return initial; },
                set: function (v) { initial = prune(v); }
            });
        } catch (e) {}

        function skipAds() {
            var player = document.querySelector(
                '.html5-video-player.ad-showing, .html5-video-player.ad-interrupting');
            if (!player) return;
            var v = player.querySelector('video');
            if (v && isFinite(v.duration) && v.duration > 0 && v.currentTime < v.duration - 0.1) {
                v.currentTime = v.duration;
            }
            var b = player.querySelector(
                '.ytp-skip-ad-button, .ytp-ad-skip-button, .ytp-ad-skip-button-modern, ' +
                '.ytp-ad-skip-button-container button');
            if (b) b.click();
        }
        setInterval(skipAds, 250);
    })();
    """#

    // 광고 서버로 가는 요청 자체를 막는다. WebKit 콘텐츠 차단 규칙 형식.
    static let ruleListID = "nct-ads-v1"
    static let ruleListJSON = #"""
    [
      {"trigger": {"url-filter": "^https?://([^/]+\\.)?doubleclick\\.net/"}, "action": {"type": "block"}},
      {"trigger": {"url-filter": "^https?://([^/]+\\.)?googlesyndication\\.com/"}, "action": {"type": "block"}},
      {"trigger": {"url-filter": "^https?://([^/]+\\.)?googleadservices\\.com/"}, "action": {"type": "block"}},
      {"trigger": {"url-filter": "^https?://[^/]*google\\.com/pagead/"}, "action": {"type": "block"}},
      {"trigger": {"url-filter": "^https?://[^/]*youtube\\.com/pagead/"}, "action": {"type": "block"}},
      {"trigger": {"url-filter": "^https?://[^/]*youtube\\.com/api/stats/ads"}, "action": {"type": "block"}}
    ]
    """#

    static var userScripts: [WKUserScript] {
        [
            WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true),
            Injection.styleScript(id: "nct-hide-ads", css: css),
        ]
    }
}

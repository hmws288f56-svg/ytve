import WebKit

enum Posts {
    // 홈·구독 피드에 끼어드는 채널 게시물(글·사진·투표). 채널의 게시물 탭은
    // 직접 찾아 들어가는 곳이라 그대로 둔다.
    // The post element was identified on a channel's Posts tab on 2026-10-10;
    // the feed wrappers are the two kinds of row the home feed is made of.
    static let css = """
    ytm-rich-item-renderer:has(ytm-backstage-post-thread-renderer),
    ytm-rich-item-renderer:has(ytm-backstage-post-renderer),
    ytm-rich-section-renderer:has(ytm-backstage-post-thread-renderer),
    ytm-rich-section-renderer:has(ytm-backstage-post-renderer),
    .rich-grid-renderer-contents ytm-backstage-post-thread-renderer,
    .rich-grid-renderer-contents ytm-backstage-post-renderer,
    /* 데스크톱 레이아웃(iPad) */
    ytd-rich-item-renderer:has(ytd-post-renderer),
    ytd-rich-section-renderer:has(ytd-post-renderer) {
        display: none !important;
    }
    """

    static var userScript: WKUserScript {
        Injection.styleScript(id: "nct-hide-posts", css: css)
    }
}

import WebKit

enum HideComments {
    // Selectors checked against m.youtube.com on 2026-10-10. If YouTube renames
    // its elements and comments reappear, this list is the only thing to update.
    static let css = """
    /* 일반 영상: 댓글 미리보기(탭하면 댓글 패널이 열리는 영역) */
    yt-video-metadata-carousel-view-model:has(comments-entry-point-teaser-view-model),
    yt-video-metadata-carousel-view-model:has(yt-comment-teaser-carousel-item-view-model),
    comments-entry-point-teaser-view-model,
    ytm-comments-entry-point-header-renderer,
    ytm-item-section-renderer[section-identifier="comments-entry-point"],
    ytm-item-section-renderer[section-identifier="comment-item-section"],
    /* 일반 영상: 댓글 목록 자체 */
    ytm-comment-section-renderer,
    ytm-comments-header-renderer,
    ytm-comment-simplebox-renderer,
    ytm-comment-thread-renderer,
    ytm-comment-renderer,
    /* 쇼츠: 댓글 버튼 */
    reel-action-bar-view-model button-view-model:has(button[aria-label*="댓글"]),
    reel-action-bar-view-model button-view-model:has(button[aria-label*="omment"]),
    ytm-reel-player-overlay-renderer button[aria-label*="댓글"],
    ytm-reel-player-overlay-renderer button[aria-label*="omment"],
    /* 데스크톱 레이아웃(iPad) */
    ytd-comments,
    ytd-comments-entry-point-header-renderer {
        display: none !important;
    }
    """

    static var userScript: WKUserScript {
        Injection.styleScript(id: "nct-hide-comments", css: css)
    }
}

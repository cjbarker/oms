import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String?
    let searchQuery: String?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        return WKWebView(frame: .zero, configuration: config)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let id = videoId, !id.isEmpty {
            let html = """
            <html><body style="margin:0;padding:0;background:black;">
            <iframe width="100%" height="100%" src="https://www.youtube.com/embed/\(id)?playsinline=1"
            frameborder="0" allowfullscreen></iframe></body></html>
            """
            webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        } else if let q = searchQuery,
                  let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://www.youtube.com/results?search_query=\(encoded)") {
            webView.load(URLRequest(url: url))
        }
    }
}

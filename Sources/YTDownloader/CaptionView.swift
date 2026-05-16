import SwiftUI
import WebKit

/// Embeds caption-app's local web UI inside a WKWebView.
struct CaptionView: View {
    @ObservedObject var service: CaptionAppService
    @State private var reloadToken: Int = 0

    var body: some View {
        ZStack {
            Color(white: 0.06).ignoresSafeArea()
            switch service.status {
            case .stopped:
                VStack(spacing: 14) {
                    Image(systemName: "captions.bubble").font(.system(size: 36)).foregroundColor(.secondary)
                    Text("Caption app is not running").font(.system(size: 14, weight: .medium))
                    Button("Start caption-app") { service.start() }
                        .buttonStyle(.borderedProminent)
                }
            case .starting:
                VStack(spacing: 14) {
                    ProgressView().controlSize(.large)
                    Text("Starting caption-app…")
                        .font(.system(size: 13)).foregroundColor(.secondary)
                }
            case .running:
                CaptionWebView(url: CaptionAppService.url, reloadToken: reloadToken)
                    .overlay(alignment: .topTrailing) {
                        Button { reloadToken += 1 } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .background(.thinMaterial, in: Circle())
                        .padding(8)
                        .help("Reload")
                    }
            case .failed(let msg):
                VStack(spacing: 14) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36)).foregroundColor(.orange)
                    Text("Couldn't start caption-app")
                        .font(.system(size: 14, weight: .medium))
                    Text(msg).font(.system(size: 12)).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
                    Button("Try again") {
                        service.status = .stopped
                        service.start()
                    }.buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

/// SwiftUI wrapper for WKWebView that reloads when `reloadToken` changes.
struct CaptionWebView: NSViewRepresentable {
    let url: URL
    let reloadToken: Int

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let view = WKWebView(frame: .zero, configuration: config)
        view.load(URLRequest(url: url))
        return view
    }

    func updateNSView(_ webview: WKWebView, context: Context) {
        // Reload when token changes (re-mount-style refresh).
        if context.coordinator.lastToken != reloadToken {
            context.coordinator.lastToken = reloadToken
            webview.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(reloadToken: reloadToken) }

    final class Coordinator {
        var lastToken: Int
        init(reloadToken: Int) { self.lastToken = reloadToken }
    }
}

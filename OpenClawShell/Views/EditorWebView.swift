import SwiftUI
import WebKit

struct EditorWebView: UIViewRepresentable {
    let file: WorkspaceFile

    @EnvironmentObject private var appState: AppState

    func makeCoordinator() -> Coordinator {
        Coordinator(appState: appState, file: file)
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "editorBridge")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        if let url = Bundle.main.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.file = file
        let text = appState.workspaceStore.readText(for: file)
        let encoded = Self.jsEscaped(text)
        webView.evaluateJavaScript("window.setEditorText(\"\(encoded)\")")
    }

    static func jsEscaped(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let appState: AppState
        var file: WorkspaceFile

        init(appState: AppState, file: WorkspaceFile) {
            self.appState = appState
            self.file = file
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "editorBridge",
                  let payload = message.body as? [String: Any],
                  let event = payload["event"] as? String,
                  event == "save",
                  let text = payload["text"] as? String else {
                return
            }

            Task { @MainActor in
                appState.workspaceStore.saveText(text, for: file)
            }
        }
    }
}

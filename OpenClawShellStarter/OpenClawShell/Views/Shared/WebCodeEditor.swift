import SwiftUI
import WebKit

struct WebCodeEditor: View {
    @EnvironmentObject private var appState: AppState
    let file: WorkspaceFile

    var body: some View {
        WebCodeEditorRepresentable(initialText: appState.workspaceStore.loadText(for: file)) { updatedText in
            appState.workspaceStore.saveText(updatedText, to: file)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct WebCodeEditorRepresentable: UIViewRepresentable {
    let initialText: String
    let onSave: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSave: onSave)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "editorBridge")
        config.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false

        if let htmlURL = Bundle.main.url(forResource: "editor", withExtension: "html", subdirectory: "Assets") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }
        context.coordinator.initialText = initialText
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onSave = onSave
        context.coordinator.initialText = initialText
        let escaped = initialText
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\"", with: "\\\"")
        webView.evaluateJavaScript("window.setEditorText(\"\(escaped)\")")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var initialText: String = ""
        var onSave: (String) -> Void
        weak var webView: WKWebView?

        init(onSave: @escaping (String) -> Void) {
            self.onSave = onSave
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let escaped = initialText
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "")
                .replacingOccurrences(of: "\"", with: "\\\"")
            webView.evaluateJavaScript("window.setEditorText(\"\(escaped)\")")
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "editorBridge" else { return }
            if let body = message.body as? [String: Any],
               let event = body["event"] as? String,
               event == "save",
               let text = body["text"] as? String {
                onSave(text)
            }
        }
    }
}

import SwiftUI
import Markdown
import Combine

/// A view to render markdown text.
///
/// - note: If you want to change font size, you shoud use ``environment(_:_:)`` to modify the `dynamicTypeSize` instead of using ``font(_:)`` to maintain a natural layout.
public struct MarkdownView: View {
    @Binding private var text: String

    @Environment(\.lineSpacing) private var lineSpacing
    @StateObject var imageCacheController = ImageCacheController()
    var codeBlockTheme = CodeBlockTheme(
        lightModeThemeName: "xcode", darkModeThemeName: "dark"
    )
    
    // Update content 0.3s after the user stops entering.
    @StateObject var contentUpdater = ContentUpdater()
    @State private var representedView = AnyView(Color.black.opacity(0.001)) // RenderedView
    @State private var renderComplete = false
    
    var role: MarkdownViewRole = .normal
    var tintColor = Color.accentColor
    
    /// Parse the Markdown and render it as a single `View`.
    /// - Parameters:
    ///   - text: A Binding Text that can be modified.
    ///   - baseURL: A path where the images will load from.
    public init(text: Binding<String>, baseURL: URL? = nil) {
        _text = text
        if let baseURL {
            ImageRenderer.shared.baseURL = baseURL
        }
    }
    
    /// Parse the Markdown and render it as a single view.
    /// - Parameters:
    ///   - text: Markdown Text.
    ///   - baseURL: A path where the images will load from.
    public init(text: String, baseURL: URL? = nil) {
        _text = .constant(text)
        if let baseURL {
            ImageRenderer.shared.baseURL = baseURL
        }
    }
    
    public var body: some View {
        ZStack {
            switch configuration.role {
            case .normal: representedView
            case .editor:
                representedView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .readViewSize()
        // Push current text, waiting for next update.
        .onChange(of: text, perform: contentUpdater.push(_:))
        // Load view immediately after the first launch.
        // Receive configuration changes and reload MarkdownView to fit.
        .task(id: configuration) { makeView(text: text) }
        // Received a debouncedText, we need to reload MarkdownView.
        .onReceive(contentUpdater.textUpdater, perform: makeView(text:))
    }
    
    private func makeView(text: String) {
        Task.detached {
            let config = await self.configuration
            var renderer = Renderer(
                text: text,
                configuration: config,
                interactiveEditHandler: { text in
                    Task { @MainActor in
                        self.text = text
                        self.makeView(text: text)
                    }
                }
            )
            let parseBD = !BlockDirectiveRenderer.shared.blockDirectiveHandlers.isEmpty
            let view = renderer.representedView(parseBlockDirectives: parseBD)
            Task { @MainActor in
                representedView = view
            }
        }
    }
}

extension MarkdownView {
    var configuration: RendererConfiguration {
        RendererConfiguration(
            role: role,
            lineSpacing: lineSpacing,
            tintColor: tintColor,
            codeBlockTheme: codeBlockTheme,
            imageCacheController: imageCacheController
        )
    }
}

/// Update content 0.3s after the user stops entering.
class ContentUpdater: ObservableObject {
    /// Send all the changes from raw text
    private var relay = PassthroughSubject<String, Never>()
    
    /// A publisher to notify MarkdownView to update its content.
    var textUpdater: AnyPublisher<String, Never>
    
    init() {
        textUpdater = relay
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func push(_ text: String) {
        relay.send(text)
    }
}

struct RendererConfiguration: Equatable {
    var role: MarkdownView.MarkdownViewRole
    
    /// Sets the amount of space between lines in a paragraph in this view.
    ///
    /// Use SwiftUI's built-in `lineSpacing(_:)` to set the amount of spacing
    /// from the bottom of one line to the top of the next for text elements in the view.
    ///
    ///     MarkdownView(...)
    ///         .lineSpacing(10)
    var lineSpacing: CGFloat
    var componentSpacing: CGFloat = 8
    var tintColor: Color
    
    /// Sets the theme of the code block.
    /// For more information, please check out [raspu/Highlightr](https://github.com/raspu/Highlightr) .
    var codeBlockTheme: CodeBlockTheme

    var imageCacheController: ImageCacheController
}

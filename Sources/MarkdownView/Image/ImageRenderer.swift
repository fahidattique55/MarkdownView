import SwiftUI

class ImageRenderer {
    /// The base URL for local images or network images.
    var baseURL: URL
    
    /// Create a Configuration for image handling.
    init(baseURL: URL? = nil) {
        guard baseURL == nil else {
            self.baseURL = baseURL!
            return
        }
        
        let baseURL: URL
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            baseURL = .documentsDirectory
        } else {
            baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
        self.baseURL = baseURL
    }
    
    /// All the providers that have been added.
    var imageProviders: [String: any ImageDisplayable] = [
        "http": NetworkImageDisplayable(),
        "https": NetworkImageDisplayable(),
    ]
    
    /// Add custom provider for images rendering.
    /// - Parameters:
    ///   - provider: An image provider to make image using a url and an alternative text.
    ///   - urlScheme: The url scheme to use the provider.
    func addProvider(
        _ provider: some ImageDisplayable, forURLScheme urlScheme: String
    ) {
        self.imageProviders[urlScheme] = provider
    }
    
    func loadImage(
        _ provider: (any ImageDisplayable)?, url: URL, alt: String?
    ) -> AnyView {
        if let provider {
            // Found a specific provider.
            return AnyView(provider.makeImage(url: url, alt: alt))
        } else {
            // No specific provider.
            // Try to load the image from the Base URL.
            return AnyView(RelativePathImageDisplayable(baseURL: baseURL).makeImage(url: url, alt: alt))
        }
    }
}

extension ImageRenderer {
    static var shared: ImageRenderer = ImageRenderer()
}

// MARK: - Display Images

extension MarkdownView {
    /// Adds your own providers to render images.
    ///
    /// - parameters
    ///     - provider: The provider you created to handle image loading and displaying.
    ///     - urlScheme: A scheme for the renderer to determine when to use the provider.
    /// - Returns: A `MarkdownView` that can render the image with a specific scheme.
    ///
    /// You can set the provider multiple times if you want to add multiple schemes.
    public func imageProvider(
        _ provider: some ImageDisplayable, forURLScheme urlScheme: String
    ) -> MarkdownView {
        ImageRenderer.shared.addProvider(provider, forURLScheme: urlScheme)
        return self
    }
}

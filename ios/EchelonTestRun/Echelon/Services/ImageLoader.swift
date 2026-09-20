import UIKit
import SwiftUI

public final class ImageLoader {
    public static let shared = ImageLoader()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50 MB
            diskCapacity: 150 * 1024 * 1024,  // 150 MB
            diskPath: "echelon_image_cache"
        )
        self.session = URLSession(configuration: config)
        self.memoryCache.countLimit = 200
    }
    
    public func loadImage(from urlString: String?, completion: @escaping (UIImage?) -> Void) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let cacheKey = NSString(string: urlString)
        if let cached = memoryCache.object(forKey: cacheKey) {
            completion(cached)
            return
        }
        
        // Support local file URLs for profile avatars and cached images
        if url.isFileURL {
            if let image = UIImage(contentsOfFile: url.path) {
                self.memoryCache.setObject(image, forKey: cacheKey)
                DispatchQueue.main.async {
                    completion(image)
                }
                return
            }
        }
        
        let request = URLRequest(url: url)
        if let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            self.memoryCache.setObject(image, forKey: cacheKey)
            completion(image)
            return
        }
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if let response = response {
                let cachedData = CachedURLResponse(response: response, data: data)
                self.session.configuration.urlCache?.storeCachedResponse(cachedData, for: request)
            }
            self.memoryCache.setObject(image, forKey: cacheKey)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}

// MARK: - SwiftUI RemoteImageView

public struct RemoteImageView: View {
    public let urlString: String?
    public let fallbackSystemName: String
    public let contentMode: ContentMode
    
    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = false
    
    public init(
        urlString: String?,
        fallbackSystemName: String = "building.2.crop.circle",
        contentMode: ContentMode = .fill
    ) {
        self.urlString = urlString
        self.fallbackSystemName = fallbackSystemName
        self.contentMode = contentMode
    }
    
    public var body: some View {
        ZStack {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: .infinity)
            } else if isLoading {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "#1A2333"), Color(hex: "#0F1622")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.8)))
                }
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "#161E2E"), Color(hex: "#0E131E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: fallbackSystemName)
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(Color.white.opacity(0.35))
                }
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: urlString) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let urlString = urlString, !urlString.isEmpty else {
            self.image = nil
            self.isLoading = false
            return
        }
        
        self.isLoading = true
        ImageLoader.shared.loadImage(from: urlString) { loadedImage in
            self.image = loadedImage
            self.isLoading = false
        }
    }
}

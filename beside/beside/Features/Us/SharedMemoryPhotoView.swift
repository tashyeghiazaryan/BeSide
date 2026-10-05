import SwiftUI
import UIKit

/// In-memory cache so feed / gallery / carousel share loaded remote photos.
enum SharedMemoryImageCache {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(for urlString: String) -> UIImage? {
        cache.object(forKey: urlString as NSString)
    }

    static func store(_ image: UIImage, for urlString: String) {
        cache.setObject(image, forKey: urlString as NSString)
    }
}

/// Photo area for Shared Memory cards — prefers `photoData`, then data URI, then remote URL (cached).
struct SharedMemoryPhotoView: View {
    let memory: UsSharedMemory
    var contentMode: ContentMode = .fill

    @State private var remoteImage: UIImage?
    @State private var remoteFailed = false

    var body: some View {
        ZStack {
            moodPlaceholder

            if let local = UsSharedMemories.localImage(for: memory) {
                Image(uiImage: local)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            } else if let remoteImage {
                Image(uiImage: remoteImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            } else if UsSharedMemories.isRemotePhotoURL(memory.photoURL), !remoteFailed {
                ProgressView()
                    .tint(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .task(id: memory.photoURL) {
            await loadRemoteIfNeeded()
        }
    }

    private var moodPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.55),
                    Color(hex: 0xC4B5FD).opacity(0.14),
                    Color(hex: 0xF8FAFC).opacity(0.7),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(memory.mood)
                .font(.system(size: 28))
                .opacity(0.9)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    private func loadRemoteIfNeeded() async {
        guard UsSharedMemories.localImage(for: memory) == nil else { return }
        let urlString = memory.photoURL
        guard UsSharedMemories.isRemotePhotoURL(urlString),
              let url = URL(string: urlString)
        else { return }

        if let cached = SharedMemoryImageCache.image(for: urlString) {
            remoteImage = cached
            remoteFailed = false
            return
        }

        remoteFailed = false
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                remoteFailed = true
                return
            }
            guard let image = UIImage(data: data) else {
                remoteFailed = true
                return
            }
            SharedMemoryImageCache.store(image, for: urlString)
            remoteImage = image
        } catch {
            remoteFailed = true
        }
    }
}

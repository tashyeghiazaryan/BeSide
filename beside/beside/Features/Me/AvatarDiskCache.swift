import Foundation

/// Local JPEG persistence for the signed-in user's avatar (demo + offline).
enum AvatarDiskCache {
    private static let fileName = "me-avatar.jpg"

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("BeSide", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }

    static func load() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    static func save(_ data: Data?) {
        let url = fileURL
        if let data {
            try? data.write(to: url, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

import CoreTransferable
import Foundation
import UIKit
import UniformTypeIdentifiers

/// Shared memory entry — Figma Make `SharedMemory`.
struct UsSharedMemory: Identifiable, Equatable, Sendable {
    let id: String
    var title: String
    var dateTime: Date
    var description: String
    var mood: String
    /// Remote URL or `data:image/...;base64,...` — optional when `photoData` is set.
    var photoURL: String
    /// Preferred in-session photo bytes (JPEG) from PhotosPicker.
    var photoData: Data?
    var likes: Int
    var likedByMe: Bool
    /// True when created via Add — shown in the gallery page.
    var addedByUser: Bool
}

/// PhotosPicker → JPEG Data (HEIC/PNG/JPEG).
struct SharedMemoryPickedPhoto: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let image = UIImage(data: data),
                  let jpeg = image.jpegData(compressionQuality: 0.82)
            else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return SharedMemoryPickedPhoto(data: jpeg)
        }
    }
}

enum UsSharedMemories {
    static let moodOptions = ["💛", "😊", "🥰", "✨", "🌙", "🔥", "💙"]

    static func demoSeed() -> [UsSharedMemory] {
        let now = Date()
        let calendar = Calendar.current
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now).map {
            calendar.date(bySettingHour: 19, minute: 30, second: 0, of: $0) ?? $0
        } ?? now
        let coffeeDay = calendar.date(byAdding: .day, value: -3, to: now).map {
            calendar.date(bySettingHour: 9, minute: 15, second: 0, of: $0) ?? $0
        } ?? now

        return [
            UsSharedMemory(
                id: "memory-1",
                title: "Evening on the rooftop",
                dateTime: now,
                description: "You two enjoyed the sunset together",
                mood: "💛",
                photoURL: "https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=800&h=800&q=80",
                photoData: nil,
                likes: 1,
                likedByMe: false,
                addedByUser: true
            ),
            UsSharedMemory(
                id: "memory-user-demo-1",
                title: "Morning coffee walk",
                dateTime: coffeeDay,
                description: "Quiet streets and shared silence",
                mood: "☕",
                photoURL: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&h=800&q=80",
                photoData: nil,
                likes: 2,
                likedByMe: true,
                addedByUser: true
            ),
            UsSharedMemory(
                id: "memory-user-demo-2",
                title: "Rainy cinema night",
                dateTime: lastMonth,
                description: "Held hands through the credits",
                mood: "🎬",
                // Reliable cinema still — previous Unsplash id often 404'd in feed.
                photoURL: "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=800&h=800&q=80",
                photoData: nil,
                likes: 0,
                likedByMe: false,
                addedByUser: true
            ),
        ]
    }

    static func shortDateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    static func monthKey(_ date: Date) -> String {
        let calendar = Calendar.current
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }

    static func monthLabel(_ key: String) -> String {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return key }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = 1
        guard let date = Calendar.current.date(from: comps) else { return key }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    static func shareText(for memory: UsSharedMemory) -> String {
        [
            "\(memory.mood) \(memory.title)",
            shortDateLabel(memory.dateTime),
            memory.description,
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
    }

    /// Local image from in-memory bytes or data/file URL (not remote http).
    static func localImage(for memory: UsSharedMemory) -> UIImage? {
        if let photoData = memory.photoData, let image = UIImage(data: photoData) {
            return image
        }
        return image(from: memory.photoURL)
    }

    static func hasPhoto(_ memory: UsSharedMemory) -> Bool {
        if memory.photoData != nil { return true }
        return !memory.photoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func isRemotePhotoURL(_ urlString: String) -> Bool {
        urlString.hasPrefix("http://") || urlString.hasPrefix("https://")
    }

    static func image(from urlString: String) -> UIImage? {
        guard !urlString.isEmpty else { return nil }
        if urlString.hasPrefix("data:"),
           let comma = urlString.firstIndex(of: ","),
           let data = Data(base64Encoded: String(urlString[urlString.index(after: comma)...])) {
            return UIImage(data: data)
        }
        if urlString.hasPrefix("file:"), let url = URL(string: urlString),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }

    static func normalizedJPEG(from photoData: Data?) -> Data? {
        guard let photoData, !photoData.isEmpty else { return nil }
        if let image = UIImage(data: photoData) {
            return image.jpegData(compressionQuality: 0.82) ?? photoData
        }
        return photoData
    }
}

import SwiftUI
import UIKit

enum InstagramStoriesShare {
    private static let storiesURL = URL(string: "instagram-stories://share")!

    static var isAvailable: Bool {
        UIApplication.shared.canOpenURL(storiesURL)
    }

    /// Renders the couple sticker and opens Instagram Stories when possible.
    /// Falls back to the system share sheet if Instagram isn’t installed.
    @MainActor
    static func shareCoupleStory(
        meName: String,
        partnerName: String,
        style: UsTimeTogether.Style,
        relationshipStart: Date
    ) {
        let card = CoupleStoryShareCard(
            meName: meName,
            partnerName: partnerName,
            style: style,
            relationshipStart: relationshipStart
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        guard let image = renderer.uiImage, let png = image.pngData() else { return }

        if isAvailable {
            openStories(stickerPNG: png)
        } else {
            presentSystemShare(items: [image])
        }
    }

    private static func openStories(stickerPNG: Data) {
        var payload: [String: Any] = [
            "com.instagram.sharedSticker.stickerImage": stickerPNG,
            "com.instagram.sharedSticker.backgroundTopColor": "#F3F1F0",
            "com.instagram.sharedSticker.backgroundBottomColor": "#E8DDE8",
        ]
        if let appID = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String,
           !appID.isEmpty {
            payload["com.instagram.sharedSticker.appID"] = appID
        }

        UIPasteboard.general.setItems(
            [payload],
            options: [.expirationDate: Date().addingTimeInterval(60 * 5)]
        )
        UIApplication.shared.open(storiesURL)
    }

    private static func presentSystemShare(items: [Any]) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }

        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = top.view
            pop.sourceRect = CGRect(
                x: top.view.bounds.midX,
                y: top.view.bounds.midY,
                width: 1,
                height: 1
            )
            pop.permittedArrowDirections = []
        }
        top.present(sheet, animated: true)
    }
}

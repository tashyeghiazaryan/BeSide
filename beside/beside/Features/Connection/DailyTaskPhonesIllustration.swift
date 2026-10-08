import SwiftUI

/// Soft pink line art: two phones linked by a single quiet connection.
struct DailyTaskPhonesIllustration: View {
    private let pink = Color(hex: 0xF9A8D4)
    private let heartPink = Color(hex: 0xFB7185)

    var body: some View {
        Canvas { context, size in
            let designW: CGFloat = 220
            let designH: CGFloat = 120
            let scale = min(size.width / designW, size.height / designH)
            let ox = (size.width - designW * scale) / 2
            let oy = (size.height - designH * scale) / 2

            context.translateBy(x: ox, y: oy)
            context.scaleBy(x: scale, y: scale)

            let lw = 2.15 / max(scale, 0.01)
            let style = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
            let linkStyle = StrokeStyle(
                lineWidth: lw * 0.85,
                lineCap: .round,
                dash: [4 / scale, 5 / scale]
            )
            let ink = pink.opacity(0.95)

            drawPhone(
                context: &context,
                pivot: CGPoint(x: 58, y: 62),
                angle: -0.1,
                origin: CGPoint(x: 28, y: 18),
                ink: ink,
                heart: heartPink,
                style: style
            )

            drawPhone(
                context: &context,
                pivot: CGPoint(x: 162, y: 62),
                angle: 0.1,
                origin: CGPoint(x: 146, y: 18),
                ink: ink,
                heart: heartPink,
                style: style
            )

            // One connection idea only — dashed curve, no spark.
            var link = Path()
            link.move(to: CGPoint(x: 86, y: 60))
            link.addQuadCurve(to: CGPoint(x: 134, y: 60), control: CGPoint(x: 110, y: 46))
            context.stroke(link, with: .color(ink.opacity(0.7)), style: linkStyle)
        }
        .accessibilityHidden(true)
    }

    private func drawPhone(
        context: inout GraphicsContext,
        pivot: CGPoint,
        angle: CGFloat,
        origin: CGPoint,
        ink: Color,
        heart: Color,
        style: StrokeStyle
    ) {
        context.concatenate(
            CGAffineTransform(translationX: pivot.x, y: pivot.y)
                .rotated(by: angle)
                .translatedBy(x: -pivot.x, y: -pivot.y)
        )

        let width: CGFloat = 48
        let height: CGFloat = 86
        context.stroke(Self.phoneFrame(origin: origin, width: width, height: height), with: .color(ink), style: style)

        let heartCenter = CGPoint(x: origin.x + width / 2, y: origin.y + height * 0.48)
        context.stroke(
            Self.heart(center: heartCenter, size: 20),
            with: .color(heart),
            style: StrokeStyle(lineWidth: style.lineWidth * 1.05, lineCap: .round, lineJoin: .round)
        )

        context.concatenate(
            CGAffineTransform(translationX: pivot.x, y: pivot.y)
                .rotated(by: -angle)
                .translatedBy(x: -pivot.x, y: -pivot.y)
        )
    }

    private static func phoneFrame(origin: CGPoint, width: CGFloat, height: CGFloat) -> Path {
        var p = Path()
        p.addRoundedRect(
            in: CGRect(x: origin.x, y: origin.y, width: width, height: height),
            cornerSize: CGSize(width: 9, height: 9)
        )
        p.addRoundedRect(
            in: CGRect(x: origin.x + 5.5, y: origin.y + 13, width: width - 11, height: height - 30),
            cornerSize: CGSize(width: 4, height: 4)
        )
        let earW: CGFloat = 13
        p.move(to: CGPoint(x: origin.x + (width - earW) / 2, y: origin.y + 6.5))
        p.addLine(to: CGPoint(x: origin.x + (width + earW) / 2, y: origin.y + 6.5))
        let barW: CGFloat = 15
        p.move(to: CGPoint(x: origin.x + (width - barW) / 2, y: origin.y + height - 8.5))
        p.addLine(to: CGPoint(x: origin.x + (width + barW) / 2, y: origin.y + height - 8.5))
        return p
    }

    private static func heart(center: CGPoint, size: CGFloat) -> Path {
        let s = size / 16
        var p = Path()
        p.move(to: CGPoint(x: center.x, y: center.y + 6.5 * s))
        p.addCurve(
            to: CGPoint(x: center.x - 8 * s, y: center.y - 1.5 * s),
            control1: CGPoint(x: center.x - 1.5 * s, y: center.y + 3.5 * s),
            control2: CGPoint(x: center.x - 8 * s, y: center.y + 3 * s)
        )
        p.addCurve(
            to: CGPoint(x: center.x, y: center.y - 5.5 * s),
            control1: CGPoint(x: center.x - 8 * s, y: center.y - 7 * s),
            control2: CGPoint(x: center.x - 3.5 * s, y: center.y - 7 * s)
        )
        p.addCurve(
            to: CGPoint(x: center.x + 8 * s, y: center.y - 1.5 * s),
            control1: CGPoint(x: center.x + 3.5 * s, y: center.y - 7 * s),
            control2: CGPoint(x: center.x + 8 * s, y: center.y - 7 * s)
        )
        p.addCurve(
            to: CGPoint(x: center.x, y: center.y + 6.5 * s),
            control1: CGPoint(x: center.x + 8 * s, y: center.y + 3 * s),
            control2: CGPoint(x: center.x + 1.5 * s, y: center.y + 3.5 * s)
        )
        p.closeSubpath()
        return p
    }
}

#Preview {
    ZStack {
        BeSideColor.navyFill.ignoresSafeArea()
        DailyTaskPhonesIllustration()
            .frame(height: 140)
            .padding(24)
    }
}

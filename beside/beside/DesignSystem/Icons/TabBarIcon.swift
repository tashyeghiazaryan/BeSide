import SwiftUI
import UIKit

/// Lucide stroke icons for the floating tab bar (Figma Make: UserRound / Users / Heart / Sparkle / MoreHorizontal).
enum TabBarIconKind: Sendable {
    case userRound
    case users
    case heart
    case sparkle
    case more
}

struct TabBarIcon: View {
    let kind: TabBarIconKind
    var size: CGFloat = 21
    var lineWidth: CGFloat = 1.5

    var body: some View {
        Group {
            if kind == .more {
                TabBarIconShape(kind: kind)
                    .fill(style: FillStyle(eoFill: false))
            } else {
                TabBarIconShape(kind: kind)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct TabBarIconShape: Shape {
    let kind: TabBarIconKind

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        let dx = rect.minX + (rect.width - 24 * scale) / 2
        let dy = rect.minY + (rect.height - 24 * scale) / 2
        var transform = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale)

        let combined = CGMutablePath()
        for cg in tabBarCGPaths(kind) {
            if let copy = cg.copy(using: &transform) {
                combined.addPath(copy)
            }
        }
        return Path(combined)
    }
}

private func tabBarCGPaths(_ kind: TabBarIconKind) -> [CGPath] {
    switch kind {
    case .userRound:
        return [
            svgPath("M18 20a6 6 0 0 0-12 0"),
            UIBezierPath(ovalIn: CGRect(x: 8, y: 6, width: 8, height: 8)).cgPath,
        ]
    case .users:
        return [
            svgPath("M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"),
            UIBezierPath(ovalIn: CGRect(x: 5, y: 3, width: 8, height: 8)).cgPath,
            svgPath("M22 21v-2a4 4 0 0 0-3-3.87"),
            svgPath("M16 3.13a4 4 0 0 1 0 7.75"),
        ]
    case .heart:
        return [
            svgPath("M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"),
        ]
    case .sparkle:
        return [
            svgPath("M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z"),
        ]
    case .more:
        return [
            UIBezierPath(ovalIn: CGRect(x: 4, y: 11, width: 2, height: 2)).cgPath,
            UIBezierPath(ovalIn: CGRect(x: 11, y: 11, width: 2, height: 2)).cgPath,
            UIBezierPath(ovalIn: CGRect(x: 18, y: 11, width: 2, height: 2)).cgPath,
        ]
    }
}

// MARK: - Minimal SVG path subset (Lucide)

private func svgPath(_ d: String) -> CGPath {
    let path = CGMutablePath()
    let tokens = tokenize(d)
    var i = 0
    var current = CGPoint.zero
    var start = CGPoint.zero
    var lastCmd: Character = "M"

    func num() -> CGFloat {
        let v = CGFloat(Double(tokens[i]) ?? 0)
        i += 1
        return v
    }

    while i < tokens.count {
        let token = tokens[i]
        let cmd: Character
        if token.count == 1, let c = token.first, c.isLetter {
            cmd = c
            i += 1
            lastCmd = cmd
        } else {
            switch lastCmd {
            case "M": cmd = "L"
            case "m": cmd = "l"
            default: cmd = lastCmd
            }
        }

        switch cmd {
        case "M":
            current = CGPoint(x: num(), y: num()); start = current; path.move(to: current); lastCmd = "L"
        case "m":
            current = CGPoint(x: current.x + num(), y: current.y + num()); start = current; path.move(to: current); lastCmd = "l"
        case "L":
            current = CGPoint(x: num(), y: num()); path.addLine(to: current)
        case "l":
            current = CGPoint(x: current.x + num(), y: current.y + num()); path.addLine(to: current)
        case "H":
            current = CGPoint(x: num(), y: current.y); path.addLine(to: current)
        case "h":
            current = CGPoint(x: current.x + num(), y: current.y); path.addLine(to: current)
        case "V":
            current = CGPoint(x: current.x, y: num()); path.addLine(to: current)
        case "v":
            current = CGPoint(x: current.x, y: current.y + num()); path.addLine(to: current)
        case "C":
            let c1 = CGPoint(x: num(), y: num())
            let c2 = CGPoint(x: num(), y: num())
            current = CGPoint(x: num(), y: num())
            path.addCurve(to: current, control1: c1, control2: c2)
        case "c":
            let c1 = CGPoint(x: current.x + num(), y: current.y + num())
            let c2 = CGPoint(x: current.x + num(), y: current.y + num())
            current = CGPoint(x: current.x + num(), y: current.y + num())
            path.addCurve(to: current, control1: c1, control2: c2)
        case "A", "a":
            let rx = num(), ry = num(), rot = num()
            let large = num() != 0, sweep = num() != 0
            let end = cmd == "A"
                ? CGPoint(x: num(), y: num())
                : CGPoint(x: current.x + num(), y: current.y + num())
            addArc(path, from: current, to: end, rx: rx, ry: ry, rotationDeg: rot, large: large, sweep: sweep)
            current = end
        case "Z", "z":
            path.closeSubpath(); current = start
        default:
            i += 1
        }
    }
    return path
}

private func tokenize(_ d: String) -> [String] {
    var tokens: [String] = []
    var number = ""
    func flush() {
        if !number.isEmpty { tokens.append(number); number = "" }
    }
    for ch in d {
        if ch.isLetter {
            flush()
            tokens.append(String(ch))
        } else if ch == "," || ch == " " || ch == "\n" || ch == "\t" {
            flush()
        } else if ch == "-" || ch == "+" {
            if !number.isEmpty, number.last != "e", number.last != "E" { flush() }
            number.append(ch)
        } else if ch == "." {
            if number.contains("."), !number.contains("e"), !number.contains("E") { flush() }
            number.append(ch)
        } else if ch.isNumber || ch == "e" || ch == "E" {
            number.append(ch)
        }
    }
    flush()
    return tokens
}

private func addArc(
    _ path: CGMutablePath,
    from: CGPoint,
    to: CGPoint,
    rx inRx: CGFloat,
    ry inRy: CGFloat,
    rotationDeg: CGFloat,
    large: Bool,
    sweep: Bool
) {
    var rx = abs(inRx)
    var ry = abs(inRy)
    if rx == 0 || ry == 0 {
        path.addLine(to: to)
        return
    }

    let φ = rotationDeg * .pi / 180
    let cosφ = cos(φ), sinφ = sin(φ)
    let dx = (from.x - to.x) / 2, dy = (from.y - to.y) / 2
    let x1p = cosφ * dx + sinφ * dy
    let y1p = -sinφ * dx + cosφ * dy

    var rx2 = rx * rx, ry2 = ry * ry
    let x1p2 = x1p * x1p, y1p2 = y1p * y1p
    let λ = x1p2 / rx2 + y1p2 / ry2
    if λ > 1 {
        let s = sqrt(λ)
        rx *= s; ry *= s
        rx2 = rx * rx; ry2 = ry * ry
    }

    var sq = max(0, (rx2 * ry2 - rx2 * y1p2 - ry2 * x1p2) / (rx2 * y1p2 + ry2 * x1p2))
    sq = sqrt(sq)
    if large == sweep { sq = -sq }
    let cxp = sq * (rx * y1p) / ry
    let cyp = sq * -(ry * x1p) / rx
    let cx = cosφ * cxp - sinφ * cyp + (from.x + to.x) / 2
    let cy = sinφ * cxp + cosφ * cyp + (from.y + to.y) / 2

    func angle(_ u: CGPoint, _ v: CGPoint) -> CGFloat {
        let n = sqrt((u.x * u.x + u.y * u.y) * (v.x * v.x + v.y * v.y))
        var a = acos(max(-1, min(1, (u.x * v.x + u.y * v.y) / n)))
        if u.x * v.y - u.y * v.x < 0 { a = -a }
        return a
    }

    let v1 = CGPoint(x: (x1p - cxp) / rx, y: (y1p - cyp) / ry)
    let v2 = CGPoint(x: (-x1p - cxp) / rx, y: (-y1p - cyp) / ry)
    var θ1 = angle(CGPoint(x: 1, y: 0), v1)
    var Δθ = angle(v1, v2)
    if !sweep && Δθ > 0 { Δθ -= 2 * .pi }
    if sweep && Δθ < 0 { Δθ += 2 * .pi }

    let segments = max(1, Int(ceil(abs(Δθ) / (.pi / 2))))
    let δ = Δθ / CGFloat(segments)
    let t = (4 / 3) * tan(δ / 4)
    var startAngle = θ1
    for _ in 0..<segments {
        let endAngle = startAngle + δ
        let cos1 = cos(startAngle), sin1 = sin(startAngle)
        let cos2 = cos(endAngle), sin2 = sin(endAngle)
        let e1 = CGPoint(
            x: cx + cosφ * rx * cos1 - sinφ * ry * sin1,
            y: cy + sinφ * rx * cos1 + cosφ * ry * sin1
        )
        let e2 = CGPoint(
            x: cx + cosφ * rx * cos2 - sinφ * ry * sin2,
            y: cy + sinφ * rx * cos2 + cosφ * ry * sin2
        )
        let cp1 = CGPoint(
            x: e1.x + (-cosφ * rx * sin1 - sinφ * ry * cos1) * t,
            y: e1.y + (-sinφ * rx * sin1 + cosφ * ry * cos1) * t
        )
        let cp2 = CGPoint(
            x: e2.x - (-cosφ * rx * sin2 - sinφ * ry * cos2) * t,
            y: e2.y - (-sinφ * rx * sin2 + cosφ * ry * cos2) * t
        )
        path.addCurve(to: e2, control1: cp1, control2: cp2)
        startAngle = endAngle
    }
}

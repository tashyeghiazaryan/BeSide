import SwiftUI
import UIKit

/// Lucide outline icons matching Figma Make (`lucide-react` Leaf / Sparkles / Heart / Cloud / BatteryLow / Zap).
enum MoodIconKind: String, Sendable {
    case leaf
    case sparkles
    case heart
    case cloud
    case battery
    case zap
}

struct MoodIcon: View {
    let kind: MoodIconKind
    var size: CGFloat = 28

    var body: some View {
        LucideIconShape(kind: kind)
            .stroke(style: StrokeStyle(lineWidth: size * (2.0 / 24.0), lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

private struct LucideIconShape: Shape {
    let kind: MoodIconKind

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        let dx = rect.minX + (rect.width - 24 * scale) / 2
        let dy = rect.minY + (rect.height - 24 * scale) / 2
        var transform = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale)

        let combined = CGMutablePath()
        for cg in lucideCGPaths(kind) {
            if let copy = cg.copy(using: &transform) {
                combined.addPath(copy)
            }
        }
        return Path(combined)
    }
}

private func lucideCGPaths(_ kind: MoodIconKind) -> [CGPath] {
    switch kind {
    case .leaf:
        return [
            svgPath("M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"),
            svgPath("M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"),
        ]
    case .sparkles:
        return [
            svgPath("M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"),
            linePath(20, 3, 20, 7),
            linePath(22, 5, 18, 5),
            linePath(4, 17, 4, 19),
            linePath(5, 18, 3, 18),
        ]
    case .heart:
        return [
            svgPath("M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"),
        ]
    case .cloud:
        return [
            svgPath("M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"),
        ]
    case .battery:
        // Lucide BatteryLow — outline + one bar, as in the Figma Make mockup
        let body = UIBezierPath(roundedRect: CGRect(x: 2, y: 7, width: 16, height: 10), cornerRadius: 2)
        return [body.cgPath, linePath(22, 11, 22, 13), linePath(6, 11, 6, 13)]
    case .zap:
        return [
            svgPath("M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"),
        ]
    }
}

private func linePath(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: x1, y: y1))
    p.addLine(to: CGPoint(x: x2, y: y2))
    return p
}

// MARK: - SVG path subset used by Lucide icons

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

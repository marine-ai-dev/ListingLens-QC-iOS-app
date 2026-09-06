#if DEBUG
import UIKit
#if canImport(ListingLensQCCore)
import ListingLensQCCore
#endif

/// Deterministic synthetic-photo injection for UI tests, so XCUITest can exercise the
/// 10/20-photo and duplicate/near-duplicate flows without the fragility (and
/// per-run flakiness) of tapping individual PhotosPicker grid cells.
///
/// `#if DEBUG` wraps the whole file, not just a runtime flag: this code cannot exist
/// in a Release binary at all (verified by grepping the Release build for the
/// launch-argument string - see docs/QA.md), so there is no path by which a
/// Release build could accidentally activate it.
enum UITestFixtures {
    /// Launch-argument name XCUITest passes to select a fixture batch, e.g.
    /// `-UITestFixtureBatch mixed10`.
    static let launchArgumentKey = "-UITestFixtureBatch"

    /// Set once the batch named by the launch argument has been consumed, so
    /// returning to Import (e.g. via "Start New Audit") doesn't silently re-inject
    /// and re-run analysis every time Import's `.task` re-executes on reappearing -
    /// a real user picking new photos after "Start New Audit" must land on a truly
    /// idle Import screen, so a UI test verifying that must not fight its own
    /// injection re-firing.
    private static var hasConsumedBatch = false

    static func requestedBatchName() -> String? {
        guard !hasConsumedBatch else { return nil }
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: launchArgumentKey), args.indices.contains(index + 1) else {
            return nil
        }
        hasConsumedBatch = true
        return args[index + 1]
    }

    static func batch(named name: String) -> [PhotoInput]? {
        switch name {
        case "mixed10": return mixedBatch(count: 10)
        case "stress20": return mixedBatch(count: 20)
        case "duplicates": return duplicatesBatch()
        default: return nil
        }
    }

    /// A batch with varied resolution/sharpness/exposure so scoring actually
    /// differentiates photos, plus one exact-duplicate pair once `count >= 4`.
    private static func mixedBatch(count: Int) -> [PhotoInput] {
        var inputs: [PhotoInput] = []
        let sharp = renderPNG(size: CGSize(width: 1200, height: 1200)) { ctx, size in
            UIColor(red: 0.78, green: 0.71, blue: 0.59, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.9, green: 0.82, blue: 0.74, alpha: 1).setFill()
            ctx.fillEllipse(in: CGRect(x: size.width * 0.25, y: size.height * 0.25, width: size.width * 0.5, height: size.height * 0.5))
            for x in stride(from: 0, to: size.width, by: 24) {
                UIColor(red: 0.47, green: 0.35, blue: 0.24, alpha: 1).setStroke()
                let path = UIBezierPath()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                path.lineWidth = 2
                path.stroke()
            }
        }
        for i in 0..<count {
            let data: Data
            switch i % 5 {
            case 0: data = sharp
            case 1: data = renderPNG(size: CGSize(width: 300, height: 300)) { ctx, size in
                UIColor(red: 0.78, green: 0.71, blue: 0.59, alpha: 1).setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }
            case 2: data = renderPNG(size: CGSize(width: 900, height: 900)) { ctx, size in
                UIColor(red: 0.04, green: 0.03, blue: 0.03, alpha: 1).setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }
            case 3: data = renderPNG(size: CGSize(width: 900, height: 900)) { ctx, size in
                UIColor(red: 0.97, green: 0.97, blue: 0.96, alpha: 1).setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }
            default: data = renderPNG(size: CGSize(width: 850, height: 850)) { ctx, size in
                UIColor(hue: CGFloat(i) / CGFloat(max(count, 1)), saturation: 0.5, brightness: 0.8, alpha: 1).setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }
            }
            inputs.append(PhotoInput(data: data, originalFilename: "fixture-\(i).png"))
        }
        return inputs
    }

    /// Exact duplicate + near-duplicate + one unrelated photo, for deterministic
    /// similarity/duplicate-classification UI verification.
    private static func duplicatesBatch() -> [PhotoInput] {
        let base = renderPNG(size: CGSize(width: 1000, height: 1000)) { ctx, size in
            UIColor(red: 0.55, green: 0.62, blue: 0.75, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.7, green: 0.76, blue: 0.86, alpha: 1).setFill()
            ctx.fillEllipse(in: CGRect(x: 200, y: 200, width: 600, height: 600))
        }
        let nearDuplicate = renderPNG(size: CGSize(width: 1000, height: 1000)) { ctx, size in
            UIColor(red: 0.56, green: 0.63, blue: 0.76, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.71, green: 0.77, blue: 0.87, alpha: 1).setFill()
            ctx.fillEllipse(in: CGRect(x: 210, y: 195, width: 600, height: 600))
        }
        let unrelated = renderPNG(size: CGSize(width: 1000, height: 1000)) { ctx, size in
            UIColor(red: 0.15, green: 0.55, blue: 0.3, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            for i in 0..<8 {
                UIColor(red: 0.05, green: 0.3, blue: 0.12, alpha: 1).setFill()
                ctx.fill(CGRect(x: CGFloat(i) * 125, y: 0, width: 40, height: size.height))
            }
        }
        return [
            PhotoInput(data: base, originalFilename: "duplicate-a.png"),
            PhotoInput(data: base, originalFilename: "duplicate-b.png"), // bit-identical: exact duplicate
            PhotoInput(data: nearDuplicate, originalFilename: "near-duplicate.png"),
            PhotoInput(data: unrelated, originalFilename: "unrelated.png")
        ]
    }

    private static func renderPNG(size: CGSize, draw: (CGContext, CGSize) -> Void) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            draw(context.cgContext, size)
        }
        return image.pngData() ?? Data()
    }
}
#endif

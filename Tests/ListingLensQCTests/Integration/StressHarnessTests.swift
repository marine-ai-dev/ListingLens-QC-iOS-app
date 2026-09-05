import XCTest
@testable import ListingLensQCCore

private struct TimeoutError: Error {}

/// Synthetic 20-image stress harness. This deliberately does NOT assert on wall-clock
/// timing or memory footprint — this suite runs in a CI/cloud container, not on real
/// iOS hardware, so any such numbers would be fabricated. It checks the properties we
/// *can* verify anywhere: completion, absence of deadlock, determinism, and bounded
/// concurrency respected by construction (see AnalysisPipeline's TaskGroup limit).
final class StressHarnessTests: XCTestCase {
    private func fullBatch() -> [PhotoInput] {
        let generators: [() -> CGImage] = [
            { SyntheticImageFactory.sharpCheckerboard() },
            { SyntheticImageFactory.blurredCheckerboard() },
            { SyntheticImageFactory.tinyResolution() },
            { SyntheticImageFactory.highResolution() },
            { SyntheticImageFactory.darkImage() },
            { SyntheticImageFactory.overexposedImage() },
            { SyntheticImageFactory.centralSubjectImage() },
            { SyntheticImageFactory.edgeSubjectImage() },
            { SyntheticImageFactory.unrelatedImageA() },
            { SyntheticImageFactory.unrelatedImageB() }
        ]
        var inputs: [PhotoInput] = []
        for i in 0..<20 {
            let gen = generators[i % generators.count]
            inputs.append(PhotoInput(data: SyntheticImageFactory.pngData(from: gen())))
        }
        return inputs
    }

    func testTwentyImageBatchCompletesWithoutDeadlock() async throws {
        let inputs = fullBatch()
        let report = try await withTimeout(seconds: 60) {
            await AnalysisPipeline().run(inputs)
        }
        XCTAssertEqual(report.scores.count + report.failures.count, 20)
        XCTAssertNotNil(report.hero)
    }

    func testTwentyImageBatchIsFullyDeterministicAcrossTwoRuns() async throws {
        let inputs = fullBatch()
        let r1 = try await withTimeout(seconds: 60) { await AnalysisPipeline().run(inputs) }
        let r2 = try await withTimeout(seconds: 60) { await AnalysisPipeline().run(inputs) }
        XCTAssertEqual(r1.hero?.id, r2.hero?.id)
        XCTAssertEqual(r1.recommendedOrder, r2.recommendedOrder)
    }

    /// Helper: fails the test (rather than hanging CI forever) if the pipeline deadlocks.
    private func withTimeout<T: Sendable>(seconds: UInt64, operation: @escaping @Sendable () async -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
                throw TimeoutError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

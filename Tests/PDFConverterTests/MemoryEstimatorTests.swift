import XCTest
@testable import PDFConverter

final class MemoryEstimatorTests: XCTestCase {
    func testReturnsSafeStatusForSmallInput() {
        let estimator = MemoryEstimator()
        let input = MemoryEstimateInput(
            mode: .power,
            workerCount: 1,
            multiprocessEnabled: false,
            formatCounts: [.txt: 5],
            sizeBuckets: [.tiny: 5],
            configuredMaxRAMMB: 500
        )

        let estimate = estimator.estimate(input)
        XCTAssertEqual(estimate.status, .safe)
        XCTAssertLessThan(estimate.maxMB, 500)
    }

    func testReturnsNearCapWhenApproachingCap() {
        let estimator = MemoryEstimator()
        let input = MemoryEstimateInput(
            mode: .speed,
            workerCount: 4,
            multiprocessEnabled: true,
            formatCounts: [.docx: 12, .xlsx: 10, .pptx: 8],
            sizeBuckets: [.medium: 30],
            configuredMaxRAMMB: 650
        )

        let estimate = estimator.estimate(input)
        XCTAssertEqual(estimate.status, .nearCap)
        XCTAssertGreaterThanOrEqual(estimate.maxMB, Int(Double(650) * 0.85))
        XCTAssertLessThanOrEqual(estimate.maxMB, 650)
    }

    func testReturnsOverCapForLargeInput() {
        let estimator = MemoryEstimator()
        let input = MemoryEstimateInput(
            mode: .speed,
            workerCount: 10,
            multiprocessEnabled: true,
            formatCounts: [.pptx: 40, .xlsx: 40, .docx: 40],
            sizeBuckets: [.xLarge: 120],
            configuredMaxRAMMB: 500
        )

        let estimate = estimator.estimate(input)
        XCTAssertEqual(estimate.status, .overCap)
        XCTAssertGreaterThan(estimate.maxMB, 500)
    }

    @MainActor
    func testViewModelRecommendsThrottleAndQueueWhenOverCap() {
        let viewModel = PerformanceEstimatorViewModel(
            settings: PerformanceSettings(
                mode: .speed,
                maxRAMMB: 500,
                workerCount: 8,
                multiprocessEnabled: true
            )
        )
        let files = (1...100).map { URL(fileURLWithPath: "/tmp/sample\($0).pptx") }
        viewModel.updateSelectedFiles(files)

        XCTAssertEqual(viewModel.memoryEstimate.status, .overCap)
        XCTAssertTrue(viewModel.recommendation.shouldThrottleAndQueue)
        XCTAssertNotNil(viewModel.recommendation.warningMessage)
    }

    @MainActor
    func testViewModelRecomputesWhenSettingsChange() {
        let viewModel = PerformanceEstimatorViewModel(
            settings: PerformanceSettings(
                mode: .power,
                maxRAMMB: 1000,
                workerCount: 2,
                multiprocessEnabled: true
            )
        )
        let files = (1...40).map { URL(fileURLWithPath: "/tmp/input\($0).docx") }
        viewModel.updateSelectedFiles(files)
        let baselineMax = viewModel.memoryEstimate.maxMB

        viewModel.updateMode(.speed)
        viewModel.updateWorkerCount(6)
        let updatedMax = viewModel.memoryEstimate.maxMB

        XCTAssertGreaterThan(updatedMax, baselineMax)
    }
}

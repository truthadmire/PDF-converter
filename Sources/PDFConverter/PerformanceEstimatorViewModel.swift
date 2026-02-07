import Combine
import Foundation

@MainActor
public final class PerformanceEstimatorViewModel: ObservableObject {
    @Published public var settings: PerformanceSettings {
        didSet {
            recomputeEstimate()
        }
    }

    @Published public private(set) var selectedFileURLs: [URL]
    @Published public private(set) var profilingResult: InputProfilingResult
    @Published public private(set) var memoryEstimate: MemoryEstimate
    @Published public private(set) var recommendation: ExecutionPolicyRecommendation

    private let inputProfiler: InputProfiler
    private let memoryEstimator: MemoryEstimator

    public init(
        settings: PerformanceSettings = PerformanceSettings(),
        selectedFileURLs: [URL] = [],
        inputProfiler: InputProfiler = InputProfiler(),
        memoryEstimator: MemoryEstimator = MemoryEstimator()
    ) {
        self.settings = Self.sanitize(settings)
        self.selectedFileURLs = selectedFileURLs
        self.inputProfiler = inputProfiler
        self.memoryEstimator = memoryEstimator

        let initialProfile = inputProfiler.profile(files: selectedFileURLs)
        self.profilingResult = initialProfile
        let initialEstimate = memoryEstimator.estimate(
            MemoryEstimateInput(
                mode: settings.mode,
                workerCount: settings.workerCount,
                multiprocessEnabled: settings.multiprocessEnabled,
                formatCounts: initialProfile.formatCounts,
                sizeBuckets: initialProfile.sizeBuckets,
                configuredMaxRAMMB: settings.maxRAMMB
            )
        )
        self.memoryEstimate = initialEstimate
        self.recommendation = Self.buildRecommendation(from: initialEstimate, capMB: settings.maxRAMMB)
    }

    public func updateSelectedFiles(_ urls: [URL]) {
        selectedFileURLs = urls
        profilingResult = inputProfiler.profile(files: urls)
        recomputeEstimate()
    }

    public func updateMode(_ mode: ConversionMode) {
        var updated = settings
        updated.mode = mode
        settings = Self.sanitize(updated)
    }

    public func updateWorkerCount(_ count: Int) {
        var updated = settings
        updated.workerCount = count
        settings = Self.sanitize(updated)
    }

    public func updateMaxRAMMB(_ maxRAMMB: Int) {
        var updated = settings
        updated.maxRAMMB = maxRAMMB
        settings = Self.sanitize(updated)
    }

    public func updateMultiprocessEnabled(_ enabled: Bool) {
        var updated = settings
        updated.multiprocessEnabled = enabled
        settings = Self.sanitize(updated)
    }

    public var estimateLabel: String {
        "\(memoryEstimate.minMB)-\(memoryEstimate.maxMB) MB"
    }

    private func recomputeEstimate() {
        let input = MemoryEstimateInput(
            mode: settings.mode,
            workerCount: settings.workerCount,
            multiprocessEnabled: settings.multiprocessEnabled,
            formatCounts: profilingResult.formatCounts,
            sizeBuckets: profilingResult.sizeBuckets,
            configuredMaxRAMMB: settings.maxRAMMB
        )
        memoryEstimate = memoryEstimator.estimate(input)
        recommendation = Self.buildRecommendation(from: memoryEstimate, capMB: settings.maxRAMMB)
    }

    private static func buildRecommendation(
        from estimate: MemoryEstimate,
        capMB: Int
    ) -> ExecutionPolicyRecommendation {
        switch estimate.status {
        case .safe:
            return ExecutionPolicyRecommendation(shouldThrottleAndQueue: false)
        case .nearCap:
            return ExecutionPolicyRecommendation(
                shouldThrottleAndQueue: false,
                warningMessage: "Estimated RAM usage is near the configured cap (\(capMB) MB)."
            )
        case .overCap:
            return ExecutionPolicyRecommendation(
                shouldThrottleAndQueue: true,
                warningMessage: "Estimated RAM usage exceeds the configured cap (\(capMB) MB). Throttle + queue is recommended."
            )
        }
    }

    private static func sanitize(_ settings: PerformanceSettings) -> PerformanceSettings {
        PerformanceSettings(
            mode: settings.mode,
            maxRAMMB: max(128, settings.maxRAMMB),
            workerCount: max(1, settings.workerCount),
            multiprocessEnabled: settings.multiprocessEnabled
        )
    }
}

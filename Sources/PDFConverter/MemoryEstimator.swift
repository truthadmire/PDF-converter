import Foundation

public struct MemoryEstimator: Sendable {
    private let appBaselineMB: Double = 72
    private let workerMinOverheadMB: Double = 24
    private let workerMaxOverheadMB: Double = 42
    private let inProcessWorkerMinMB: Double = 12
    private let inProcessWorkerMaxMB: Double = 22

    private let formatWeights: [InputFormat: Double] = [
        .pptx: 9,
        .docx: 7,
        .xlsx: 8,
        .json: 3,
        .txt: 2,
        .html: 5,
        .yaml: 2,
        .md: 2,
        .csv: 2,
        .rtf: 3,
        .other: 4,
    ]

    private let sizeMultipliers: [FileSizeBucket: Double] = [
        .tiny: 0.7,
        .small: 1.0,
        .medium: 1.3,
        .large: 1.8,
        .xLarge: 2.4,
    ]

    public init() {}

    public func estimate(_ input: MemoryEstimateInput) -> MemoryEstimate {
        let workers = max(1, input.workerCount)
        let modeMultiplier = input.mode == .speed ? 1.15 : 0.9

        let perWorkerMin = input.multiprocessEnabled ? workerMinOverheadMB : inProcessWorkerMinMB
        let perWorkerMax = input.multiprocessEnabled ? workerMaxOverheadMB : inProcessWorkerMaxMB
        let processFloorMin = Double(workers) * perWorkerMin
        let processFloorMax = Double(workers) * perWorkerMax

        let formatLoad = estimatedFormatLoad(formatCounts: input.formatCounts)
        let sizeLoadMultiplier = estimatedSizeMultiplier(sizeBuckets: input.sizeBuckets)

        let estimatedMin = appBaselineMB + processFloorMin + (formatLoad * sizeLoadMultiplier * modeMultiplier * 0.45)
        let estimatedMax = appBaselineMB + processFloorMax + (formatLoad * sizeLoadMultiplier * modeMultiplier * 0.9)

        let minMB = max(64, Int(estimatedMin.rounded(.up)))
        let maxMB = max(minMB, Int(estimatedMax.rounded(.up)))

        let status: EstimateStatus
        let cap = input.configuredMaxRAMMB
        let nearCapThreshold = Int(Double(cap) * 0.85)
        if maxMB > cap {
            status = .overCap
        } else if maxMB >= nearCapThreshold {
            status = .nearCap
        } else {
            status = .safe
        }

        let confidence = estimateConfidence(input: input)
        return MemoryEstimate(minMB: minMB, maxMB: maxMB, status: status, confidence: confidence)
    }

    private func estimatedFormatLoad(formatCounts: [InputFormat: Int]) -> Double {
        formatCounts.reduce(into: 0.0) { partial, entry in
            let (format, count) = entry
            let weight = formatWeights[format, default: formatWeights[.other, default: 4]]
            partial += max(0, count) > 0 ? (Double(count) * weight) : 0
        }
    }

    private func estimatedSizeMultiplier(sizeBuckets: [FileSizeBucket: Int]) -> Double {
        let total = sizeBuckets.values.reduce(0, +)
        guard total > 0 else {
            return sizeMultipliers[.medium, default: 1.3]
        }

        let weighted = sizeBuckets.reduce(into: 0.0) { partial, entry in
            let (bucket, count) = entry
            partial += Double(max(0, count)) * sizeMultipliers[bucket, default: 1.0]
        }
        return weighted / Double(total)
    }

    private func estimateConfidence(input: MemoryEstimateInput) -> EstimateConfidence {
        let totalByFormat = input.formatCounts.values.reduce(0, +)
        let totalByBucket = input.sizeBuckets.values.reduce(0, +)
        guard totalByFormat >= 20, totalByBucket == totalByFormat else {
            return .medium
        }
        return .high
    }
}

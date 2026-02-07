import Foundation

public enum ConversionMode: String, Codable, CaseIterable, Sendable {
    case speed
    case power
}

public enum InputFormat: String, Codable, CaseIterable, Hashable, Sendable {
    case pptx
    case docx
    case xlsx
    case json
    case txt
    case html
    case yaml
    case md
    case csv
    case rtf
    case other

    public static func from(fileExtension: String) -> InputFormat {
        switch fileExtension.lowercased() {
        case "pptx":
            return .pptx
        case "docx":
            return .docx
        case "xlsx":
            return .xlsx
        case "json":
            return .json
        case "txt":
            return .txt
        case "html", "htm":
            return .html
        case "yaml", "yml":
            return .yaml
        case "md", "markdown":
            return .md
        case "csv":
            return .csv
        case "rtf":
            return .rtf
        default:
            return .other
        }
    }
}

public enum FileSizeBucket: String, Codable, CaseIterable, Hashable, Sendable {
    case tiny
    case small
    case medium
    case large
    case xLarge

    public static func from(fileSizeBytes: Int64) -> FileSizeBucket {
        switch fileSizeBytes {
        case ..<1_000_000:
            return .tiny
        case ..<5_000_000:
            return .small
        case ..<25_000_000:
            return .medium
        case ..<100_000_000:
            return .large
        default:
            return .xLarge
        }
    }
}

public enum EstimateStatus: String, Codable, Sendable {
    case safe
    case nearCap
    case overCap
}

public enum EstimateConfidence: String, Codable, Sendable {
    case high
    case medium
}

public struct PerformanceSettings: Codable, Equatable, Sendable {
    public var mode: ConversionMode
    public var maxRAMMB: Int
    public var workerCount: Int
    public var multiprocessEnabled: Bool

    public init(
        mode: ConversionMode = .power,
        maxRAMMB: Int = 500,
        workerCount: Int = 2,
        multiprocessEnabled: Bool = true
    ) {
        self.mode = mode
        self.maxRAMMB = max(128, maxRAMMB)
        self.workerCount = max(1, workerCount)
        self.multiprocessEnabled = multiprocessEnabled
    }
}

public struct MemoryEstimateInput: Sendable {
    public var mode: ConversionMode
    public var workerCount: Int
    public var multiprocessEnabled: Bool
    public var formatCounts: [InputFormat: Int]
    public var sizeBuckets: [FileSizeBucket: Int]
    public var configuredMaxRAMMB: Int

    public init(
        mode: ConversionMode,
        workerCount: Int,
        multiprocessEnabled: Bool,
        formatCounts: [InputFormat: Int],
        sizeBuckets: [FileSizeBucket: Int],
        configuredMaxRAMMB: Int
    ) {
        self.mode = mode
        self.workerCount = max(1, workerCount)
        self.multiprocessEnabled = multiprocessEnabled
        self.formatCounts = formatCounts
        self.sizeBuckets = sizeBuckets
        self.configuredMaxRAMMB = max(128, configuredMaxRAMMB)
    }
}

public struct MemoryEstimate: Equatable, Sendable {
    public var minMB: Int
    public var maxMB: Int
    public var status: EstimateStatus
    public var confidence: EstimateConfidence

    public init(minMB: Int, maxMB: Int, status: EstimateStatus, confidence: EstimateConfidence) {
        self.minMB = min(minMB, maxMB)
        self.maxMB = max(minMB, maxMB)
        self.status = status
        self.confidence = confidence
    }
}

public struct InputProfilingResult: Equatable, Sendable {
    public var formatCounts: [InputFormat: Int]
    public var sizeBuckets: [FileSizeBucket: Int]

    public init(
        formatCounts: [InputFormat: Int] = [:],
        sizeBuckets: [FileSizeBucket: Int] = [:]
    ) {
        self.formatCounts = formatCounts
        self.sizeBuckets = sizeBuckets
    }

    public var totalFiles: Int {
        formatCounts.values.reduce(0, +)
    }
}

public struct ExecutionPolicyRecommendation: Equatable, Sendable {
    public var shouldThrottleAndQueue: Bool
    public var warningMessage: String?

    public init(shouldThrottleAndQueue: Bool, warningMessage: String? = nil) {
        self.shouldThrottleAndQueue = shouldThrottleAndQueue
        self.warningMessage = warningMessage
    }
}

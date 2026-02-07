import Foundation

public struct InputProfiler {
    public init() {}

    public func profile(files: [URL], fileManager: FileManager = .default) -> InputProfilingResult {
        var formatCounts: [InputFormat: Int] = [:]
        var sizeBuckets: [FileSizeBucket: Int] = [:]

        for url in files {
            let format = InputFormat.from(fileExtension: url.pathExtension)
            formatCounts[format, default: 0] += 1

            let bucket: FileSizeBucket
            if
                let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                let sizeNumber = attributes[.size] as? NSNumber
            {
                bucket = .from(fileSizeBytes: sizeNumber.int64Value)
            } else {
                bucket = .medium
            }
            sizeBuckets[bucket, default: 0] += 1
        }

        return InputProfilingResult(formatCounts: formatCounts, sizeBuckets: sizeBuckets)
    }
}

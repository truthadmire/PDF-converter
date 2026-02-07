import Foundation
import XCTest
@testable import PDFConverter

final class InputProfilerTests: XCTestCase {
    func testProfilesFormatsAndSizeBuckets() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let txtURL = tempDir.appendingPathComponent("a.txt")
        let yamlURL = tempDir.appendingPathComponent("b.yaml")
        let pptxURL = tempDir.appendingPathComponent("c.pptx")

        try Data(repeating: 0, count: 10_000).write(to: txtURL)
        try Data(repeating: 0, count: 3_000_000).write(to: yamlURL)
        try Data(repeating: 0, count: 12_000_000).write(to: pptxURL)

        let profiler = InputProfiler()
        let result = profiler.profile(files: [txtURL, yamlURL, pptxURL])

        XCTAssertEqual(result.totalFiles, 3)
        XCTAssertEqual(result.formatCounts[.txt], 1)
        XCTAssertEqual(result.formatCounts[.yaml], 1)
        XCTAssertEqual(result.formatCounts[.pptx], 1)
        XCTAssertEqual(result.sizeBuckets[.tiny], 1)
        XCTAssertEqual(result.sizeBuckets[.small], 1)
        XCTAssertEqual(result.sizeBuckets[.medium], 1)
    }
}

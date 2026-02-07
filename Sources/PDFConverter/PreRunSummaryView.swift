#if canImport(SwiftUI)
import SwiftUI

@MainActor
public struct PreRunSummaryView: View {
    @ObservedObject private var viewModel: PerformanceEstimatorViewModel

    public init(viewModel: PerformanceEstimatorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pre-run Summary")
                .font(.headline)

            HStack {
                Text("Estimated runtime RAM:")
                Spacer()
                Text(viewModel.estimateLabel).monospacedDigit()
            }

            HStack {
                Text("Configured cap:")
                Spacer()
                Text("\(viewModel.settings.maxRAMMB) MB").monospacedDigit()
            }

            HStack(spacing: 8) {
                MemoryEstimateStatusChip(status: viewModel.memoryEstimate.status)
                Text("Files: \(viewModel.profilingResult.totalFiles)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let warning = viewModel.recommendation.warningMessage {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(viewModel.recommendation.shouldThrottleAndQueue ? .red : .orange)
            }

            if viewModel.recommendation.shouldThrottleAndQueue {
                Label("Throttle + queue will be applied by default.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("throttle_queue_notice")
            }
        }
        .padding()
    }
}
#endif

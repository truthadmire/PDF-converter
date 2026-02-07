#if canImport(SwiftUI)
import SwiftUI

@MainActor
public struct PerformanceSettingsView: View {
    @ObservedObject private var viewModel: PerformanceEstimatorViewModel

    public init(viewModel: PerformanceEstimatorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.title3.bold())

            Picker("Mode", selection: modeBinding) {
                Text("Speed").tag(ConversionMode.speed)
                Text("Save Power").tag(ConversionMode.power)
            }
            .pickerStyle(.segmented)

            Toggle("Enable multiprocess (when supported)", isOn: multiprocessBinding)

            Stepper(value: workerCountBinding, in: 1...16) {
                Text("Workers: \(viewModel.settings.workerCount)")
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max RAM: \(viewModel.settings.maxRAMMB) MB")
                    Spacer()
                }
                Slider(
                    value: maxRAMBinding,
                    in: 128...4096,
                    step: 64
                )
            }

            Divider()

            HStack {
                Text("Estimated runtime RAM:")
                Spacer()
                Text(viewModel.estimateLabel)
                    .monospacedDigit()
            }
            HStack {
                Text("Configured cap:")
                Spacer()
                Text("\(viewModel.settings.maxRAMMB) MB")
                    .monospacedDigit()
            }

            HStack(spacing: 10) {
                MemoryEstimateStatusChip(status: viewModel.memoryEstimate.status)
                Text("Confidence: \(viewModel.memoryEstimate.confidence.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let warningMessage = viewModel.recommendation.warningMessage {
                Text(warningMessage)
                    .font(.caption)
                    .foregroundStyle(viewModel.memoryEstimate.status == .overCap ? .red : .orange)
                    .accessibilityIdentifier("memory_warning")
            }
        }
        .padding()
    }

    private var modeBinding: Binding<ConversionMode> {
        Binding(
            get: { viewModel.settings.mode },
            set: { viewModel.updateMode($0) }
        )
    }

    private var multiprocessBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.multiprocessEnabled },
            set: { viewModel.updateMultiprocessEnabled($0) }
        )
    }

    private var workerCountBinding: Binding<Int> {
        Binding(
            get: { viewModel.settings.workerCount },
            set: { viewModel.updateWorkerCount($0) }
        )
    }

    private var maxRAMBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.settings.maxRAMMB) },
            set: { viewModel.updateMaxRAMMB(Int($0.rounded())) }
        )
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

public struct MemoryEstimateStatusChip: View {
    public let status: EstimateStatus

    public init(status: EstimateStatus) {
        self.status = status
    }

    public var body: some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .clipShape(Capsule())
            .accessibilityIdentifier("memory_status_chip")
    }

    private var label: String {
        switch status {
        case .safe:
            return "Safe"
        case .nearCap:
            return "Near cap"
        case .overCap:
            return "Over cap"
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .safe:
            return .blue
        case .nearCap:
            return .orange
        case .overCap:
            return .red
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .safe:
            return Color.blue.opacity(0.12)
        case .nearCap:
            return Color.orange.opacity(0.14)
        case .overCap:
            return Color.red.opacity(0.14)
        }
    }
}
#endif

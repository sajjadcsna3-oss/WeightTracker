import SwiftUI

struct TrendMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    var highlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(.system(size: 23, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .background(highlighted ? AppTheme.lime.opacity(0.78) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(highlighted ? .clear : AppTheme.stroke)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        TrendMetricCard(title: "Peak", value: "82.4", systemImage: "arrow.up")
        TrendMetricCard(
            title: "Lowest",
            value: "74.8",
            systemImage: "arrow.down",
            highlighted: true
        )
    }
    .padding()
    .frame(width: 400)
    .background(AppTheme.background)
}

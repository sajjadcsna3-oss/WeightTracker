import SwiftData
import SwiftUI

struct TrendsView: View {
    @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]
    @Query private var profiles: [WeightProfile]

    @AppStorage("trends.range") private var rangeRaw = TrendRange.threeMonths.rawValue
    @AppStorage("trends.showsForecast") private var showsForecast = true

    private var range: TrendRange {
        TrendRange(rawValue: rangeRaw) ?? .threeMonths
    }

    private var visibleEntries: [WeightEntry] {
        guard let days = range.days else { return entries }
        let end = entries.last?.date ?? .now
        let start = Calendar.current.date(byAdding: .day, value: -days, to: end) ?? end
        return entries.filter { $0.date >= start && $0.date <= end }
    }

    private var goal: Double { profiles.first?.goalKilograms ?? 70 }
    private var weights: [Double] { visibleEntries.map(\.kilograms) }
    private var chartPoints: [TrendChartPoint] {
        Self.makeChartPoints(from: visibleEntries, maximumCount: 260)
    }
    private var sevenDayAverage: Double? {
        WeightMath.average(visibleEntries, duringLastDays: 7)
    }
    private var weeklyRate: Double? { WeightMath.weeklyRate(visibleEntries) }
    private var dailySwing: Double? { WeightMath.averageDailySwing(visibleEntries) }

    private var forecastRate: Double? {
        if let measuredRate = weeklyRate,
           let last = visibleEntries.last,
           (goal - last.kilograms) * measuredRate > 0 {
            return measuredRate
        }

        guard let last = visibleEntries.last else { return nil }
        let plannedPace = max(0, profiles.first?.paceKilogramsPerWeek ?? 0.5)
        guard plannedPace > 0, abs(last.kilograms - goal) > 0.05 else { return 0 }
        return last.kilograms > goal ? -plannedPace : plannedPace
    }

    private var forecastWeight: Double? {
        guard showsForecast,
              let last = visibleEntries.last,
              let rate = forecastRate else { return nil }

        let projected = last.kilograms + rate * 30 / 7
        let isMovingTowardGoal = (goal - last.kilograms) * rate > 0

        if isMovingTowardGoal {
            return last.kilograms > goal
                ? max(goal, projected)
                : min(goal, projected)
        }
        return projected
    }

    private var title: String {
        guard let first = visibleEntries.first?.date,
              let last = visibleEntries.last?.date else { return "WEIGHT HISTORY" }
        let firstText = first.formatted(.dateTime.month(.abbreviated)).uppercased()
        let lastText = last.formatted(.dateTime.month(.abbreviated).year()).uppercased()
        return "\(firstText)  —  \(lastText)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            chartCard
            metrics
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 30)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text("Trends")
                    .font(.system(size: 27, weight: .bold))
            }

            Spacer()

            HStack(spacing: 2) {
                ForEach(TrendRange.allCases) { item in
                    Button(item.title) { rangeRaw = item.rawValue }
                        .font(.system(size: 11, weight: range == item ? .semibold : .regular))
                        .foregroundStyle(range == item ? AppTheme.ink : .secondary)
                        .frame(width: 42, height: 30)
                        .background(range == item ? AppTheme.lime.opacity(0.82) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(range == item ? .isSelected : [])
                }
            }
            .padding(3)
            .background(Color.black.opacity(0.055))
            .clipShape(RoundedRectangle(cornerRadius: 11))
        }
    }

    private var chartCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                legend("Weight", color: AppTheme.ink)
                legend("7-day average", color: .secondary, dashed: true)
                legend("Goal \(String(format: "%.1f", goal))", color: .red, dashed: true)
                Spacer()
                HStack(spacing: 8) {
                    Text("Forecast")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            showsForecast.toggle()
                        }
                    } label: {
                        ZStack(alignment: showsForecast ? .trailing : .leading) {
                            Capsule()
                                .fill(
                                    showsForecast
                                        ? AppTheme.lime
                                        : Color.black.opacity(0.14)
                                )
                                .frame(width: 36, height: 20)

                            Circle()
                                .fill(showsForecast ? AppTheme.ink : .white)
                                .frame(width: 16, height: 16)
                                .padding(2)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(visibleEntries.isEmpty)
                    .opacity(visibleEntries.isEmpty ? 0.45 : 1)
                    .accessibilityLabel("Forecast")
                    .accessibilityValue(showsForecast ? "On" : "Off")
                }
            }

            if visibleEntries.isEmpty {
                ContentUnavailableView(
                    "No trend data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Log at least one weight entry to see your trend.")
                )
                .frame(maxWidth: .infinity, minHeight: 310)
            } else {
                chart
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 19))
        .overlay { RoundedRectangle(cornerRadius: 19).stroke(AppTheme.stroke) }
    }

    private var chart: some View {
        let points = chartPoints
        let domain = chartDomain
        let records = visibleEntries
        let projectedWeight = forecastWeight

        return TrendCanvasChart(
            points: points,
            domain: domain,
            goal: goal,
            latestDate: records.last?.date,
            latestWeight: records.last?.kilograms,
            projectedWeight: showsForecast ? projectedWeight : nil
        )
        .frame(height: 330)
    }

    private var chartDomain: ClosedRange<Double> {
        let values = weights + [goal] + (forecastWeight.map { [$0] } ?? [])
        let low = (values.min() ?? 68).rounded(.down) - 1
        let high = (values.max() ?? 84).rounded(.up) + 1
        return low...max(low + 4, high)
    }

    private var metrics: some View {
        HStack(spacing: 11) {
            TrendMetricCard(title: "Peak", value: format(weights.max()), systemImage: "arrow.up")
            TrendMetricCard(title: "Lowest", value: format(weights.min()), systemImage: "arrow.down", highlighted: true)
            TrendMetricCard(title: "7-day avg", value: format(sevenDayAverage), systemImage: "clock.arrow.circlepath")
            TrendMetricCard(title: "Weekly rate", value: signed(weeklyRate), systemImage: "gauge.with.dots.needle.33percent")
            TrendMetricCard(title: "Daily swing", value: dailySwing.map { "±\(String(format: "%.1f", $0))" } ?? "—", systemImage: "drop")
        }
    }

    private func legend(_ title: String, color: Color, dashed: Bool = false) -> some View {
        HStack(spacing: 7) {
            Capsule()
                .stroke(color, style: StrokeStyle(lineWidth: 2, dash: dashed ? [2, 2] : []))
                .frame(width: 14, height: 2)
            Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private func format(_ value: Double?) -> String {
        value.map { String(format: "%.1f", $0) } ?? "—"
    }

    private func signed(_ value: Double?) -> String {
        value.map { String(format: "%+.2f", $0) } ?? "—"
    }

    // Builds the rolling average in one pass and limits chart density. This keeps
    // Swift Charts responsive even when the user has years of daily entries.
    private static func makeChartPoints(
        from entries: [WeightEntry],
        maximumCount: Int
    ) -> [TrendChartPoint] {
        let sorted = entries.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }

        let sampleStep = max(1, Int(ceil(Double(sorted.count) / Double(maximumCount))))
        let sevenDays: TimeInterval = 7 * 86_400
        var windowStart = 0
        var windowTotal = 0.0
        var points: [TrendChartPoint] = []
        points.reserveCapacity(min(sorted.count, maximumCount + 1))

        for index in sorted.indices {
            let entry = sorted[index]
            windowTotal += entry.kilograms

            while windowStart < index,
                  entry.date.timeIntervalSince(sorted[windowStart].date) >= sevenDays {
                windowTotal -= sorted[windowStart].kilograms
                windowStart += 1
            }

            if index % sampleStep == 0 || index == sorted.index(before: sorted.endIndex) {
                let count = index - windowStart + 1
                points.append(
                    TrendChartPoint(
                        date: entry.date,
                        weight: entry.kilograms,
                        rollingAverage: windowTotal / Double(count)
                    )
                )
            }
        }

        return points
    }
}

private struct TrendChartPoint: Identifiable {
    let date: Date
    let weight: Double
    let rollingAverage: Double
    var id: Date { date }
}

private struct TrendCanvasChart: View {
    let points: [TrendChartPoint]
    let domain: ClosedRange<Double>
    let goal: Double
    let latestDate: Date?
    let latestWeight: Double?
    let projectedWeight: Double?

    private let leadingInset = 32.0
    private let trailingInset = 8.0
    private let topInset = 10.0
    private let bottomInset = 24.0

    var body: some View {
        Canvas { context, size in
            guard let firstDate = points.first?.date,
                  let finalHistoryDate = latestDate ?? points.last?.date else { return }

            let forecastDate = finalHistoryDate.addingTimeInterval(30 * 86_400)
            let endDate = projectedWeight == nil ? finalHistoryDate : forecastDate
            let duration = max(1, endDate.timeIntervalSince(firstDate))
            let plotWidth = max(1, size.width - leadingInset - trailingInset)
            let plotHeight = max(1, size.height - topInset - bottomInset)

            func x(_ date: Date) -> CGFloat {
                leadingInset + plotWidth * date.timeIntervalSince(firstDate) / duration
            }
            func y(_ value: Double) -> CGFloat {
                let span = max(0.01, domain.upperBound - domain.lowerBound)
                return topInset + plotHeight * (domain.upperBound - value) / span
            }

            for index in 0...4 {
                let fraction = Double(index) / 4
                let value = domain.upperBound - (domain.upperBound - domain.lowerBound) * fraction
                let lineY = topInset + plotHeight * fraction
                var grid = Path()
                grid.move(to: CGPoint(x: leadingInset, y: lineY))
                grid.addLine(to: CGPoint(x: size.width - trailingInset, y: lineY))
                context.stroke(grid, with: .color(AppTheme.stroke.opacity(0.65)), lineWidth: 1)
                context.draw(
                    Text(String(format: "%.0f", value))
                        .font(.system(size: 9)).foregroundStyle(.secondary),
                    at: CGPoint(x: 12, y: lineY),
                    anchor: .center
                )
            }

            if let first = points.first {
                var area = Path()
                area.move(to: CGPoint(x: x(first.date), y: y(domain.lowerBound)))
                for point in points {
                    area.addLine(to: CGPoint(x: x(point.date), y: y(point.weight)))
                }
                if let last = points.last {
                    area.addLine(to: CGPoint(x: x(last.date), y: y(domain.lowerBound)))
                }
                area.closeSubpath()
                context.fill(area, with: .color(AppTheme.lime.opacity(0.12)))
            }

            drawLine(
                points.map { CGPoint(x: x($0.date), y: y($0.weight)) },
                color: AppTheme.ink,
                style: StrokeStyle(lineWidth: 2.2),
                in: &context
            )
            drawLine(
                points.map { CGPoint(x: x($0.date), y: y($0.rollingAverage)) },
                color: .secondary,
                style: StrokeStyle(lineWidth: 1.4, dash: [3, 3]),
                in: &context
            )

            var goalLine = Path()
            goalLine.move(to: CGPoint(x: leadingInset, y: y(goal)))
            goalLine.addLine(to: CGPoint(x: size.width - trailingInset, y: y(goal)))
            context.stroke(goalLine, with: .color(.red.opacity(0.72)), style: StrokeStyle(lineWidth: 1.2, dash: [5, 5]))

            if let latestDate, let latestWeight {
                let currentPoint = CGPoint(x: x(latestDate), y: y(latestWeight))
                var todayLine = Path()
                todayLine.move(to: CGPoint(x: currentPoint.x, y: topInset))
                todayLine.addLine(to: CGPoint(x: currentPoint.x, y: topInset + plotHeight))
                context.stroke(todayLine, with: .color(.secondary.opacity(0.4)), lineWidth: 1)
                context.fill(Path(ellipseIn: CGRect(x: currentPoint.x - 6, y: currentPoint.y - 6, width: 12, height: 12)), with: .color(.white))
                context.stroke(Path(ellipseIn: CGRect(x: currentPoint.x - 6, y: currentPoint.y - 6, width: 12, height: 12)), with: .color(AppTheme.ink), lineWidth: 2.5)

                if let projectedWeight {
                    let futurePoint = CGPoint(x: x(forecastDate), y: y(projectedWeight))
                    drawLine(
                        [currentPoint, futurePoint],
                        color: .secondary,
                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]),
                        in: &context
                    )
                }
            }

            for index in 0...4 {
                let fraction = Double(index) / 4
                let date = firstDate.addingTimeInterval(duration * fraction)
                context.draw(
                    Text(date.formatted(.dateTime.month(.abbreviated)).uppercased())
                        .font(.system(size: 9)).foregroundStyle(.secondary),
                    at: CGPoint(x: leadingInset + plotWidth * fraction, y: size.height - 7),
                    anchor: .center
                )
            }
        }
        .accessibilityLabel("Weight trend chart")
        .accessibilityValue("\(points.count) plotted weight records")
    }

    private func drawLine(
        _ points: [CGPoint],
        color: Color,
        style: StrokeStyle,
        in context: inout GraphicsContext
    ) {
        guard let first = points.first else { return }
        var path = Path()
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        context.stroke(path, with: .color(color), style: style)
    }
}

private enum TrendRange: String, CaseIterable, Identifiable {
    case week
    case month
    case threeMonths
    case year
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "W"
        case .month: return "M"
        case .threeMonths: return "3M"
        case .year: return "Y"
        case .all: return "All"
        }
    }

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 92
        case .year: return 365
        case .all: return nil
        }
    }
}

#Preview("Trends") {
    TrendsView()
        .modelContainer(for: [WeightProfile.self, WeightEntry.self], inMemory: true)
}

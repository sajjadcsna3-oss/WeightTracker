import Charts
import SwiftData
import SwiftUI

struct ForecastView: View {
  @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]
  @Query private var profiles: [WeightProfile]
  @AppStorage("forecast.scenario") private var selectedScenarioRaw = ForecastScenario.current.rawValue

  private var profile: WeightProfile? { profiles.first }
  private var currentWeight: Double {
    entries.last?.kilograms ?? profile?.startingKilograms ?? 70
  }
  private var currentDate: Date { entries.last?.date ?? .now }
  private var selectedScenario: ForecastScenario {
    ForecastScenario(rawValue: selectedScenarioRaw) ?? .current
  }

  var body: some View {
    Group {
      if let profile {
        forecastContent(profile)
      } else {
        ContentUnavailableView(
          "No profile found",
          systemImage: "person.crop.circle.badge.questionmark",
          description: Text("Complete your profile before creating a forecast.")
        )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppTheme.background)
  }

  private func forecastContent(_ profile: WeightProfile) -> some View {
    let rate = projectionRate(for: selectedScenario, profile: profile)
    let goalDate = projectedGoalDate(profile: profile, rate: rate)
    let days = daysUntil(goalDate)

    return VStack(alignment: .leading, spacing: 16) {
      header(profile: profile, goalDate: goalDate, days: days)
      forecastChart(profile: profile, rate: rate, goalDate: goalDate)
      scenarioPicker(profile: profile)
      milestoneSection(profile: profile, rate: rate)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 30)
    .padding(.top, 24)
    .padding(.bottom, 22)
  }

  private func header(profile: WeightProfile, goalDate: Date?, days: Int?) -> some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 5) {
        Text("FORECAST  ·  AT YOUR \(selectedScenario.title.uppercased())")
          .font(.system(size: 10, design: .monospaced))
          .foregroundStyle(.secondary)

        HStack(spacing: 6) {
          Text(weightText(profile.goalKilograms))
            .foregroundStyle(AppTheme.ink)
          Text("on \(goalDate?.formatted(.dateTime.day().month(.abbreviated).year()) ?? "—")")
            .foregroundStyle(Color(red: 0.27, green: 0.43, blue: 0.04))
        }
        .font(.system(size: 34, weight: .bold))
        .tracking(-1.7)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 1) {
        Text(days.map(String.init) ?? "—")
          .font(.system(size: 34, weight: .light))
          .monospacedDigit()
        Text("DAYS TO GO")
          .font(.system(size: 9, design: .monospaced))
          .foregroundStyle(.secondary)
      }
    }
  }

  private func forecastChart(profile: WeightProfile, rate: Double, goalDate: Date?) -> some View {
    let history = chartHistory(profile: profile)
    let projection = projectionPoints(profile: profile, rate: rate, goalDate: goalDate)
    let domain = chartDomain(profile: profile, projection: projection)
    let startDate = history.first?.date ?? Calendar.current.date(byAdding: .month, value: -3, to: currentDate) ?? currentDate
    let endDate = projection.last?.date ?? Calendar.current.date(byAdding: .month, value: 3, to: currentDate) ?? currentDate

    return Chart {
      ForEach(history) { entry in
        LineMark(
          x: .value("Date", entry.date),
          y: .value("Weight", entry.kilograms),
          series: .value("Series", "History")
        )
        .foregroundStyle(AppTheme.ink)
        .lineStyle(StrokeStyle(lineWidth: 2))
      }

      ForEach(projection) { point in
        AreaMark(
          x: .value("Forecast date", point.date),
          yStart: .value("Lower range", point.lower),
          yEnd: .value("Upper range", point.upper)
        )
        .foregroundStyle(AppTheme.lime.opacity(0.13))

        LineMark(
          x: .value("Forecast date", point.date),
          y: .value("Forecast weight", point.weight),
          series: .value("Series", "Forecast")
        )
        .foregroundStyle(AppTheme.ink)
        .lineStyle(StrokeStyle(lineWidth: 1.8, dash: [4, 4]))
      }

      RuleMark(y: .value("Goal", profile.goalKilograms))
        .foregroundStyle(Color.red.opacity(0.7))
        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [5, 5]))

      RuleMark(x: .value("Today", currentDate))
        .foregroundStyle(Color.secondary.opacity(0.35))

      PointMark(x: .value("Today", currentDate), y: .value("Current", currentWeight))
        .foregroundStyle(AppTheme.ink)
        .symbolSize(68)

      if let last = projection.last {
        PointMark(x: .value("Goal date", last.date), y: .value("Goal", last.weight))
          .foregroundStyle(AppTheme.lime)
          .symbolSize(100)
          .annotation(position: .overlay) {
            Circle().stroke(.white, lineWidth: 2).frame(width: 12, height: 12)
          }
      }
    }
    .chartXScale(domain: startDate...max(endDate, currentDate.addingTimeInterval(86_400)))
    .chartYScale(domain: domain)
    .chartLegend(.hidden)
    .chartXAxis {
      AxisMarks(values: .stride(by: .month)) { value in
        AxisValueLabel(format: .dateTime.month(.abbreviated))
          .font(.system(size: 9))
        AxisGridLine().foregroundStyle(.clear)
        AxisTick().foregroundStyle(.clear)
      }
    }
    .chartYAxis(.hidden)
    .frame(minHeight: 245)
    .padding(.horizontal, 18)
    .padding(.top, 18)
    .padding(.bottom, 10)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 19))
    .overlay { RoundedRectangle(cornerRadius: 19).stroke(AppTheme.stroke) }
    .accessibilityLabel("Weight forecast chart")
    .accessibilityValue("Projected goal date \(goalDate?.formatted(date: .abbreviated, time: .omitted) ?? "unavailable")")
  }

  private func scenarioPicker(profile: WeightProfile) -> some View {
    HStack(spacing: 11) {
      ForEach(ForecastScenario.allCases) { scenario in
        let date = projectedGoalDate(
          profile: profile,
          rate: projectionRate(for: scenario, profile: profile)
        )

        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            selectedScenarioRaw = scenario.rawValue
          }
        } label: {
          HStack {
            VStack(alignment: .leading, spacing: 3) {
              Text(scenario.title)
                .font(.system(size: 12, weight: .semibold))
              Text(rateText(projectionRate(for: scenario, profile: profile)))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(date?.formatted(.dateTime.day().month(.abbreviated)) ?? "—")
              .font(.system(size: 15, weight: .bold))
          }
          .padding(.horizontal, 16)
          .frame(maxWidth: .infinity, minHeight: 64)
          .foregroundStyle(AppTheme.ink)
          .background(selectedScenario == scenario ? AppTheme.lime.opacity(0.78) : .white)
          .clipShape(RoundedRectangle(cornerRadius: 15))
          .overlay {
            RoundedRectangle(cornerRadius: 15)
              .stroke(selectedScenario == scenario ? AppTheme.lime : AppTheme.stroke)
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(scenario.title), \(rateText(projectionRate(for: scenario, profile: profile)))")
        .accessibilityAddTraits(selectedScenario == scenario ? .isSelected : [])
      }
    }
  }

  private func milestoneSection(profile: WeightProfile, rate: Double) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Milestones")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.secondary)

      HStack(spacing: 9) {
        ForEach(milestones(profile: profile, rate: rate)) { milestone in
          VStack(alignment: .leading, spacing: 7) {
            Image(systemName: milestone.isGoal ? "flag" : milestone.isComplete ? "checkmark.circle" : "circle")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(milestone.isGoal ? .red.opacity(0.75) : milestone.isComplete ? Color(red: 0.35, green: 0.52, blue: 0.07) : .secondary)
            Spacer(minLength: 0)
            Text(milestone.title)
              .font(.system(size: 11, weight: .semibold))
              .lineLimit(1)
            Text(milestone.dateText)
              .font(.system(size: 9, design: .monospaced))
              .foregroundStyle(.secondary)
          }
          .padding(12)
          .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
          .background(AppTheme.sidebar.opacity(0.72))
          .clipShape(RoundedRectangle(cornerRadius: 14))
          .overlay {
            RoundedRectangle(cornerRadius: 14)
              .stroke(milestone.isCurrent ? AppTheme.lime : .clear)
          }
          .accessibilityElement(children: .combine)
        }
      }
    }
  }

  private func projectionRate(for scenario: ForecastScenario, profile: WeightProfile) -> Double {
    let direction = profile.goalKilograms < currentWeight ? -1.0 : 1.0
    let planned = max(0.1, profile.paceKilogramsPerWeek)

    switch scenario {
    case .current:
      if let measured = WeightMath.weeklyRate(entries), measured * direction > 0.02 {
        return direction * min(2.0, max(0.05, abs(measured)))
      }
      return direction * planned
    case .steady:
      return direction * max(0.5, planned)
    case .focused:
      return direction * max(0.75, planned * 1.5)
    }
  }

  private func projectedGoalDate(profile: WeightProfile, rate: Double) -> Date? {
    if abs(currentWeight - profile.goalKilograms) < 0.05 { return currentDate }
    return WeightMath.goalDate(
      current: currentWeight,
      goal: profile.goalKilograms,
      weeklyRate: rate,
      from: currentDate
    )
  }

  private func projectionPoints(profile: WeightProfile, rate: Double, goalDate: Date?) -> [ProjectionPoint] {
    guard let goalDate else { return [] }
    let totalDays = max(0, Calendar.current.dateComponents([.day], from: currentDate, to: goalDate).day ?? 0)
    let step = 7
    var points = [ProjectionPoint(date: currentDate, weight: currentWeight, lower: currentWeight, upper: currentWeight)]

    for day in stride(from: step, through: totalDays, by: step) {
      guard let date = Calendar.current.date(byAdding: .day, value: day, to: currentDate) else { continue }
      let rawWeight = currentWeight + rate * Double(day) / 7
      let weight = clampedToGoal(rawWeight, goal: profile.goalKilograms)
      let uncertainty = min(1.8, 0.12 + Double(day) / 90 * 0.45)
      points.append(ProjectionPoint(date: date, weight: weight, lower: weight - uncertainty, upper: weight + uncertainty))
    }

    if points.last?.date != goalDate {
      let uncertainty = min(1.8, 0.12 + Double(totalDays) / 90 * 0.45)
      points.append(
        ProjectionPoint(
          date: goalDate,
          weight: profile.goalKilograms,
          lower: profile.goalKilograms - uncertainty,
          upper: profile.goalKilograms + uncertainty
        )
      )
    }
    return points
  }

  private func chartHistory(profile: WeightProfile) -> [WeightEntry] {
    if !entries.isEmpty {
      let cutoff = Calendar.current.date(byAdding: .month, value: -6, to: currentDate) ?? .distantPast
      return entries.filter { $0.date >= cutoff }
    }
    return [WeightEntry(date: profile.createdAt, kilograms: profile.startingKilograms)]
  }

  private func chartDomain(profile: WeightProfile, projection: [ProjectionPoint]) -> ClosedRange<Double> {
    let values = entries.map(\.kilograms) + projection.flatMap { [$0.lower, $0.upper] } + [profile.goalKilograms, currentWeight]
    let lower = (values.min() ?? profile.goalKilograms).rounded(.down) - 1
    let upper = (values.max() ?? currentWeight).rounded(.up) + 1
    return lower...max(lower + 4, upper)
  }

  private func milestones(profile: WeightProfile, rate: Double) -> [ForecastMilestone] {
    let start = profile.startingKilograms
    let goal = profile.goalKilograms
    let direction = goal < start ? -1.0 : 1.0
    let distance = abs(goal - start)
    let candidates: [(String, Double, Bool)] = [
      ("First 2 kg", start + direction * min(2, distance), false),
      (direction < 0 ? "−5 kg" : "+5 kg", start + direction * min(5, distance), false),
      (thresholdTitle(start + (goal - start) * 0.5, direction: direction), start + (goal - start) * 0.5, false),
      (direction < 0 ? "−10%" : "+10%", start * (direction < 0 ? 0.9 : 1.1), false),
      ("Goal \(String(format: "%.1f", goal))", goal, true),
    ]

    return candidates.enumerated().map { index, item in
      let target = direction < 0 ? max(goal, item.1) : min(goal, item.1)
      let complete = hasReached(target, direction: direction)
      let achieved = completionDate(for: target, direction: direction)
      let projected = estimatedDate(for: target, rate: rate)
      let date = achieved ?? projected
      let isCurrent = !complete && candidates.prefix(index).allSatisfy {
        hasReached(direction < 0 ? max(goal, $0.1) : min(goal, $0.1), direction: direction)
      }

      return ForecastMilestone(
        id: index,
        title: item.0,
        dateText: complete && achieved == nil ? "TODAY" : date?.formatted(.dateTime.day().month(.abbreviated)).uppercased() ?? "—",
        isComplete: complete,
        isCurrent: isCurrent,
        isGoal: item.2
      )
    }
  }

  private func hasReached(_ target: Double, direction: Double) -> Bool {
    direction < 0 ? currentWeight <= target + 0.05 : currentWeight >= target - 0.05
  }

  private func completionDate(for target: Double, direction: Double) -> Date? {
    entries.first {
      direction < 0 ? $0.kilograms <= target + 0.05 : $0.kilograms >= target - 0.05
    }?.date
  }

  private func estimatedDate(for target: Double, rate: Double) -> Date? {
    if abs(currentWeight - target) < 0.05 { return currentDate }
    return WeightMath.goalDate(current: currentWeight, goal: target, weeklyRate: rate, from: currentDate)
  }

  private func clampedToGoal(_ value: Double, goal: Double) -> Double {
    currentWeight > goal ? max(goal, value) : min(goal, value)
  }

  private func daysUntil(_ date: Date?) -> Int? {
    guard let date else { return nil }
    return max(0, Calendar.current.dateComponents([.day], from: currentDate, to: date).day ?? 0)
  }

  private func thresholdTitle(_ value: Double, direction: Double) -> String {
    "\(direction < 0 ? "Below" : "Above") \(String(format: "%.0f", value))"
  }

  private func weightText(_ kilograms: Double) -> String {
    "\(String(format: "%.1f", kilograms)) kg"
  }

  private func rateText(_ rate: Double) -> String {
    "\(String(format: "%+.2f", rate)) kg/wk"
  }
}

private enum ForecastScenario: String, CaseIterable, Identifiable {
  case current
  case steady
  case focused

  var id: String { rawValue }
  var title: String {
    switch self {
    case .current: return "Current pace"
    case .steady: return "Steady"
    case .focused: return "Focused"
    }
  }
}

private struct ProjectionPoint: Identifiable {
  let date: Date
  let weight: Double
  let lower: Double
  let upper: Double
  var id: Date { date }
}

private struct ForecastMilestone: Identifiable {
  let id: Int
  let title: String
  let dateText: String
  let isComplete: Bool
  let isCurrent: Bool
  let isGoal: Bool
}

#Preview("Forecast") {
  ForecastView()
    .modelContainer(for: [WeightProfile.self, WeightEntry.self], inMemory: true)
    .frame(width: 884, height: 716)
}

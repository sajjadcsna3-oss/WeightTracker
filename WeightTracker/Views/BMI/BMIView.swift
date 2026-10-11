import Charts
import SwiftData
import SwiftUI

struct BMIView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]
  @Query private var profiles: [WeightProfile]
  @State private var isEditingHeight = false
  @State private var heightText = ""
  @State private var heightError: String?

  private var profile: WeightProfile? { profiles.first }
  private var height: Double { max(profile?.heightCentimeters ?? 0, 1) }
  private var currentWeight: Double {
    entries.last?.kilograms ?? profile?.startingKilograms ?? 0
  }
  private var bmi: Double { Self.bmi(weight: currentWeight, height: height) }
    private var goalBMI: Double {
    Self.bmi(weight: profile?.goalKilograms ?? 0, height: height)
  }
  private var recentEntries: [WeightEntry] {
    guard let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) else {
      return entries
    }
    return entries.filter { $0.date >= cutoff }
  }
  private var chartPoints: [BMIPoint] {
    recentEntries.map { BMIPoint(date: $0.date, value: Self.bmi(weight: $0.kilograms, height: height)) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
        .padding(.bottom, 20)

      bmiSummaryCard
        .frame(height: 230)

      HStack(alignment: .top, spacing: 12) {
        trendCard
          .frame(maxWidth: .infinity)
        healthyRangeCard
          .frame(maxWidth: .infinity)
      }
      .padding(.top, 16)
      .frame(maxHeight: .infinity)
    }
    .padding(.horizontal, 28)
    .padding(.top, 24)
    .padding(.bottom, 22)
    .background(AppTheme.background)
    .sheet(isPresented: $isEditingHeight) {
      heightEditor
    }
  }

  private var header: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading, spacing: 5) {
        Text("BODY MASS INDEX")
          .font(.system(size: 10, design: .monospaced))
          .foregroundStyle(.secondary)
          .tracking(0.5)
        Text("BMI")
          .font(.system(size: 27, weight: .bold))
      }
      Spacer()
      Button {
        heightText = String(format: "%.0f", height)
        heightError = nil
        isEditingHeight = true
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "arrow.up.and.down")
            .font(.system(size: 11, weight: .medium))
          Text("\(height, specifier: "%.0f") cm · edit")
            .font(.system(size: 12))
        }
        .foregroundStyle(AppTheme.ink.opacity(0.68))
        .padding(.horizontal, 15)
        .frame(height: 38)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(AppTheme.stroke))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Edit height, currently \(Int(height)) centimeters")
    }
  }

  private var bmiSummaryCard: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center) {
        HStack(alignment: .lastTextBaseline, spacing: 18) {
          Text(bmi > 0 ? String(format: "%.1f", bmi) : "—")
            .font(.system(size: 82, weight: .light))
            .tracking(-5)
            .foregroundStyle(AppTheme.ink)
          Text(category.title)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 13)
            .frame(height: 28)
            .background(category.color)
            .clipShape(Capsule())
            .offset(y: -8)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 5) {
          Text("AT GOAL WEIGHT")
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(.secondary)
          Text(goalBMI > 0 ? String(format: "%.1f", goalBMI) : "—")
            .font(.system(size: 28, weight: .bold))
        }
      }
      .padding(.horizontal, 28)
      .padding(.top, 24)

      Spacer(minLength: 12)
      bmiScale
        .padding(.horizontal, 28)
        .padding(.bottom, 25)
    }
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.stroke))
  }

  private var bmiScale: some View {
    GeometryReader { proxy in
      let gap: CGFloat = 4
      let width = proxy.size.width
      let first = width * 0.14
      let second = width * 0.26
      let third = width * 0.20
      let fourth = max(0, width - first - second - third - gap * 3)
      let currentMarker = markerPosition(for: bmi, width: width)
      let goalMarker = markerPosition(for: goalBMI, width: width)

      VStack(alignment: .leading, spacing: 10) {
        ZStack(alignment: .leading) {
          HStack(spacing: gap) {
            RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.39, green: 0.67, blue: 0.94)).frame(width: first)
            RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.74, green: 0.94, blue: 0.42)).frame(width: second)
            RoundedRectangle(cornerRadius: 4).fill(Color(red: 1.0, green: 0.72, blue: 0.34)).frame(width: third)
            RoundedRectangle(cornerRadius: 4).fill(Color(red: 1.0, green: 0.43, blue: 0.36)).frame(width: fourth)
          }
          Circle()
            .fill(.white)
            .overlay(Circle().stroke(AppTheme.ink, lineWidth: 1))
            .frame(width: 15, height: 15)
            .offset(x: min(max(goalMarker - 7.5, 0), width - 15))
          Rectangle()
            .fill(AppTheme.ink)
            .frame(width: 4, height: 30)
            .clipShape(Capsule())
            .offset(x: min(max(currentMarker - 2, 0), width - 4))
        }
        .frame(height: 15)

        HStack(spacing: gap) {
          scaleLabel("Under", "<18.5").frame(width: first, alignment: .leading)
          scaleLabel("Healthy", "18.5–25").frame(width: second, alignment: .leading)
          scaleLabel("Over", "25–30").frame(width: third, alignment: .leading)
          scaleLabel("Obese", "30+").frame(width: fourth, alignment: .leading)
        }
      }
    }
    .frame(height: 64)
  }

  private var trendCard: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("BMI over 30 days").font(.system(size: 14, weight: .semibold))
        Spacer()
        Text(changeText)
          .font(.system(size: 12, design: .monospaced))
          .foregroundStyle(Color(red: 0.38, green: 0.53, blue: 0.17))
      }

      if chartPoints.isEmpty {
        ContentUnavailableView(
          "No BMI history", systemImage: "chart.xyaxis.line",
          description: Text("Log weight entries to build your 30-day chart."))
          .frame(maxWidth: .infinity, minHeight: 220)
      } else {
        Chart {
          RectangleMark(
            xStart: .value("Start", chartStart),
            xEnd: .value("End", chartEnd),
            yStart: .value("Healthy minimum", 18.5),
            yEnd: .value("Healthy maximum", 25)
          )
          .foregroundStyle(AppTheme.lime.opacity(0.12))

          RuleMark(y: .value("Healthy maximum", 25))
            .foregroundStyle(Color.orange)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))

          ForEach(chartPoints) { point in
            LineMark(x: .value("Date", point.date), y: .value("BMI", point.value))
              .foregroundStyle(AppTheme.ink)
              .lineStyle(StrokeStyle(lineWidth: 2.2, lineJoin: .round))
          }
          if let last = chartPoints.last {
            PointMark(x: .value("Date", last.date), y: .value("BMI", last.value))
              .foregroundStyle(AppTheme.ink)
              .symbolSize(32)
          }
        }
        .chartXScale(domain: chartStart...chartEnd)
        .chartYScale(domain: chartDomain)
        .chartXAxis {
          AxisMarks(values: .stride(by: .day, count: 10)) { value in
            AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
              .font(.system(size: 9, design: .monospaced))
              .foregroundStyle(.secondary)
          }
        }
        .chartYAxis {
          AxisMarks(position: .leading) { value in
            AxisGridLine().foregroundStyle(AppTheme.stroke.opacity(0.7))
            AxisValueLabel().font(.system(size: 9)).foregroundStyle(.secondary)
          }
        }
        .chartLegend(.hidden)
        .frame(minHeight: 215)
        .padding(.top, 10)
      }

      Divider().padding(.vertical, 12)
      HStack {
        metric("Start", chartPoints.first.map { String(format: "%.1f", $0.value) } ?? "—")
        Spacer()
        metric("Now", bmi > 0 ? String(format: "%.1f", bmi) : "—")
        Spacer()
        metric("Healthy since", healthySinceText)
      }
    }
    .padding(18)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.stroke))
  }

  private var healthyRangeCard: some View {
    let low = 18.5 * pow(height / 100, 2)
    let high = 24.9 * pow(height / 100, 2)
    return VStack(alignment: .leading, spacing: 0) {
      Text("Healthy range for \(height, specifier: "%.0f") cm")
        .font(.system(size: 14, weight: .semibold))
      HStack(alignment: .lastTextBaseline, spacing: 10) {
        Text(height > 1 ? "\(low, specifier: "%.1f") – \(high, specifier: "%.1f")" : "—")
          .font(.system(size: 34, weight: .bold))
          .tracking(-1)
        Text("kg").font(.system(size: 12)).foregroundStyle(.secondary)
      }
      .padding(.top, 18)
      Spacer()
      Text("BMI is a screening estimate — it doesn’t see muscle or body composition. Pair it with body-fat % for a fuller picture.")
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .lineSpacing(5)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(18)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.stroke))
  }

  private var heightEditor: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Edit height").font(.system(size: 20, weight: .bold))
      Text("Height is used to calculate BMI and your healthy weight range.")
        .font(.system(size: 12)).foregroundStyle(.secondary)
      HStack {
        TextField("Height", text: $heightText)
          .textFieldStyle(.roundedBorder)
          .onSubmit(saveHeight)
        Text("cm").foregroundStyle(.secondary)
      }
      if let heightError {
        Text(heightError).font(.system(size: 11)).foregroundStyle(.red)
      }
      HStack {
        Spacer()
        Button("Cancel") { isEditingHeight = false }
        Button("Save", action: saveHeight)
          .buttonStyle(.borderedProminent)
          .tint(AppTheme.ink)
      }
    }
    .padding(24)
    .frame(width: 380)
  }

  private var category: BMICategory {
    switch bmi {
    case ..<18.5: return .underweight
    case ..<25: return .healthy
    case ..<30: return .overweight
    default: return .obese
    }
  }
  private var chartStart: Date {
    Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
  }
  private var chartEnd: Date { .now }
  private var chartDomain: ClosedRange<Double> {
    let values = chartPoints.map(\.value) + [18.5, 25]
    let low = floor((values.min() ?? 18.5) - 0.5)
    let high = ceil((values.max() ?? 25) + 0.5)
    return low...max(low + 2, high)
  }
  private var changeText: String {
    guard let first = chartPoints.first else { return "—" }
    return String(format: "%+.1f", bmi - first.value)
  }
  private var healthySinceText: String {
    let healthy = chartPoints.filter { (18.5..<25).contains($0.value) }
    guard let first = healthy.first else { return "Not yet" }
    return first.date.formatted(.dateTime.day().month(.abbreviated))
  }

  private func markerPosition(for value: Double, width: CGFloat) -> CGFloat {
    let clamped = min(max(value, 15), 40)
    return width * CGFloat((clamped - 15) / 25)
  }
  private func scaleLabel(_ title: String, _ detail: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
      Text(detail).font(.system(size: 10, design: .monospaced))
    }
    .font(.system(size: 11)).foregroundStyle(.secondary)
  }
  private func metric(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
      Text(value).font(.system(size: 15, weight: .semibold))
    }
  }
  private func saveHeight() {
    let normalized = heightText.replacingOccurrences(of: ",", with: ".")
    guard let value = Double(normalized), (100...250).contains(value) else {
      heightError = "Enter a height between 100 and 250 cm."
      return
    }
    guard let profile else {
      heightError = "Profile is unavailable."
      return
    }
    profile.heightCentimeters = value
    try? modelContext.save()
    isEditingHeight = false
  }
  private static func bmi(weight: Double, height: Double) -> Double {
    guard weight > 0, height > 0 else { return 0 }
    return weight / pow(height / 100, 2)
  }
}

private struct BMIPoint: Identifiable {
  let date: Date
  let value: Double
  var id: Date { date }
    
}

private enum BMICategory {
  case underweight, healthy, overweight, obese

  var title: String {
    switch self {
    case .underweight: "Under"
    case .healthy: "Healthy"
    case .overweight: "Over"
    case .obese: "Obese"
    }
  }
  var color: Color {
    switch self {
    case .underweight: Color(red: 0.39, green: 0.67, blue: 0.94)
    case .healthy: AppTheme.lime
    case .overweight: Color(red: 1.0, green: 0.72, blue: 0.34)
    case .obese: Color(red: 1.0, green: 0.43, blue: 0.36)
    }
  }
}

#Preview {
  BMIView()
    .frame(width: 768, height: 600)
    .modelContainer(for: [WeightProfile.self, WeightEntry.self], inMemory: true)
}

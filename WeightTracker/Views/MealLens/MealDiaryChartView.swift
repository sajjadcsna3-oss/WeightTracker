import Charts
import SwiftUI

struct DailyCaloriePoint: Identifiable {
  let date: Date
  let calories: Double
  let isRecorded: Bool
  var id: Date { date }
}

struct MealDiaryChartView: View {
  let points: [DailyCaloriePoint]
  let target: Double

  private var recordedPoints: [DailyCaloriePoint] { points.filter(\.isRecorded) }
  private var atOrBelowCount: Int { recordedPoints.filter { $0.calories <= target }.count }
  private var overCount: Int { recordedPoints.filter { $0.calories > target }.count }
  private var chartMaximum: Double {
    max(target, recordedPoints.map(\.calories).max() ?? 0) * 1.08
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Last 14 days").font(.system(size: 13, weight: .semibold))
        Spacer()
        Text(recordedPoints.isEmpty ? "NO DATA" : "AVG \(Int(recordedPoints.map(\.calories).reduce(0,+) / Double(recordedPoints.count))) KCAL")
          .font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
      }
      if recordedPoints.isEmpty {
        ContentUnavailableView("No calorie history", systemImage: "chart.bar", description: Text("Saved meals will build this chart."))
          .frame(height: 130)
      } else {
        Chart {
          ForEach(points) { point in
            if point.isRecorded {
              BarMark(x: .value("Day", point.date, unit: .day), y: .value("Calories", point.calories))
                .foregroundStyle(point.calories > target ? Color(red: 1, green: 0.48, blue: 0.36) : AppTheme.ink.opacity(0.84))
                .cornerRadius(3)
            } else {
              PointMark(x: .value("Day", point.date, unit: .day), y: .value("Calories", 0))
                .symbol { Capsule().fill(AppTheme.stroke).frame(width: 11, height: 3) }
            }
          }
          RuleMark(y: .value("Target", target))
            .foregroundStyle(AppTheme.violet.opacity(0.65))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
          RuleMark(y: .value("Mid grid", target * 0.5))
            .foregroundStyle(AppTheme.stroke.opacity(0.7))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
        }
        .chartYScale(domain: 0...chartMaximum)
        .chartXScale(range: .plotDimension(padding: 6))
        .chartXAxis(.hidden).chartYAxis(.hidden).chartLegend(.hidden).frame(height: 135)
      }
      HStack {
        Label("At/below · \(atOrBelowCount)", systemImage: "square.fill").foregroundStyle(AppTheme.ink)
        Spacer()
        Label("Over · \(overCount)", systemImage: "square.fill").foregroundStyle(Color(red: 1, green: 0.48, blue: 0.36))
      }.font(.system(size: 9)).symbolRenderingMode(.monochrome)
    }
    .padding(16).background(.white, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.stroke))
  }
}

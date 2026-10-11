import Charts
import SwiftUI

struct DailyCaloriePoint: Identifiable {
  let date: Date
  let calories: Double
  var id: Date { date }
}

struct MealDiaryChartView: View {
  let points: [DailyCaloriePoint]
  let target: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Last 14 days").font(.system(size: 13, weight: .semibold))
        Spacer()
        let recorded = points.filter { $0.calories > 0 }
        Text(recorded.isEmpty ? "NO DATA" : "AVG \(Int(recorded.map(\.calories).reduce(0,+) / Double(recorded.count))) KCAL")
          .font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
      }
      if points.allSatisfy({ $0.calories == 0 }) {
        ContentUnavailableView("No calorie history", systemImage: "chart.bar", description: Text("Saved meals will build this chart."))
          .frame(height: 130)
      } else {
        Chart(points) { point in
          BarMark(x: .value("Day", point.date, unit: .day), y: .value("Calories", point.calories))
            .foregroundStyle(point.calories > target ? Color(red: 1, green: 0.48, blue: 0.36) : AppTheme.ink.opacity(0.84))
            .cornerRadius(3)
          RuleMark(y: .value("Target", target)).foregroundStyle(AppTheme.violet.opacity(0.5)).lineStyle(StrokeStyle(dash: [3]))
        }
        .chartXAxis(.hidden).chartYAxis(.hidden).chartLegend(.hidden).frame(height: 135)
      }
      HStack {
        Label("At/below budget", systemImage: "square.fill").foregroundStyle(AppTheme.ink)
        Spacer()
        Label("Over", systemImage: "square.fill").foregroundStyle(Color(red: 1, green: 0.48, blue: 0.36))
      }.font(.system(size: 9)).symbolRenderingMode(.monochrome)
    }
    .padding(16).background(.white, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.stroke))
  }
}

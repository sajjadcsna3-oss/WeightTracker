
//
//  WeightChartView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//
import SwiftUI
import Charts
struct WeightChartView: View {
  let entries: [WeightEntry]
  let startWeight: Double

  private var ordered: [WeightEntry] { entries.sorted { $0.date < $1.date } }
  private var limits: ClosedRange<Double> {
    let values = ordered.map(\.kilograms)
    let low = min(values.min() ?? startWeight, startWeight) - 0.8
    let high = max(values.max() ?? startWeight, startWeight) + 0.8
    return low...max(low + 2, high)
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 13) {
      HStack {
        Text("Last 30 days").font(.system(size: 14, weight: .semibold))
        Spacer()
        HStack(spacing: 6) {
          Rectangle().fill(AppTheme.ink).frame(width: 12, height: 2)
          Text("Weight")
          Text("  ---  7-day avg")
        }.font(.system(size: 10)).foregroundStyle(.secondary)
      }
      if ordered.isEmpty {
        ContentUnavailableView(
          "No weight entries", systemImage: "chart.xyaxis.line",
          description: Text("Log your first weight to see a real chart.")
        )
        .frame(height: 178)
      } else {
        Chart {
          ForEach(ordered) { entry in
            AreaMark(
              x: .value("Date", entry.date),
              yStart: .value("Base", limits.lowerBound),
              yEnd: .value("Weight", entry.kilograms)
            )
            .foregroundStyle(AppTheme.lime.opacity(0.32))
            LineMark(
              x: .value("Date", entry.date),
              y: .value("Weight", entry.kilograms)
            )
            .foregroundStyle(AppTheme.ink).lineStyle(StrokeStyle(lineWidth: 2.2))
            LineMark(
              x: .value("Date", entry.date),
              y: .value("7-day average", WeightMath.rollingAverage(for: entry, records: ordered)),
              series: .value("Series", "Rolling average")
            )
            .foregroundStyle(.gray).lineStyle(StrokeStyle(lineWidth: 1.3, dash: [4, 4]))
          }
          if let last = ordered.last {
            PointMark(x: .value("Date", last.date), y: .value("Latest", last.kilograms))
              .foregroundStyle(AppTheme.lime).symbolSize(95)
          }
        }
        .chartYScale(domain: limits)
        .chartLegend(.hidden)
        .frame(height: 178)
      }
      Divider()
      HStack {
        summary("START", String(format: "%.1f", startWeight))
        Spacer()
        let change = (ordered.last?.kilograms ?? startWeight) - startWeight
        summary("CHANGE", String(format: "%+.1f", change))
        Spacer()
        let average = ordered.suffix(7).map(\.kilograms)
        summary(
          "7-DAY AVG",
          average.isEmpty
            ? "—" : String(format: "%.1f", average.reduce(0, +) / Double(average.count)))
        Spacer()
        summary("LOGGED", "\(ordered.count)")
      }
    }
    .padding(18).frame(height: 300)
    .background(.white).clipShape(RoundedRectangle(cornerRadius: 19))
    .overlay(RoundedRectangle(cornerRadius: 19).stroke(AppTheme.stroke))
  }
  private func summary(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
      Text(value).font(.system(size: 14, weight: .semibold))
    }
  }
}

#Preview {
  WeightChartView(
    entries: [
      WeightEntry(date: .now.addingTimeInterval(-172_800), kilograms: 82.4),
      WeightEntry(date: .now.addingTimeInterval(-86_400), kilograms: 81.9),
      WeightEntry(date: .now, kilograms: 81.5),
    ],
    startWeight: 82.4
  )
  .padding()
  .frame(width: 720)
  .background(AppTheme.background)
}

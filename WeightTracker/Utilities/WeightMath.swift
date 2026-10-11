//
//  WeightMath.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import Foundation

enum WeightMath {
  static func progress(start: Double, current: Double, goal: Double) -> Double {
    let distance = goal - start
    guard abs(distance) > 0.0001 else { return abs(current - goal) < 0.05 ? 1 : 0 }
    return min(1, max(0, (current - start) / distance))
  }

  // Linear regression over actual elapsed days, not a fixed rate or hard-coded date.
  static func weeklyRate(_ records: [WeightEntry]) -> Double? {
    let records = records.sorted { $0.date < $1.date }
    guard records.count >= 2, let first = records.first else { return nil }
    let xs = records.map { $0.date.timeIntervalSince(first.date) / 86400 }
    let ys = records.map(\.kilograms)
    let mx = xs.reduce(0, +) / Double(xs.count)
    let my = ys.reduce(0, +) / Double(ys.count)
    let denom = xs.reduce(0) { $0 + pow($1 - mx, 2) }
    guard denom > 0.0001 else { return nil }
    let numerator = zip(xs, ys).reduce(0.0) { $0 + ($1.0 - mx) * ($1.1 - my) }
    return numerator / denom * 7
  }

  static func goalDate(current: Double, goal: Double, weeklyRate: Double?, from date: Date) -> Date?
  {
    guard let rate = weeklyRate, abs(rate) > 0.01 else { return nil }
    let weeks = (goal - current) / rate
    guard weeks > 0, weeks <= 104 else { return nil }
    return date.addingTimeInterval(weeks * 7 * 86400)
  }

  static func rollingAverage(for entry: WeightEntry, records: [WeightEntry]) -> Double {
    let start = entry.date.addingTimeInterval(-7 * 86400)
    let recent = records.filter { $0.date <= entry.date && $0.date > start }
    guard !recent.isEmpty else { return entry.kilograms }
    return recent.map(\.kilograms).reduce(0, +) / Double(recent.count)
  }

  static func average(_ records: [WeightEntry], duringLastDays days: Int? = nil) -> Double? {
    guard !records.isEmpty else { return nil }
    let sorted = records.sorted { $0.date < $1.date }
    let selected: [WeightEntry]
    if let days, let end = sorted.last?.date,
      let start = Calendar.current.date(byAdding: .day, value: -days, to: end)
    {
      selected = sorted.filter { $0.date >= start }
    } else {
      selected = sorted
    }
    guard !selected.isEmpty else { return nil }
    return selected.map(\.kilograms).reduce(0, +) / Double(selected.count)
  }

  static func averageDailySwing(_ records: [WeightEntry]) -> Double? {
    let sorted = records.sorted { $0.date < $1.date }
    guard sorted.count > 1 else { return nil }
    let changes = zip(sorted.dropFirst(), sorted).map {
      abs($0.0.kilograms - $0.1.kilograms)
    }
    return changes.reduce(0, +) / Double(changes.count)
  }

  static func streak(_ records: [WeightEntry], today: Date = .now) -> Int {
    let calendar = Calendar.current
    let days = Set(records.map { calendar.startOfDay(for: $0.date) })
    var cursor = calendar.startOfDay(for: today)
    if !days.contains(cursor) { cursor = calendar.date(byAdding: .day, value: -1, to: cursor)! }
    var count = 0
    while days.contains(cursor) {
      count += 1
      guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
      cursor = previous
    }
    return count
  }
}

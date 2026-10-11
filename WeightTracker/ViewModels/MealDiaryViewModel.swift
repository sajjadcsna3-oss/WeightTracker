import Foundation
import Observation

enum DiaryRange: String, CaseIterable, Identifiable { case week = "Week", month = "Month"; var id: String { rawValue } }

@MainActor @Observable
final class MealDiaryViewModel {
  var range: DiaryRange = .week
  var selectedDate = Calendar.current.startOfDay(for: .now)
  var anchorDate = Calendar.current.startOfDay(for: .now)

  var visibleDays: [Date] {
    let calendar = Calendar.current
    if range == .week {
      let interval = calendar.dateInterval(of: .weekOfYear, for: anchorDate)
      return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval?.start ?? anchorDate) }
    }
    let interval = calendar.dateInterval(of: .month, for: anchorDate)
    let days = calendar.range(of: .day, in: .month, for: anchorDate)?.count ?? 30
    return (0..<days).compactMap { calendar.date(byAdding: .day, value: $0, to: interval?.start ?? anchorDate) }
  }

  var rangeTitle: String {
    guard let first = visibleDays.first, let last = visibleDays.last else { return "" }
    if range == .month { return anchorDate.formatted(.dateTime.month(.wide).year()) }
    return "\(first.formatted(.dateTime.day().month(.abbreviated))) – \(last.formatted(.dateTime.day().month(.abbreviated)))"
  }

  func move(_ direction: Int) {
    let component: Calendar.Component = range == .week ? .weekOfYear : .month
    anchorDate = Calendar.current.date(byAdding: component, value: direction, to: anchorDate) ?? anchorDate
    if let closest = visibleDays.min(by: { abs($0.timeIntervalSince(selectedDate)) < abs($1.timeIntervalSince(selectedDate)) }) { selectedDate = closest }
  }

  func meals(on date: Date, from meals: [MealEntry]) -> [MealEntry] {
    meals.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.sorted { $0.date < $1.date }
  }

  func calories(on date: Date, from allMeals: [MealEntry]) -> Double { meals(on: date, from: allMeals).reduce(0) { $0 + $1.calories } }
}

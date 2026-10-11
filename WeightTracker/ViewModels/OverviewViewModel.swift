import Combine
import Foundation
import SwiftData

@MainActor
final class OverviewViewModel: ObservableObject {
  @Published var showLogSheet = false
  @Published var showGoalSheet = false
  @Published var selectedPage = "Overview"

  func save(
    kilograms: Double, date: Date, bodyFat: Double?, note: String,
    existing: WeightEntry?, context: ModelContext
  ) throws {
    guard kilograms >= 20 && kilograms <= 500 else { throw EntryError.invalidWeight }
    if let bodyFat, !(1...75).contains(bodyFat) { throw EntryError.invalidBodyFat }
    guard date <= Date().addingTimeInterval(60) else { throw EntryError.futureDate }
    if let existing {
      existing.kilograms = kilograms
      existing.date = date
      existing.bodyFatPercent = bodyFat
      existing.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
      context.insert(
        WeightEntry(
          date: date, kilograms: kilograms,
          bodyFatPercent: bodyFat,
          note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
    }
    try context.save()
  }

  enum EntryError: LocalizedError {
    case invalidWeight, invalidBodyFat, futureDate
    var errorDescription: String? {
      switch self {
      case .invalidWeight: return "Enter a weight between 20 and 500 kg."
      case .invalidBodyFat: return "Body fat must be between 1 and 75%."
      case .futureDate: return "You cannot log a future time."
      }
    }
  }
}

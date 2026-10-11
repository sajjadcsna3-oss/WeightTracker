//
//  OnboardingViewModel.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import Combine
import SwiftData
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
  @Published var step = 0
  @Published var displayName = ""
  @Published var imperial = false
  @Published var height = "178"
  @Published var age = "31"
  @Published var weight = "82.4"
  @Published var goal = "70.0"
  @Published var pace = 0.5
  @Published var touchID = false
  @Published var reminder = false
  @Published var healthSync = true
  @Published var cloudSync = true
  @Published var error: String?
  @Published private(set) var isFinishing = false

  var normalizedName: String {
    displayName.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var heightCM: Double? {
    guard let value = Double(height) else { return nil }
    return imperial ? value * 30.48 : value  // Imperial height entered in feet
  }
  var startingKG: Double? {
    guard let value = Double(weight) else { return nil }
    return imperial ? value * 0.45359237 : value
  }
  var goalKG: Double? {
    guard let value = Double(goal) else { return nil }
    return imperial ? value * 0.45359237 : value
  }
  var projectedDate: Date? {
    guard let a = startingKG, let b = goalKG, pace > 0 else { return nil }
    let weeks = abs(a - b) / pace
    guard weeks < 520 else { return nil }
    return Calendar.current.date(byAdding: .day, value: Int(ceil(weeks * 7)), to: .now)
  }
  func next() {
    error = nil
    if step == 1 {
      guard !normalizedName.isEmpty else {
        error = "Enter your name to continue."
        return
      }
      guard normalizedName.count <= 40,
        let h = heightCM, (100...250).contains(h),
        let a = Int(age), (13...120).contains(a),
        let w = startingKG, (20...500).contains(w)
      else {
        error =
          imperial
          ? "Enter height in feet, age and weight in pounds."
          : "Enter valid height, age and weight."
        return
      }
      if goal.isEmpty { goal = weight }
    }
    if step == 2 {
      guard let g = goalKG, (20...500).contains(g) else {
        error = "Enter a valid target weight."
        return
      }
    }
    step = min(step + 1, 3)
  }
  func back() {
    error = nil
    step = max(0, step - 1)
  }

  func finish(context: ModelContext) async -> Bool {
    guard !isFinishing else { return false }
    guard !normalizedName.isEmpty, normalizedName.count <= 40,
      let h = heightCM, let a = Int(age), let w = startingKG,
      let g = goalKG, (100...250).contains(h), (13...120).contains(a),
      (20...500).contains(w), (20...500).contains(g)
    else {
      error = "Please complete your profile first."
      return false
    }
    isFinishing = true
    defer { isFinishing = false }
    let descriptor = FetchDescriptor<WeightProfile>(
      sortBy: [SortDescriptor(\.createdAt)]
    )
    let profile: WeightProfile
    if let existingProfile = try? context.fetch(descriptor).first {
      profile = existingProfile
      profile.displayName = normalizedName
      profile.startingKilograms = w
      profile.goalKilograms = g
      profile.heightCentimeters = h
      profile.age = a
      profile.paceKilogramsPerWeek = pace
      profile.usesImperialUnits = imperial
      profile.onboardingComplete = true
    } else {
      profile = WeightProfile(
        displayName: normalizedName, startingKilograms: w,
        goalKilograms: g, heightCentimeters: h, age: a,
        paceKilogramsPerWeek: pace, usesImperialUnits: imperial)
      context.insert(profile)
    }
    profile.healthSyncEnabled = healthSync
    profile.cloudSyncEnabled = cloudSync
    profile.lockEnabled = false
    profile.reminderEnabled = false
    if touchID {
      guard AuthenticationService.isAvailable else {
        error = "Touch ID is unavailable on this Mac. Turn it off to continue."
        return false
      }
      guard await AuthenticationService.authenticate() else {
        error = "Touch ID authentication was not completed."
        return false
      }
      profile.lockEnabled = true
    }
    if reminder {
      profile.reminderEnabled = await ReminderService.enableMorningReminder()
      if !profile.reminderEnabled {
        error = "Notifications were not authorized. You can enable reminders later."
      }
    }
    let entries = (try? context.fetch(FetchDescriptor<WeightEntry>())) ?? []
    if entries.isEmpty {
      context.insert(WeightEntry(date: .now, kilograms: w))
    }
    do {
      try context.save()
      return true
    } catch {
      self.error = error.localizedDescription
      return false
    }
  }
}

//
//  WeightProfile.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import Foundation
import SwiftData

@Model
final class WeightProfile {
  var id: UUID = UUID()
  var displayName: String = ""
  var startingKilograms: Double = 0
  var goalKilograms: Double = 0
  var heightCentimeters: Double = 0
  var age: Int = 0
  var paceKilogramsPerWeek: Double = 0.5
  var usesImperialUnits: Bool = false
  var onboardingComplete: Bool = false
  var lockEnabled: Bool = false
  var reminderEnabled: Bool = false
  var healthSyncEnabled: Bool = true
  var cloudSyncEnabled: Bool = true
  var createdAt: Date = Date()

  init(
    displayName: String, startingKilograms: Double, goalKilograms: Double,
    heightCentimeters: Double, age: Int, paceKilogramsPerWeek: Double,
    usesImperialUnits: Bool = false
  ) {
    self.id = UUID()
    self.displayName = displayName
    self.startingKilograms = startingKilograms
    self.goalKilograms = goalKilograms
    self.heightCentimeters = heightCentimeters
    self.age = age
    self.paceKilogramsPerWeek = paceKilogramsPerWeek
    self.usesImperialUnits = usesImperialUnits
    self.onboardingComplete = true
    self.createdAt = .now
  }
}

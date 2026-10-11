
//
//  GoalSettingsSheet.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//
import SwiftUI
import SwiftData
struct GoalSettingsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  @Bindable var profile: WeightProfile
  @State private var error: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Weight goals")
        .font(.title2.bold())

      TextField("Display name", text: $profile.displayName)

      LabeledContent("Starting weight (kg)") {
        TextField("Start", value: $profile.startingKilograms, format: .number)
          .frame(width: 110)
      }

      LabeledContent("Goal weight (kg)") {
        TextField("Goal", value: $profile.goalKilograms, format: .number)
          .frame(width: 110)
      }

      LabeledContent("Height (cm)") {
        TextField("Height", value: $profile.heightCentimeters, format: .number)
          .frame(width: 110)
      }

      Text("Supports weight loss, gain, and maintenance.")
        .font(.caption)
        .foregroundStyle(.secondary)

      if let error {
        Text(error)
          .foregroundStyle(.red)
      }

      HStack {
        Spacer()
        Button("Done") {
          saveChanges()
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.ink)
      }
    }
    .padding(28)
    .frame(width: 390)
  }

  private func saveChanges() {
    let startIsValid = (20...500).contains(profile.startingKilograms)
    let goalIsValid = (20...500).contains(profile.goalKilograms)
    let heightIsValid = (100...250).contains(profile.heightCentimeters)

    guard startIsValid && goalIsValid && heightIsValid else {
      error = "Please enter realistic values."
      return
    }

    do {
      try context.save()
      dismiss()
    } catch {
      self.error = error.localizedDescription
    }
  }
}

#Preview {
  GoalSettingsSheet(
    profile: WeightProfile(
      displayName: "Alex",
      startingKilograms: 82.4,
      goalKilograms: 70,
      heightCentimeters: 178,
      age: 31,
      paceKilogramsPerWeek: 0.5
    )
  )
  .modelContainer(for: [WeightProfile.self, WeightEntry.self], inMemory: true)
}

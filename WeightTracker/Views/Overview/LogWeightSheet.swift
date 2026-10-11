import SwiftData
import SwiftUI

struct LogWeightSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  @State private var weight: Double
  @State private var date: Date
  @State private var bodyFat: String
  @State private var note: String
  @State private var errorMessage: String?
  @State private var selectedDay = "Today"
  let existing: WeightEntry?
  let save: (Double, Date, Double?, String, WeightEntry?, ModelContext) throws -> Void

  init(
    initialWeight: Double, existing: WeightEntry? = nil,
    save: @escaping (Double, Date, Double?, String, WeightEntry?, ModelContext) throws -> Void
  ) {
    self.existing = existing
    self.save = save
    _weight = State(initialValue: existing?.kilograms ?? initialWeight)
    _date = State(initialValue: existing?.date ?? .now)
    _bodyFat = State(initialValue: existing?.bodyFatPercent.map { String($0) } ?? "")
    _note = State(initialValue: existing?.note ?? "")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      header

      if selectedDay == "Pick" {
        DatePicker(
          "Date and time", selection: $date, in: ...Date(),
          displayedComponents: [.date, .hourAndMinute])
      }

      weightPicker

      Text("KG")
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)

      WeightRuler(weight: $weight)
      extraFields

      TextField("Add a note — after run, travel day...", text: $note)
        .textFieldStyle(.roundedBorder)

      mealLensNotice

      if let errorMessage {
        Text(errorMessage)
          .foregroundStyle(.red)
          .font(.caption)
      }

      actionButtons
    }
    .padding(28)
    .frame(width: 620)
    .background(AppTheme.background)
  }

  private var header: some View {
    HStack {
      Text(existing == nil ? "Log weight" : "Edit weight")
        .font(.system(size: 21, weight: .semibold))

      Spacer()

      ForEach(["Today", "Yesterday", "Pick"], id: \.self) { day in
        Button(day) {
          selectDay(day)
        }
        .buttonStyle(.borderedProminent)
        .tint(selectedDay == day ? AppTheme.ink : .gray.opacity(0.25))
      }
    }
  }

  private var weightPicker: some View {
    HStack(spacing: 26) {
      Button {
        decreaseWeight()
      } label: {
        Image(systemName: "minus")
          .frame(width: 30, height: 30)
      }

      Text(weight, format: .number.precision(.fractionLength(1)))
        .font(.system(size: 84, weight: .light))
        .monospacedDigit()

      Button {
        increaseWeight()
      } label: {
        Image(systemName: "plus")
          .frame(width: 30, height: 30)
      }
    }
    .buttonStyle(.bordered)
    .frame(maxWidth: .infinity)
  }

  private var extraFields: some View {
    HStack(spacing: 12) {
      HStack(spacing: 26) {
        Text("Time")
          .foregroundStyle(.secondary)
        Spacer()
        DatePicker("", selection: $date, in: ...Date(), displayedComponents: .hourAndMinute)
          .labelsHidden()
      }
      .padding(10)
      .background(.white)
      .cornerRadius(11)

      HStack {
        Text("Body fat")
          .foregroundStyle(.secondary)
        Spacer()
        TextField("Optional %", text: $bodyFat)
          .multilineTextAlignment(.trailing)
          .frame(width: 85)
      }
      .padding(10)
      .background(.white)
      .cornerRadius(11)
    }
    .font(.system(size: 12))
  }

  private var mealLensNotice: some View {
    HStack {
      Image(systemName: "camera")
        .foregroundStyle(AppTheme.violet)
      Text("Meal attachment requires Meal Lens (not implemented)")
        .font(.system(size: 12))
      Spacer()
      Text("PRO")
        .font(.system(size: 9, weight: .bold))
    }
    .padding(12)
    .background(AppTheme.violet.opacity(0.08))
    .cornerRadius(10)
  }

  private var actionButtons: some View {
    HStack {
      Spacer()

      Button("Cancel") {
        dismiss()
      }
      .buttonStyle(.plain)

      Button("Save") {
        saveWeight()
      }
      .buttonStyle(.borderedProminent)
      .tint(AppTheme.ink)
    }
  }

  private func selectDay(_ day: String) {
    selectedDay = day

    if day == "Today" {
      date = .now
    } else if day == "Yesterday" {
      date = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    }
  }

  private func decreaseWeight() {
    weight = max(20, (weight * 10 - 1).rounded() / 10)
  }

  private func increaseWeight() {
    weight = min(500, (weight * 10 + 1).rounded() / 10)
  }

  private func saveWeight() {
    let trimmedBodyFat = bodyFat.trimmingCharacters(in: .whitespaces)

    if !trimmedBodyFat.isEmpty && Double(trimmedBodyFat) == nil {
      errorMessage = "Enter a valid body-fat percentage."
      return
    }

    do {
      try save(weight, date, Double(trimmedBodyFat), note, existing, context)
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

#Preview {
  LogWeightSheet(initialWeight: 76.8) { _, _, _, _, _, _ in }
    .modelContainer(for: [WeightProfile.self, WeightEntry.self], inMemory: true)
}

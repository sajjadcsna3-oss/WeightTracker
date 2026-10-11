import AppKit
import SwiftData
import SwiftUI

struct AddMealSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query private var meals: [MealEntry]
  @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
  let viewModel: MealLensViewModel
  let dailyTarget: Double
  @State private var category: MealCategory = .lunch
  @State private var quantity = 1.0
  @State private var mealName = ""
  @State private var healthSave = false
  @State private var saving = false
  @State private var error: String?

  private var calories: Double { viewModel.calories * quantity }
  private var protein: Double { viewModel.protein * quantity }
  private var carbs: Double { viewModel.carbohydrates * quantity }
  private var fat: Double { viewModel.fat * quantity }
  private var todayBefore: Double { meals.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.calories } }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Text("MEAL LENS · CONFIRM").font(.system(size: 10, design: .monospaced)).foregroundStyle(AppTheme.violet)
          Text("Add \(category.rawValue.lowercased()) to today").font(.system(size: 22, weight: .bold))
        }
        Spacer()
        Text("PRO").font(.system(size: 9, weight: .bold)).padding(5).background(AppTheme.violet, in: RoundedRectangle(cornerRadius: 4))
      }
      mealSummary
      HStack(spacing: 12) { categoryPicker; portionPicker }
      HStack(spacing: 8) {
        macro("Protein", protein, Color.black)
        macro("Carbs", carbs, Color.black)
        macro("Fat", fat, Color.black)
      }
      budgetCard
      if HealthKitService.isAvailable {
        Toggle("Also save to Apple Health · Dietary Energy", isOn: $healthSave).toggleStyle(.switch)
      } else {
        Label("Apple Health dietary energy is unavailable on this Mac.", systemImage: "heart")
          .font(.system(size: 12)).foregroundStyle(.secondary)
      }
      Divider()
      HStack {
        Label("Saves to Diary · \(Date.now.formatted(date: .abbreviated, time: .omitted))", systemImage: "book")
          .font(.system(size: 11)).foregroundStyle(.secondary)
        Spacer()
        Button("Cancel") { dismiss() }.buttonStyle(.plain)
        Button(saving ? "Saving…" : "Add to today") { Task { await save() } }
          .buttonStyle(MealLensPrimaryButtonStyle()).disabled(saving || calories <= 0 || mealName.trimmingCharacters(in: .whitespaces).isEmpty)
      }
    }
    .padding(28).frame(width: 655)
    .background(AppTheme.background)
    .onAppear { if mealName.isEmpty { mealName = defaultName } }
    .alert("Couldn’t save meal", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
      Button("OK", role: .cancel) { error = nil }
    } message: { Text(error ?? "") }
  }

  private var defaultName: String {
    let names = viewModel.ingredients.prefix(3).map(\.name)
    return names.isEmpty ? "Meal" : names.joined(separator: " & ")
  }
  private var mealSummary: some View {
    HStack(spacing: 14) {
      Group {
        if let image = viewModel.image { Image(nsImage: image).resizable().scaledToFill() }
        else { Color.gray.opacity(0.12) }
      }.frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 12))
      VStack(alignment: .leading, spacing: 6) {
        TextField("Meal name", text: $mealName).textFieldStyle(.plain).font(.system(size: 15, weight: .semibold))
        Text(viewModel.ingredients.map(\.name).joined(separator: " · ")).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
      }
      Spacer()
      VStack(alignment: .trailing) { Text("\(Int(calories.rounded()))").font(.system(size: 26, weight: .semibold)); Text("KCAL").font(.system(size: 9)).foregroundStyle(.secondary) }
    }.padding(12).background(.white, in: RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.stroke))
  }
  private var categoryPicker: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text("Meal").font(.system(size: 11)).foregroundStyle(.secondary)
      Picker("Meal", selection: $category) { ForEach(MealCategory.allCases) { Text($0.shortTitle).tag($0) } }
        .pickerStyle(.segmented).labelsHidden()
    }.frame(maxWidth: .infinity)
  }
  private var portionPicker: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text("Portion").font(.system(size: 11)).foregroundStyle(.secondary)
      HStack {
        Button { quantity = max(0.25, quantity - 0.25) } label: {
          Text("−").frame(width: 28, height: 36).contentShape(Rectangle())
        }
        Spacer()
        Text("\(quantity.formatted(.number.precision(.fractionLength(0...2)))) serving")
        Spacer()
        Button { quantity = min(10, quantity + 0.25) } label: {
          Text("+").frame(width: 28, height: 36).contentShape(Rectangle())
        }
      }
        .buttonStyle(.plain).padding(.horizontal, 14).frame(height: 36).background(.white, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.stroke))
    }.frame(maxWidth: .infinity)
  }
  private func macro(_ label: String, _ value: Double, _ color: Color) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack { Text(label); Spacer(); Text("\(Int(value.rounded())) g").fontWeight(.semibold) }.font(.system(size: 11))
      GeometryReader { p in Capsule().fill(AppTheme.stroke); Capsule().fill(color).frame(width: p.size.width * min(value / 70, 1)) }.frame(height: 5)
    }.padding(11).frame(maxWidth: .infinity).background(.white, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.stroke))
  }
  private var budgetCard: some View {
    let after = todayBefore + calories
    return VStack(alignment: .leading, spacing: 10) {
      HStack { Text("Today’s estimated budget").fontWeight(.semibold); Spacer(); Text("\(Int(todayBefore)) → \(Int(after)) / \(Int(dailyTarget))").font(.system(size: 11, design: .monospaced)) }
      GeometryReader { p in ZStack(alignment: .leading) { Capsule().fill(AppTheme.violet.opacity(0.18)); Capsule().fill(after > dailyTarget ? Color.orange : AppTheme.violet).frame(width: p.size.width * min(after / dailyTarget, 1)) } }.frame(height: 9)
      Text(after <= dailyTarget ? "About \(Int(dailyTarget - after)) kcal remain in today’s estimate." : "About \(Int(after - dailyTarget)) kcal above today’s estimate. A single day does not predict tomorrow’s weight.")
        .font(.system(size: 12)).foregroundStyle(Color(red: 0.2, green: 0.16, blue: 0.48))
    }.padding(16).background(AppTheme.violet.opacity(0.09), in: RoundedRectangle(cornerRadius: 15))
  }

  @MainActor private func save() async {
    guard !saving else { return }
    saving = true
    defer { saving = false }
    do {
      let now = Date.now
      if meals.contains(where: { abs($0.createdAt.timeIntervalSince(now)) < 3 && $0.name == mealName }) { throw MealStorageError.duplicateMeal }
      let imageReference = try viewModel.image.map { try MealStorageService.storeImage($0) }
      let copiedItems = viewModel.ingredients.map {
        FoodItem(name: $0.name, grams: $0.grams * quantity, caloriesPer100Grams: $0.caloriesPer100Grams,
          proteinPer100Grams: $0.proteinPer100Grams, carbohydratesPer100Grams: $0.carbohydratesPer100Grams,
          fatPer100Grams: $0.fatPer100Grams, recognitionConfidence: $0.recognitionConfidence)
      }
      let meal = MealEntry(name: mealName.trimmingCharacters(in: .whitespacesAndNewlines), date: now, category: category,
        servingQuantity: quantity, calories: calories, protein: protein, carbohydrates: carbs, fat: fat,
        imageReference: imageReference, ingredients: copiedItems)
      modelContext.insert(meal)
      try modelContext.save()
      if healthSave { try await HealthKitService.save(kilocalories: calories, date: now) }
      dismiss()
    } catch let saveError { error = saveError.localizedDescription }
  }
}

import AppKit
import SwiftData
import SwiftUI

struct MealDiaryView: View {
  @Binding var destination: MealLensDestination
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \MealEntry.date, order: .reverse) private var meals: [MealEntry]
  @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
  @Query private var profiles: [WeightProfile]
  @State private var viewModel = MealDiaryViewModel()
  @State private var editingMeal: MealEntry?
  @State private var errorMessage: String?

  private var target: Double { CalorieBudgetService.estimatedTarget(profile: profiles.first, latestWeight: weights.last?.kilograms) }
  private var selectedMeals: [MealEntry] { viewModel.meals(on: viewModel.selectedDate, from: meals) }
  private var selectedCalories: Double { selectedMeals.reduce(0) { $0 + $1.calories } }
  private var protein: Double { selectedMeals.reduce(0) { $0 + $1.protein } }
  private var carbs: Double { selectedMeals.reduce(0) { $0 + $1.carbohydrates } }
  private var fat: Double { selectedMeals.reduce(0) { $0 + $1.fat } }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      header
      dayStrip
      GeometryReader { proxy in
        let compact = proxy.size.width < 760
        if compact {
          ScrollView { VStack(spacing: 14) { mealList.frame(minHeight: 360); summaryColumn } }
        } else {
          HStack(alignment: .top, spacing: 14) { mealList; summaryColumn.frame(width: min(290, proxy.size.width * 0.36)) }
        }
      }
    }
    .padding(.horizontal, 28).padding(.top, 24).padding(.bottom, 22).background(AppTheme.background)
    .sheet(item: $editingMeal) { meal in MealEditorSheet(meal: meal) }
    .alert("Diary", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(errorMessage ?? "") }
  }

  private var header: some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading, spacing: 5) {
        Text("MEAL LENS · DIARY").font(.system(size: 10, design: .monospaced)).foregroundStyle(AppTheme.violet)
        HStack { Text("Meal Log").font(.system(size: 27, weight: .bold)); Text("PRO").font(.system(size: 9, weight: .bold)).padding(5).background(AppTheme.violet, in: RoundedRectangle(cornerRadius: 5)) }
      }
      Spacer()
      Picker("", selection: $destination) { Label("Scan", systemImage: "camera").tag(MealLensDestination.scan); Label("Diary", systemImage: "book").tag(MealLensDestination.diary) }
        .pickerStyle(.segmented).labelsHidden().frame(width: 170)
      Spacer()
      Picker("", selection: $viewModel.range) { ForEach(DiaryRange.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented).labelsHidden().frame(width: 135)
      HStack { Button { viewModel.move(-1) } label: { Image(systemName: "chevron.left") }; Text(viewModel.rangeTitle).frame(minWidth: 95); Button { viewModel.move(1) } label: { Image(systemName: "chevron.right") } }
        .buttonStyle(.plain).font(.system(size: 11)).padding(.horizontal, 12).frame(height: 36).background(.white, in: RoundedRectangle(cornerRadius: 11)).overlay(RoundedRectangle(cornerRadius: 11).stroke(AppTheme.stroke))
    }
  }

  private var dayStrip: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(viewModel.visibleDays, id: \.self) { day in
          let selected = Calendar.current.isDate(day, inSameDayAs: viewModel.selectedDate)
          let calories = viewModel.calories(on: day, from: meals)
          Button { viewModel.selectedDate = day } label: {
            VStack(alignment: .leading, spacing: 7) {
              HStack { Text(day.formatted(.dateTime.weekday(.abbreviated))); Spacer(); Text(day.formatted(.dateTime.day())).fontWeight(.semibold) }
              Text(calories > 0 ? "\(Int(calories))" : "—").font(.system(size: 14, weight: .semibold)) + Text(calories > 0 ? " kcal" : "").font(.system(size: 8))
              Text(calories == 0 ? "No meals" : calories <= target ? "\(Int(target - calories)) left" : "\(Int(calories - target)) over")
                .font(.system(size: 9, weight: .semibold)).padding(.horizontal, 7).padding(.vertical, 3)
                .background(calories > target ? Color.orange.opacity(0.3) : AppTheme.lime.opacity(0.55), in: Capsule())
            }.padding(11).frame(width: 110, height: 86, alignment: .leading)
              .foregroundStyle(selected ? Color.white : AppTheme.ink)
              .background(selected ? AppTheme.ink : Color.white, in: RoundedRectangle(cornerRadius: 14))
              .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.stroke))
              .contentShape(Rectangle())
          }.buttonStyle(.plain)
        }
      }
    }
  }

  private var mealList: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(viewModel.selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide))).font(.system(size: 14, weight: .semibold))
        Spacer(); Button { destination = .scan } label: { Label("Add meal", systemImage: "camera") }.buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(.secondary)
      }.padding(.bottom, 10)
      Divider()
      if selectedMeals.isEmpty {
        ContentUnavailableView("No meals on this day", systemImage: "fork.knife", description: Text("Scan a photo or add ingredients manually."))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(spacing: 0) { ForEach(selectedMeals) { mealRow($0); Divider() } }
        }
      }
    }.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.stroke))
  }

  private func mealRow(_ meal: MealEntry) -> some View {
    HStack(spacing: 13) {
      Group {
        if let image = MealStorageService.image(at: meal.imageReference) { Image(nsImage: image).resizable().scaledToFill() }
        else { ZStack { Color.gray.opacity(0.12); Image(systemName: "fork.knife").foregroundStyle(.secondary) } }
      }.frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 11))
      VStack(alignment: .leading, spacing: 5) {
        HStack { Text(meal.category.rawValue).font(.system(size: 14, weight: .semibold)); Text(meal.date.formatted(date: .omitted, time: .shortened)).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary) }
        Text(meal.name).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
        Text(meal.ingredients.map(\.name).joined(separator: " · ")).font(.system(size: 10)).foregroundStyle(AppTheme.violet).lineLimit(1)
      }
      Spacer(); Text("\(Int(meal.calories))").font(.system(size: 18, weight: .semibold)); Text("kcal").font(.system(size: 9)).foregroundStyle(.secondary)
      Menu { Button("Edit") { editingMeal = meal }; Button("Delete", role: .destructive) { delete(meal) } } label: { Image(systemName: "ellipsis").frame(width: 20) }.menuStyle(.borderlessButton).menuIndicator(.hidden)
    }.padding(.vertical, 9)
  }

  private var summaryColumn: some View {
    VStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .firstTextBaseline) { Text("\(Int(selectedCalories))").font(.system(size: 26, weight: .bold)); Spacer(); Text("/ \(Int(target)) KCAL EST.").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary) }
        GeometryReader { p in ZStack(alignment: .leading) { Capsule().fill(AppTheme.stroke); Capsule().fill(selectedCalories > target ? Color.orange : AppTheme.ink).frame(width: p.size.width * min(selectedCalories / target, 1)) } }.frame(height: 8)
        HStack { Text("P \(Int(protein))g"); Spacer(); Text("C \(Int(carbs))g"); Spacer(); Text("F \(Int(fat))g") }.font(.system(size: 10)).foregroundStyle(.secondary)
        Divider(); Text(selectedCalories <= target ? "\(Int(target - selectedCalories)) kcal remaining" : "\(Int(selectedCalories - target)) kcal over estimate").font(.system(size: 12))
      }.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.stroke))
      insightCard
      MealDiaryChartView(points: chartPoints, target: target)
    }
  }

  private var chartPoints: [DailyCaloriePoint] {
    (0..<14).reversed().compactMap { offset in
      Calendar.current.date(byAdding: .day, value: -offset, to: Calendar.current.startOfDay(for: .now)).map { day in
        let dayMeals = viewModel.meals(on: day, from: meals)
        return DailyCaloriePoint(
          date: day,
          calories: dayMeals.reduce(0) { $0 + $1.calories },
          isRecorded: !dayMeals.isEmpty
        )
      }
    }
  }
  private var insightCard: some View {
    let recorded = chartPoints.filter(\.isRecorded)
    let avg = recorded.isEmpty ? 0 : recorded.map(\.calories).reduce(0,+) / Double(recorded.count)
    return VStack(alignment: .leading, spacing: 9) {
      Label("Nutrition insight", systemImage: "sparkles").font(.system(size: 13, weight: .semibold))
      Text(recorded.isEmpty ? "Save meals to see calorie and macro summaries based on your records." : "Across \(recorded.count) recorded day\(recorded.count == 1 ? "" : "s"), intake averages \(Int(avg)) kcal. Compare this with your multi-week weight trend; this is an estimate, not a weight prediction.")
        .font(.system(size: 11)).lineSpacing(3)
    }.padding(16).foregroundStyle(Color(red: 0.18, green: 0.14, blue: 0.46)).frame(maxWidth: .infinity, alignment: .leading).background(AppTheme.violet.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
  }
  private func delete(_ meal: MealEntry) { do { try MealStorageService.delete(meal, from: modelContext) } catch { errorMessage = error.localizedDescription } }
}

private struct MealEditorSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Bindable var meal: MealEntry
  @State private var error: String?
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Edit meal").font(.title2.bold())
      TextField("Meal name", text: $meal.name).textFieldStyle(.roundedBorder)
      DatePicker("Date and time", selection: $meal.date)
      Picker("Category", selection: $meal.categoryRawValue) { ForEach(MealCategory.allCases) { Text($0.rawValue).tag($0.rawValue) } }.pickerStyle(.segmented)
      Text("Ingredients and portions").font(.headline)
      List { ForEach(meal.ingredients) { item in HStack { Text(item.name); Spacer(); TextField("g", value: Bindable(item).grams, format: .number).frame(width: 70); Text("g") } } }.frame(height: 180)
      HStack { Spacer(); Button("Cancel") { modelContext.rollback(); dismiss() }; Button("Save") { save() }.buttonStyle(.borderedProminent) }
    }.padding(24).frame(width: 520)
      .alert("Couldn’t save", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") {} } message: { Text(error ?? "") }
  }
  private func save() {
    meal.calories = meal.ingredients.reduce(0) { $0 + $1.calories }; meal.protein = meal.ingredients.reduce(0) { $0 + $1.protein }
    meal.carbohydrates = meal.ingredients.reduce(0) { $0 + $1.carbohydrates }; meal.fat = meal.ingredients.reduce(0) { $0 + $1.fat }
    do { try modelContext.save(); dismiss() } catch let saveError { error = saveError.localizedDescription }
  }
}

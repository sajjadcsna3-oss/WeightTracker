import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum MealLensDestination: String, CaseIterable, Identifiable {
  case scan = "Scan"
  case diary = "Diary"
  var id: String { rawValue }
}

struct MealLensView: View {
  @Binding var destination: MealLensDestination
  @State private var viewModel = MealLensViewModel()
  @State private var choosingImage = false
  @State private var choosingIngredient = false
  @Query private var meals: [MealEntry]
  @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
  @Query private var profiles: [WeightProfile]

  private var todayCalories: Double {
    meals.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.calories }
  }
  private var target: Double {
    CalorieBudgetService.estimatedTarget(profile: profiles.first, latestWeight: weights.last?.kilograms)
  }

  var body: some View {
    Group {
      if destination == .scan { scanView } else { MealDiaryView(destination: $destination) }
    }
    .fileImporter(isPresented: $choosingImage, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
      if case .success(let urls) = result, let url = urls.first { viewModel.loadImage(from: url) }
      if case .failure(let error) = result { viewModel.errorMessage = error.localizedDescription }
    }
    .sheet(isPresented: $choosingIngredient) { IngredientPicker { viewModel.add($0) } }
    .sheet(isPresented: $viewModel.showingAddMeal) {
      AddMealSheet(viewModel: viewModel, dailyTarget: target)
    }
    .alert("Meal Lens", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
      Button("OK", role: .cancel) { viewModel.errorMessage = nil }
    } message: { Text(viewModel.errorMessage ?? "") }
  }

  private var scanView: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      GeometryReader { proxy in
        let compact = proxy.size.width < 760
        Group {
          if compact {
            ScrollView {
              VStack(spacing: 14) {
                imagePanel.frame(height: 390)
                detailsPanel.frame(minHeight: 390)
              }
            }
          } else {
            HStack(alignment: .top, spacing: 16) {
              imagePanel.frame(minWidth: 360).frame(maxWidth: .infinity)
              detailsPanel.frame(width: min(415, proxy.size.width * 0.46))
            }
          }
        }
      }
    }
    .padding(.horizontal, 28).padding(.top, 24).padding(.bottom, 22)
    .background(AppTheme.background)
  }

  private var header: some View {
    HStack(alignment: .bottom, spacing: 18) {
      VStack(alignment: .leading, spacing: 5) {
        Text("MEAL LENS · \(MealCategory.lunch.rawValue.uppercased()) · \(Date.now.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 10, design: .monospaced)).foregroundStyle(AppTheme.violet)
        HStack(spacing: 10) {
          Text("Meal Lens").font(.system(size: 27, weight: .bold))
          Text("PRO").font(.system(size: 9, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 4)
            .background(AppTheme.violet, in: RoundedRectangle(cornerRadius: 5))
        }
      }
      Spacer()
      destinationPicker
      Spacer()
      Button { choosingImage = true } label: { Label(viewModel.image == nil ? "Choose photo" : "Retake", systemImage: "arrow.clockwise") }
        .buttonStyle(MealLensOutlineButtonStyle())
      Button { viewModel.showingAddMeal = true } label: { Label("Add to today", systemImage: "plus") }
        .buttonStyle(MealLensPrimaryButtonStyle()).disabled(!viewModel.canSave)
    }
  }

  private var destinationPicker: some View {
    Picker("", selection: $destination) {
      Label("Scan", systemImage: "camera").tag(MealLensDestination.scan)
      Label("Diary", systemImage: "book").tag(MealLensDestination.diary)
    }.pickerStyle(.segmented).labelsHidden().frame(width: 170)
  }

  private var imagePanel: some View {
    VStack(spacing: 12) {
      MealImageView(image: viewModel.image, detections: viewModel.detections)
      Button { choosingImage = true } label: {
        Label(viewModel.image == nil ? "Select image" : "Replace image", systemImage: "photo.badge.plus")
          .frame(maxWidth: .infinity, minHeight: 42)
      }.buttonStyle(.plain).background(.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(style: StrokeStyle(lineWidth: 1, dash: [4])))
    }
  }

  private var detailsPanel: some View {
    VStack(spacing: 14) {
      DetectedFoodListView(ingredients: viewModel.ingredients, state: viewModel.state,
        onAdd: { choosingIngredient = true }, onDelete: viewModel.remove)
      nutritionTotal
      WeightImpactCard(consumed: todayCalories + viewModel.calories, target: target, protein: viewModel.protein)
    }
  }

  private var nutritionTotal: some View {
    HStack {
      Text("Total · P \(Int(viewModel.protein))g · C \(Int(viewModel.carbohydrates))g · F \(Int(viewModel.fat))g")
        .font(.system(size: 12)).foregroundStyle(.secondary)
      Spacer()
      Text("\(Int(viewModel.calories.rounded()))").font(.system(size: 23, weight: .semibold))
      Text("kcal").font(.system(size: 9)).foregroundStyle(.secondary)
    }.padding(16).background(.white, in: RoundedRectangle(cornerRadius: 14))
      .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.stroke))
  }
}

struct MealLensOutlineButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(.system(size: 12, weight: .medium)).padding(.horizontal, 15).frame(height: 38)
      .background(.white.opacity(configuration.isPressed ? 0.6 : 1), in: RoundedRectangle(cornerRadius: 11))
      .overlay(RoundedRectangle(cornerRadius: 11).stroke(AppTheme.stroke))
  }
}

struct MealLensPrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(.system(size: 12, weight: .semibold)).padding(.horizontal, 17).frame(height: 38)
      .background(AppTheme.violet.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 11))
      .foregroundStyle(AppTheme.ink)
  }
}

private struct IngredientPicker: View {
  @Environment(\.dismiss) private var dismiss
  @State private var search = ""
  let onSelect: (NutritionReference) -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Add ingredient").font(.title2.bold())
      TextField("Search offline nutrition catalog", text: $search).textFieldStyle(.roundedBorder)
      List(NutritionService.matches(search)) { item in
        Button {
          onSelect(item); dismiss()
        } label: {
          HStack { Text(item.name); Spacer(); Text("\(Int(item.calories)) kcal / 100 g").foregroundStyle(.secondary) }
        }.buttonStyle(.plain)
      }
      Button("Cancel") { dismiss() }.frame(maxWidth: .infinity, alignment: .trailing)
    }.padding(22).frame(width: 430, height: 480)
  }
}

import SwiftUI

struct DetectedFoodListView: View {
  let ingredients: [FoodItem]
  let state: MealLensViewModel.RecognitionState
  let onAdd: () -> Void
  let onDelete: (FoodItem) -> Void

  var body: some View {
    VStack(spacing: 0) {
      if ingredients.isEmpty { emptyState.frame(maxHeight: .infinity) }
      else {
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(ingredients) { item in
              HStack(spacing: 12) {
                Image(systemName: "fork.knife").foregroundStyle(AppTheme.violet).frame(width: 20)
                VStack(alignment: .leading, spacing: 4) {
                  HStack {
                    TextField("Ingredient", text: Bindable(item).name).textFieldStyle(.plain)
                      .font(.system(size: 14, weight: .semibold))
                    if let confidence = item.recognitionConfidence {
                      Text("\(Int(confidence * 100))%").font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                    }
                  }
                  HStack(spacing: 5) {
                    TextField("100", value: Bindable(item).grams, format: .number.precision(.fractionLength(0)))
                      .textFieldStyle(.plain).frame(width: 42)
                    Text("g").foregroundStyle(.secondary)
                  }.font(.system(size: 11))
                }
                Spacer()
                Text("\(Int(item.calories.rounded()))").font(.system(size: 16, weight: .semibold))
                Text("kcal").font(.system(size: 9)).foregroundStyle(.secondary)
                Button { onDelete(item) } label: { Image(systemName: "xmark").font(.system(size: 10)) }
                  .buttonStyle(.plain).foregroundStyle(.secondary)
              }.padding(.vertical, 11)
              Divider()
            }
          }.padding(.horizontal, 16)
        }
      }
      Divider()
      Button(action: onAdd) { Label("Add ingredient", systemImage: "plus") }
        .buttonStyle(.plain).font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.violet)
        .frame(maxWidth: .infinity, minHeight: 42)
    }
    .background(.white, in: RoundedRectangle(cornerRadius: 18))
    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.stroke))
  }

  @ViewBuilder private var emptyState: some View {
    VStack(spacing: 10) {
      switch state {
      case .loading:
        ProgressView(); Text("Analyzing photo…")
      case .failed(let message):
        Image(systemName: "exclamationmark.triangle"); Text(message)
      case .manualFallback(let message):
        Image(systemName: "hand.tap"); Text("Manual entry ready").fontWeight(.semibold); Text(message)
      default:
        Image(systemName: "leaf"); Text("Ingredients will appear here")
      }
    }.font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(24)
  }
}

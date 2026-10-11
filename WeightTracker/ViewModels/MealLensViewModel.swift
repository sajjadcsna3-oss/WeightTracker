import AppKit
import Foundation
import Observation

@MainActor @Observable
final class MealLensViewModel {
  enum RecognitionState: Equatable {
    case empty, loading, recognized, manualFallback(String), failed(String)
  }

  var image: NSImage?
  var imageData: Data?
  var ingredients: [FoodItem] = []
  var detections: [FoodRecognitionResult] = []
  var state: RecognitionState = .empty
  var showingAddMeal = false
  var errorMessage: String?
  private let recognizer = FoodRecognitionService()

  var calories: Double { ingredients.reduce(0) { $0 + $1.calories } }
  var protein: Double { ingredients.reduce(0) { $0 + $1.protein } }
  var carbohydrates: Double { ingredients.reduce(0) { $0 + $1.carbohydrates } }
  var fat: Double { ingredients.reduce(0) { $0 + $1.fat } }
  var canSave: Bool { image != nil && !ingredients.isEmpty && calories > 0 }

  func loadImage(from url: URL) {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    do {
      let data = try Data(contentsOf: url)
      guard let image = NSImage(data: data) else { throw FoodRecognitionError.invalidImage }
      self.image = image
      imageData = data
      ingredients = []
      detections = []
      state = .loading
      Task { await recognize(image) }
    } catch {
      state = .failed(error.localizedDescription)
    }
  }

  func add(_ reference: NutritionReference, grams: Double = 100) {
    ingredients.append(NutritionService.item(from: reference, grams: grams))
    if case .empty = state { state = .manualFallback("Enter ingredients and portions manually.") }
  }

  func remove(_ item: FoodItem) { ingredients.removeAll { $0.id == item.id } }

  private func recognize(_ image: NSImage) async {
    do {
      let results = try await Task.detached { [recognizer] in try await recognizer.recognize(image: image) }.value
      detections = results.filter { $0.boundingBox != nil }
      let matched = results.compactMap { result -> FoodItem? in
        guard let reference = NutritionService.reference(matching: result.label) else { return nil }
        return NutritionService.item(from: reference, confidence: result.confidence)
      }
      ingredients = Array(Dictionary(grouping: matched, by: { $0.name }).compactMap(\.value.first))
      if ingredients.isEmpty {
        state = .manualFallback("Apple Vision analyzed the photo but could not confidently match a supported food. Add or correct ingredients manually.")
      } else {
        state = .recognized
      }
    } catch FoodRecognitionError.modelUnavailable {
      state = .manualFallback(FoodRecognitionError.modelUnavailable.localizedDescription)
    } catch {
      state = .failed(error.localizedDescription)
    }
  }
}

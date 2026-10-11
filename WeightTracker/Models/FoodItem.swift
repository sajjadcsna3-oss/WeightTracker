import Foundation
import SwiftData

@Model
final class FoodItem {
  var id: UUID = UUID()
  var name: String = ""
  var grams: Double = 100
  var caloriesPer100Grams: Double = 0
  var proteinPer100Grams: Double = 0
  var carbohydratesPer100Grams: Double = 0
  var fatPer100Grams: Double = 0
  var recognitionConfidence: Double?

  init(
    name: String, grams: Double = 100, caloriesPer100Grams: Double = 0,
    proteinPer100Grams: Double = 0, carbohydratesPer100Grams: Double = 0,
    fatPer100Grams: Double = 0, recognitionConfidence: Double? = nil
  ) {
    self.id = UUID()
    self.name = name
    self.grams = grams
    self.caloriesPer100Grams = caloriesPer100Grams
    self.proteinPer100Grams = proteinPer100Grams
    self.carbohydratesPer100Grams = carbohydratesPer100Grams
    self.fatPer100Grams = fatPer100Grams
    self.recognitionConfidence = recognitionConfidence
  }

  var calories: Double { caloriesPer100Grams * grams / 100 }
  var protein: Double { proteinPer100Grams * grams / 100 }
  var carbohydrates: Double { carbohydratesPer100Grams * grams / 100 }
  var fat: Double { fatPer100Grams * grams / 100 }
}

struct NutritionReference: Identifiable, Hashable, Sendable {
  let name: String
  let calories: Double
  let protein: Double
  let carbohydrates: Double
  let fat: Double
  var id: String { name }
}

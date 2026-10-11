import Foundation
import SwiftData

enum MealCategory: String, CaseIterable, Identifiable, Codable {
  case breakfast = "Breakfast"
  case lunch = "Lunch"
  case dinner = "Dinner"
  case snack = "Snack"
  var id: String { rawValue }
  var shortTitle: String { self == .breakfast ? "Bkfst" : rawValue }
}

@Model
final class MealEntry {
  var id: UUID = UUID()
  var name: String = "Meal"
  var date: Date = Date()
  var categoryRawValue: String = MealCategory.lunch.rawValue
  var servingQuantity: Double = 1
  var calories: Double = 0
  var protein: Double = 0
  var carbohydrates: Double = 0
  var fat: Double = 0
  var imageReference: String?
  var createdAt: Date = Date()
  @Relationship(deleteRule: .cascade) var ingredients: [FoodItem] = []

  init(
    name: String, date: Date = .now, category: MealCategory, servingQuantity: Double,
    calories: Double, protein: Double, carbohydrates: Double, fat: Double,
    imageReference: String? = nil, ingredients: [FoodItem] = []
  ) {
    self.id = UUID()
    self.name = name
    self.date = date
    self.categoryRawValue = category.rawValue
    self.servingQuantity = servingQuantity
    self.calories = calories
    self.protein = protein
    self.carbohydrates = carbohydrates
    self.fat = fat
    self.imageReference = imageReference
    self.createdAt = .now
    self.ingredients = ingredients
  }

  var category: MealCategory {
    get { MealCategory(rawValue: categoryRawValue) ?? .lunch }
    set { categoryRawValue = newValue.rawValue }
  }
}

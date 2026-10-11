import Foundation

enum NutritionService {
  // Values are per 100 g and derived from standard food-composition references.
  // This compact on-device catalog keeps manual entry useful offline.
  static let catalog: [NutritionReference] = [
    .init(name: "Apple", calories: 52, protein: 0.3, carbohydrates: 13.8, fat: 0.2),
    .init(name: "Almonds", calories: 579, protein: 21.2, carbohydrates: 21.6, fat: 49.9),
    .init(name: "Avocado", calories: 160, protein: 2, carbohydrates: 8.5, fat: 14.7),
    .init(name: "Banana", calories: 89, protein: 1.1, carbohydrates: 22.8, fat: 0.3),
    .init(name: "Beef", calories: 250, protein: 26, carbohydrates: 0, fat: 15),
    .init(name: "Bread", calories: 265, protein: 9, carbohydrates: 49, fat: 3.2),
    .init(name: "Broccoli", calories: 35, protein: 2.4, carbohydrates: 7.2, fat: 0.4),
    .init(name: "Brown rice", calories: 123, protein: 2.7, carbohydrates: 25.6, fat: 1),
    .init(name: "Cheese", calories: 402, protein: 25, carbohydrates: 1.3, fat: 33),
    .init(name: "Chickpeas", calories: 164, protein: 8.9, carbohydrates: 27.4, fat: 2.6),
    .init(name: "Chicken breast", calories: 165, protein: 31, carbohydrates: 0, fat: 3.6),
    .init(name: "Egg", calories: 155, protein: 12.6, carbohydrates: 1.1, fat: 10.6),
    .init(name: "Greek yogurt", calories: 97, protein: 9, carbohydrates: 3.9, fat: 5),
    .init(name: "Hamburger", calories: 295, protein: 17, carbohydrates: 24, fat: 14),
    .init(name: "Ice cream", calories: 207, protein: 3.5, carbohydrates: 24, fat: 11),
    .init(name: "Leafy greens", calories: 23, protein: 2.9, carbohydrates: 3.6, fat: 0.4),
    .init(name: "Lentils", calories: 116, protein: 9, carbohydrates: 20, fat: 0.4),
    .init(name: "Oats", calories: 379, protein: 13.2, carbohydrates: 67.7, fat: 6.5),
    .init(name: "Olive oil", calories: 884, protein: 0, carbohydrates: 0, fat: 100),
    .init(name: "Pasta", calories: 157, protein: 5.8, carbohydrates: 30.9, fat: 0.9),
    .init(name: "Pancakes", calories: 227, protein: 6.4, carbohydrates: 28, fat: 10),
    .init(name: "Pizza", calories: 266, protein: 11, carbohydrates: 33, fat: 10),
    .init(name: "Potato", calories: 87, protein: 1.9, carbohydrates: 20.1, fat: 0.1),
    .init(name: "Quinoa", calories: 120, protein: 4.4, carbohydrates: 21.3, fat: 1.9),
    .init(name: "Salmon", calories: 208, protein: 20.4, carbohydrates: 0, fat: 13.4),
    .init(name: "Sesame dressing", calories: 443, protein: 3.1, carbohydrates: 16, fat: 42),
    .init(name: "Shrimp", calories: 99, protein: 24, carbohydrates: 0.2, fat: 0.3),
    .init(name: "Sushi", calories: 150, protein: 6, carbohydrates: 28, fat: 2),
    .init(name: "Tacos", calories: 226, protein: 9, carbohydrates: 20, fat: 13),
    .init(name: "Tofu", calories: 144, protein: 17.3, carbohydrates: 2.8, fat: 8.7),
    .init(name: "Tomato", calories: 18, protein: 0.9, carbohydrates: 3.9, fat: 0.2),
    .init(name: "Waffles", calories: 291, protein: 8, carbohydrates: 33, fat: 14),
    .init(name: "White rice", calories: 130, protein: 2.7, carbohydrates: 28.2, fat: 0.3)
  ]

  static func matches(_ text: String) -> [NutritionReference] {
    let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return catalog }
    return catalog.filter { $0.name.localizedCaseInsensitiveContains(query) }
  }

  static func reference(matching label: String) -> NutritionReference? {
    let normalized = label.lowercased()
      .replacingOccurrences(of: "_", with: " ")
      .replacingOccurrences(of: "-", with: " ")
    if let exact = catalog.first(where: {
      normalized.contains($0.name.lowercased()) || $0.name.lowercased().contains(normalized)
    }) { return exact }

    // Vision's built-in taxonomy sometimes uses broader or alternate names.
    // Each alias maps a real Vision label to its closest catalog food.
    let aliases: [(terms: [String], food: String)] = [
      (["almond", "nut"], "Almonds"),
      (["avocado", "alligator pear"], "Avocado"),
      (["bean", "chickpea", "garbanzo", "legume"], "Chickpeas"),
      (["beef", "steak", "red meat"], "Beef"),
      (["bread", "toast", "loaf"], "Bread"),
      (["broccoli"], "Broccoli"),
      (["cheese", "cheddar"], "Cheese"),
      (["chicken", "poultry"], "Chicken breast"),
      (["egg"], "Egg"),
      (["green vegetable", "leaf vegetable", "lettuce", "spinach"], "Leafy greens"),
      (["lentil"], "Lentils"),
      (["pasta", "noodle", "spaghetti"], "Pasta"),
      (["potato"], "Potato"),
      (["rice"], "White rice"),
      (["salmon"], "Salmon"),
      (["shrimp", "prawn"], "Shrimp"),
      (["tofu", "soybean curd"], "Tofu"),
      (["tomato"], "Tomato"),
      (["yogurt", "yoghurt"], "Greek yogurt")
    ]
    guard let mappedName = aliases.first(where: { alias in
      alias.terms.contains(where: normalized.contains)
    })?.food else { return nil }
    return catalog.first { $0.name == mappedName }
  }

  static func item(from reference: NutritionReference, grams: Double = 100, confidence: Double? = nil) -> FoodItem {
    FoodItem(name: reference.name, grams: grams, caloriesPer100Grams: reference.calories,
      proteinPer100Grams: reference.protein, carbohydratesPer100Grams: reference.carbohydrates,
      fatPer100Grams: reference.fat, recognitionConfidence: confidence)
  }
}

import AppKit
import Foundation
import SwiftData

enum MealStorageError: LocalizedError {
  case imageEncodingFailed
  case duplicateMeal
  var errorDescription: String? {
    switch self {
    case .imageEncodingFailed: "The meal was saved, but its image could not be stored."
    case .duplicateMeal: "This meal has already been saved."
    }
  }
}

enum MealStorageService {
  static func storeImage(_ image: NSImage) throws -> String {
    guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.82])
    else { throw MealStorageError.imageEncodingFailed }
    let manager = FileManager.default
    let root = try manager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("WeightTracker/MealImages", isDirectory: true)
    try manager.createDirectory(at: root, withIntermediateDirectories: true)
    let url = root.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
    try data.write(to: url, options: .atomic)
    return url.path
  }

  static func image(at reference: String?) -> NSImage? {
    guard let reference else { return nil }
    return NSImage(contentsOfFile: reference)
  }

  @MainActor static func delete(_ meal: MealEntry, from context: ModelContext) throws {
    if let path = meal.imageReference { try? FileManager.default.removeItem(atPath: path) }
    context.delete(meal)
    try context.save()
  }
}

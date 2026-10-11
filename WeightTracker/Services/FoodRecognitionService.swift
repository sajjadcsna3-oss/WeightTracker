import AppKit
import CoreML
import Foundation
import Vision

struct FoodRecognitionResult: Sendable {
  let label: String
  let confidence: Double
  let boundingBox: CGRect?
}

enum FoodRecognitionError: LocalizedError {
  case modelUnavailable
  case invalidImage
  case unsupportedOutput

  var errorDescription: String? {
    switch self {
    case .modelUnavailable: "No compatible food-recognition model is bundled. Add ingredients manually."
    case .invalidImage: "The selected image could not be read."
    case .unsupportedOutput: "The bundled model did not return classifications or detections."
    }
  }
}

final class FoodRecognitionService: @unchecked Sendable {
  func recognize(image: NSImage) async throws -> [FoodRecognitionResult] {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      throw FoodRecognitionError.invalidImage
    }
    guard let modelURL = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil)?.first else {
      return try await recognizeWithAppleVision(cgImage)
    }
    let coreModel = try MLModel(contentsOf: modelURL)
    let visionModel = try VNCoreMLModel(for: coreModel)
    let request = VNCoreMLRequest(model: visionModel)
    request.imageCropAndScaleOption = .scaleFit
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])

    if let detections = request.results as? [VNRecognizedObjectObservation] {
      return detections.compactMap { observation in
        guard let label = observation.labels.first else { return nil }
        return FoodRecognitionResult(label: label.identifier, confidence: Double(label.confidence), boundingBox: observation.boundingBox)
      }
    }
    if let classifications = request.results as? [VNClassificationObservation] {
      let scores = classifications.map { Double($0.confidence) }
      let total = scores.reduce(0, +)
      let needsSoftmax = scores.contains(where: { $0 < 0 || $0 > 1 }) || abs(total - 1) > 0.05
      let probabilities: [Double]
      if needsSoftmax, let maximum = scores.max() {
        let exponentials = scores.map { exp($0 - maximum) }
        let denominator = exponentials.reduce(0, +)
        probabilities = exponentials.map { $0 / denominator }
      } else {
        probabilities = scores
      }
      return zip(classifications, probabilities).prefix(5).map { observation, probability in
        FoodRecognitionResult(label: observation.identifier, confidence: probability, boundingBox: nil)
      }
    }
    throw FoodRecognitionError.unsupportedOutput
  }

  /// Uses Apple's built-in, on-device classifier when the app does not ship a
  /// dedicated Core ML model. These are real Vision results and confidences.
  private func recognizeWithAppleVision(_ image: CGImage) async throws -> [FoodRecognitionResult] {
    let request = Vision.ClassifyImageRequest(.revision2)
    let observations = try await request.perform(on: image)
    return observations
      .filter { $0.confidence >= 0.01 }
      .prefix(50)
      .map {
        FoodRecognitionResult(
          label: $0.identifier,
          confidence: Double($0.confidence),
          boundingBox: nil
        )
      }
  }
}

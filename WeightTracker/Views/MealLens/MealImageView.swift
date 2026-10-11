import AppKit
import SwiftUI

struct MealImageView: View {
  let image: NSImage?
  let detections: [FoodRecognitionResult]

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        RoundedRectangle(cornerRadius: 18).fill(Color.white)
        if let image {
          Image(nsImage: image).resizable().scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height).clipped()
          ForEach(Array(detections.enumerated()), id: \.offset) { _, result in
            if let box = result.boundingBox {
              detectionBox(result, box: box, size: proxy.size)
            }
          }
        } else {
          VStack(spacing: 12) {
            Image(systemName: "camera.viewfinder").font(.system(size: 42)).foregroundStyle(AppTheme.violet)
            Text("Choose a food photo").font(.system(size: 18, weight: .semibold))
            Text("Recognition runs on-device when a compatible Core ML model is bundled.")
              .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
          }.padding(30)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 18))
      .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.stroke))
    }
  }

  private func detectionBox(_ result: FoodRecognitionResult, box: CGRect, size: CGSize) -> some View {
    let width = box.width * size.width
    let height = box.height * size.height
    let x = box.minX * size.width
    let y = (1 - box.maxY) * size.height
    return RoundedRectangle(cornerRadius: 10)
      .stroke(AppTheme.violet, lineWidth: 1.2)
      .frame(width: width, height: height)
      .overlay(alignment: .topLeading) {
        Text("\(result.label) · \(Int(result.confidence * 100))%")
          .font(.system(size: 10, weight: .semibold)).padding(.horizontal, 7).padding(.vertical, 3)
          .background(AppTheme.violet, in: RoundedRectangle(cornerRadius: 5)).offset(y: -11)
      }
      .position(x: x + width / 2, y: y + height / 2)
  }
}

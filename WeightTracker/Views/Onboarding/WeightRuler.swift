//
//  WeightRuler.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI

struct WeightRuler: View {
  @Binding var weight: Double
  @State private var dragStartWeight: Double?
  private let minWeight = 20.0
  private let maxWeight = 500.0
  var body: some View {
    GeometryReader { geo in
      ZStack {
        RoundedRectangle(cornerRadius: 12).fill(AppTheme.background)
        HStack(spacing: 0) {
          ForEach(-25...25, id: \.self) { offset in
            let tickValue = (weight * 10).rounded() / 10 + Double(offset) / 10
            VStack(spacing: 4) {
              Rectangle().fill(Color.gray.opacity(0.65))
                .frame(
                  width: offset.isMultiple(of: 10) ? 2 : 1,
                  height: offset.isMultiple(of: 10) ? 36 : offset.isMultiple(of: 5) ? 25 : 14)
              if offset.isMultiple(of: 10) {
                Text(String(format: "%.0f", tickValue))
                  .font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
              }
            }.frame(maxWidth: .infinity, alignment: .top).frame(height: 58, alignment: .top)
          }
        }.padding(.horizontal, 8)
        Rectangle().fill(AppTheme.ink).frame(width: 3, height: 70)
        Image(systemName: "arrowtriangle.down.fill")
          .font(.system(size: 12)).foregroundStyle(AppTheme.lime)
          .offset(y: -34)
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { gesture in
            if dragStartWeight == nil { dragStartWeight = weight }
            let delta = gesture.translation.width / 12
            weight = min(max(minWeight, (dragStartWeight ?? weight) - delta * 0.1), maxWeight)
            weight = (weight * 10).rounded() / 10
          }
          .onEnded { _ in dragStartWeight = nil })
    }.frame(height: 74)
      .accessibilityLabel("Weight ruler")
      .accessibilityValue(String(format: "%.1f kilograms", weight))
  }
}

#Preview {
  WeightRuler(weight: .constant(76.8))
    .padding()
    .frame(width: 620)
}

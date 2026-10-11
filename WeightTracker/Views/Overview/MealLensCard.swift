//
//  MealLensCard.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI

struct MealLensCard: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 15) {
      HStack {
        Label("Meal Lens", systemImage: "sparkles")
          .font(.system(size: 12, weight: .semibold))
        Spacer()
        Text("PRO").font(.system(size: 9, weight: .bold))
          .padding(4).background(AppTheme.purple, in: RoundedRectangle(cornerRadius: 4))
      }
      HStack(alignment: .firstTextBaseline, spacing: 5) {
        Text("1,420").font(.system(size: 22, weight: .semibold))
        Text("/ 1,850 kcal").font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
      }
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule().fill(.white.opacity(0.12)).frame(height: 6)
          Capsule().fill(AppTheme.violet).frame(width: proxy.size.width * 0.77, height: 6)
        }
      }.frame(height: 6)
      Text("Lunch scan: salmon bowl · keeps tomorrow at −0.06 kg")
        .font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
      Spacer()
    }
    .padding(16).foregroundStyle(.white)
    .frame(maxWidth: .infinity, alignment: .leading).frame(height: 224)
    .background(Color(red: 0.11, green: 0.09, blue: 0.19), in: RoundedRectangle(cornerRadius: 19))
  }
}

#Preview {
  MealLensCard()
    .padding()
    .frame(width: 340)
    .background(AppTheme.background)
}

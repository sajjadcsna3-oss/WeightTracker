//
//  CurrentWeightCard.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI

struct CurrentWeightCard: View {
  let current: Double?
  let previous: Double?
  let start: Double
  let goal: Double

  private var displayedWeight: Double { current ?? start }
  private var change: Double { displayedWeight - (previous ?? start) }
  private var progress: Double {
    WeightMath.progress(start: start, current: displayedWeight, goal: goal)
  }

  private var yesterdayChange: String {
    let amount = abs(change)
    return String(format: "%.1f kg since last entry", amount)
  }

  var body: some View {
    HStack(spacing: 35) {
      VStack(alignment: .leading, spacing: 6) {
        Text("CURRENT")
          .font(.system(size: 10, design: .monospaced))
          .foregroundStyle(.gray)

        HStack(alignment: .firstTextBaseline, spacing: 7) {
          Text(displayedWeight, format: .number.precision(.fractionLength(1)))
            .font(.system(size: 70, weight: .light))
            .tracking(-4)

          Text("kg")
            .font(.system(size: 17))
            .foregroundStyle(.gray)
        }

        HStack(spacing: 6) {
          Image(
            systemName: change <= 0
              ? "arrow.down.right" : "arrow.up.right")

          Text(yesterdayChange)
        }
        .font(.system(size: 11))
        .foregroundStyle(AppTheme.lime)
      }
      .frame(width: 240, alignment: .leading)

      VStack(alignment: .leading, spacing: 23) {
        HStack {
          Text("\(Int(progress * 100))% of the way")
            .font(.system(size: 14, weight: .semibold))

          Spacer()

          Label(progress >= 1 ? "Goal reached" : "On track", systemImage: "checkmark.circle")
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(AppTheme.black)
            .background(AppTheme.lime)
            .clipShape(Capsule())
        }

        GeometryReader { proxy in
          ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.12)).frame(height: 10)
            Capsule().fill(AppTheme.lime)
              .frame(width: proxy.size.width * progress, height: 10)
            ForEach([0.2, 0.4, 0.8], id: \.self) { mark in
              Rectangle().fill(AppTheme.black.opacity(0.75)).frame(width: 2, height: 19)
                .offset(x: proxy.size.width * mark)
            }
            Circle().fill(.white).frame(width: 19, height: 19)
              .overlay { Circle().stroke(AppTheme.black, lineWidth: 3) }
              .offset(x: min(max(0, proxy.size.width * progress - 9), max(0, proxy.size.width - 19)))
          }
        }
        .frame(height: 17)

        HStack(spacing: 0) {
          Text(String(format: "%.1f start", start)).frame(maxWidth: .infinity, alignment: .leading)
          Text("−2.5").frame(maxWidth: .infinity)
          Text("−5.0").frame(maxWidth: .infinity)
          Text("you").frame(maxWidth: .infinity)
          Text("−10.0").frame(maxWidth: .infinity)
          Text(String(format: "%.1f goal", goal)).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.gray)
      }
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 28).padding(.vertical, 24)
    .frame(maxWidth: .infinity)
    .frame(height: 167)
    .background(AppTheme.black)
    .clipShape(RoundedRectangle(cornerRadius: 22))
  }
}

#Preview {
  CurrentWeightCard(current: 76.8, previous: 77.2, start: 82.4, goal: 70)
    .padding()
    .frame(width: 850)
    .background(AppTheme.background)
}

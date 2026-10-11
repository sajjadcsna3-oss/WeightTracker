//
//  ChallengePreviewCard.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI

struct ChallengePreviewCard: View {

  var body: some View {
    HStack(spacing: 12) {
      HStack(spacing: -8) {
        avatar("A", color: .brown)
        avatar("S", color: .pink)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text("October Cut")
          .font(.system(size: 12, weight: .semibold))

        Text("You lead Sara by 0.3 kg")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(height: 64)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 17))
    .overlay {
      RoundedRectangle(cornerRadius: 17)
        .stroke(AppTheme.border)
    }
  }

  private func avatar(_ letter: String, color: Color) -> some View {
    Text(letter)
      .font(.system(size: 12, weight: .bold))
      .foregroundStyle(.white)
      .frame(width: 30, height: 30)
      .background(color)
      .clipShape(Circle())
      .overlay {
        Circle().stroke(.white, lineWidth: 2)
      }
  }
}

#Preview {
  ChallengePreviewCard()
    .padding()
    .frame(width: 340)
    .background(AppTheme.background)
}

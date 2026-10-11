//
//  OverviewHeaderView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI

struct OverviewHeaderView: View {

  let onLogWeight: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 5) {
        Text(
          Date.now.formatted(
            .dateTime.weekday(.abbreviated).day().month(.abbreviated)
          ).uppercased()
        )
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.secondary)

        Text("Morning, Alex")
          .font(.system(size: 25, weight: .bold))
          .tracking(-1)
      }

      Spacer()

      Label("Local data", systemImage: "checkmark.circle")
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .padding(12)
        .overlay {
          RoundedRectangle(cornerRadius: 11)
            .stroke(AppTheme.border)
        }

      Button(action: onLogWeight) {
        Label("Log weight", systemImage: "plus")
          .font(.system(size: 12, weight: .semibold))
          .padding(.horizontal, 17)
          .frame(height: 39)
          .background(AppTheme.black)
          .foregroundStyle(.white)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
      .buttonStyle(.plain)
    }
  }
}

#Preview {
  OverviewHeaderView(onLogWeight: {})
    .padding()
    .frame(width: 900)
    .background(AppTheme.background)
}

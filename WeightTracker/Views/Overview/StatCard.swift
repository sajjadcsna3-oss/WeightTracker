//
//  StatCard.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI

struct StatCard: View {
  let title: String
  let value: String
  let unit: String
  let icon: String

    var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Label(title, systemImage: icon)
        .font(.system(size: 11)).foregroundStyle(.secondary)
      HStack(alignment: .firstTextBaseline, spacing: 5) {
        Text(value).font(.system(size: 23, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
        Text(unit).font(.system(size: 11)).foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(17).frame(height: 90)
    .background(.white, in: RoundedRectangle(cornerRadius: 17))
    .overlay(RoundedRectangle(cornerRadius: 17).stroke(AppTheme.border, lineWidth: 0.8))
  }
}

#Preview {
  StatCard(title: "Total change", value: "-5.6", unit: "kg", icon: "arrow.down.right")
    .padding()
    .frame(width: 260)
    .background(AppTheme.background)
}

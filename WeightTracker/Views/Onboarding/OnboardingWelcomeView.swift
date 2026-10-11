//
//  OnboardingWelcomeView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//
import SwiftUI

struct OnboardingWelcomeView: View {
  let onNext: () -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading) {
        Text("YOUR JOURNEY")
          .font(.system(size: 11, design: .monospaced)).foregroundStyle(.gray)
        Spacer()
        HStack(alignment: .firstTextBaseline, spacing: 7) {
          Text("74.8").font(.system(size: 70, weight: .light))
          Text("kg").font(.system(size: 18)).foregroundStyle(.gray)
        }
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.13))
            Capsule().fill(AppTheme.lime).frame(width: geo.size.width * 0.61)
          }
        }.frame(height: 9)
        HStack {
          Text("82.4 start")
          Spacer()
          Text("70.0 goal")
        }.font(.system(size: 11, design: .monospaced)).foregroundStyle(.gray)
      }
      .padding(28)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .background(AppTheme.ink)
      .foregroundStyle(.white)
      .clipShape(RoundedRectangle(cornerRadius: 21))
      .padding(.bottom, 18)
      Text("Every gram.\nin context.")
        .font(.system(size: 33, weight: .bold))
        .tracking(-1)
        .foregroundColor(.black)

      Text(
        "Log in a second, see the trend behind the noise, and know exactly when you’ll get there."
      )
      .font(.system(size: 13))
      .foregroundColor(.black)
      .padding(.top, 18)
      Spacer(minLength: 16)
      HStack {
        Text("Step 1 of 4").font(.system(size: 12)).foregroundStyle(.secondary)
          .foregroundColor(.black)
        Spacer()
        OnboardingButton(title: "Get started", action: onNext)
      }
    }
  }
}

#Preview {
  OnboardingWelcomeView(onNext: {})
    .padding()
    .frame(width: 520, height: 650)
    .background(AppTheme.background)
}

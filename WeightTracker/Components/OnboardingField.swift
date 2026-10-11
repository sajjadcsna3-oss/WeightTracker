//
//  OnboardingField.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI

struct OnboardingFrame<Content: View>: View {
  let step: Int
  let content: Content
  init(step: Int, @ViewBuilder content: () -> Content) {
    self.step = step
    self.content = content()
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        HStack(spacing: 7) {
          Circle().fill(Color.red)
          Circle().fill(Color.orange)
          Circle().fill(Color.green)
        }.frame(width: 54, height: 12)
        Spacer()
        HStack(spacing: 5) {
          ForEach(0..<4, id: \.self) { i in
            Capsule().fill(i == step ? AppTheme.ink : AppTheme.stroke)
              .frame(width: i == step ? 22 : 8, height: 5)
          }
        }
      }.padding(.bottom, 20)
      content
    }
    .padding(.horizontal, 38)
    .padding(.top, 20)
    .padding(.bottom, 34)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(AppTheme.background)
  }
}

struct OnboardingButton: View {
  enum Style {
    case dark
    case lime

    var background: Color { self == .lime ? AppTheme.lime : AppTheme.ink }
    var foreground: Color { self == .lime ? AppTheme.ink : .white }
  }

  let title: String
  var style: Style = .dark
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(style.foreground)
        .padding(.horizontal, 22)
        .frame(minWidth: style == .lime ? 143 : nil, minHeight: 43)
        .background(style.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

struct OnboardingField: View {
  let title: String
  @Binding var value: String
  let unit: String
  var body: some View {
    HStack {
      Text(title).foregroundStyle(.secondary)
      Spacer()
      TextField("Required", text: $value)
        .multilineTextAlignment(.trailing)
        .textFieldStyle(.plain)
        .font(.system(size: 21, weight: .semibold))
        .frame(width: 170)
      Text(unit).font(.system(size: 12)).foregroundStyle(.secondary)
    }
    .font(.system(size: 13))
    .padding(.horizontal, 16)
    .frame(height: 59)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 13))
    .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.stroke))
  }
}

#Preview("Onboarding Frame") {
  OnboardingFrame(step: 1) {
    Text("Preview content")
  }
  .frame(width: 520, height: 300)
}

#Preview("Onboarding Button") {
  OnboardingButton(title: "Continue", action: {})
    .padding()
}

#Preview("Onboarding Field") {
  OnboardingField(title: "Current weight", value: .constant("82.4"), unit: "kg")
    .padding()
    .frame(width: 440)
    .background(AppTheme.background)
}

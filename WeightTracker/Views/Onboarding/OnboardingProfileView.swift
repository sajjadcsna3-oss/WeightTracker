//
//  OnboardingProfileView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//
import SwiftUI

struct OnboardingProfileView: View {
  @ObservedObject var vm: OnboardingViewModel
  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("A little\nabout you.").font(.system(size: 33, weight: .bold))
        .tracking(-1)
        .foregroundColor(.black)
      Text("Used for BMI and healthy-range targets. Stays on your Mac.")
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .foregroundColor(.black)
      HStack(spacing: 4) {
        unitButton("kg · cm", imperial: false)
        unitButton("lbs · ft", imperial: true)
      }.padding(4)
        .background(AppTheme.stroke.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .foregroundColor(.black)
      OnboardingField(title: "Name", value: $vm.displayName, unit: "")
        .foregroundColor(.black)
      OnboardingField(title: "Height", value: $vm.height, unit: vm.imperial ? "ft" : "cm")
        .foregroundColor(.black)
      OnboardingField(title: "Age", value: $vm.age, unit: "")
        .foregroundColor(.black)
      OnboardingField(title: "Current weight", value: $vm.weight, unit: vm.imperial ? "lb" : "kg")
        .foregroundColor(.black)
      Spacer()
      HStack {
        Button("Back", action: vm.back)
          .buttonStyle(.plain)
          .foregroundStyle(.secondary)
          .foregroundColor(.black)
        Spacer()
        OnboardingButton(title: "Continue", action: vm.next)
      }
    }
  }
    
  private func unitButton(_ title: String, imperial: Bool) -> some View {
    Button {
      guard vm.imperial != imperial else { return }
      if let h = Double(vm.height), let w = Double(vm.weight) {
        vm.height = String(format: "%.2f", imperial ? h / 30.48 : h * 30.48)
        vm.weight = String(format: "%.1f", imperial ? w / 0.45359237 : w * 0.45359237)
      } else {
        vm.height = ""
        vm.weight = ""
      }
      if let g = Double(vm.goal) {
        vm.goal = String(format: "%.1f", imperial ? g / 0.45359237 : g * 0.45359237)
      }
      vm.imperial = imperial
    } label: {
      Text(title).font(.system(size: 13, weight: vm.imperial == imperial ? .semibold : .regular))
        .frame(maxWidth: .infinity).frame(height: 38)
        .background(vm.imperial == imperial ? .white : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .foregroundColor(.black)
        .contentShape(Rectangle())
    }

    .buttonStyle(.plain)
    .foregroundColor(.black)
  }
}

#Preview {
  OnboardingProfileView(vm: OnboardingViewModel())
    .padding()
    .frame(width: 520, height: 650)
    .background(AppTheme.background)
}

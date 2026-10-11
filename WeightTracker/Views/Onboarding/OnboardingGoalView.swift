//
//  OnboardingGoalView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//
import SwiftUI

struct OnboardingGoalView: View {
  @ObservedObject var vm: OnboardingViewModel

  private let paceOptions: [(value: Double, title: String, date: String)] = [
    (0.25, "Gentle", "Jun 2027"),
    (0.50, "Steady", "Feb 2027"),
    (0.75, "Focused", "Dec 2026"),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("Where are\nyou headed?")
        .font(.system(size: 33, weight: .bold))
        .tracking(-1)
        .foregroundStyle(AppTheme.ink)

      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("NOW")
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.secondary)
            .foregroundColor(.black)
          Text(vm.weight.isEmpty ? "—" : vm.weight)
            .font(.system(size: 29))
            .foregroundStyle(AppTheme.ink)
        }

        Spacer()
        Image(systemName: "arrow.right")
          .font(.system(size: 20, weight: .regular))
          .foregroundStyle(.secondary)
          .foregroundColor(.black)
        Spacer()

        VStack(alignment: .trailing, spacing: 2) {
          Text("GOAL")
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.secondary)
            .foregroundColor(.black)
          HStack(alignment: .lastTextBaseline, spacing: 1) {
            TextField("Goal", text: $vm.goal)
              .textFieldStyle(.plain)
              .multilineTextAlignment(.trailing)
              .font(.system(size: 29, weight: .semibold))
              .foregroundStyle(AppTheme.ink)
              .frame(width: 90)
              .foregroundColor(.black)
            Text(vm.imperial ? "lb" : "kg")
              .font(.system(size: 11))
              .foregroundStyle(.secondary)
              .foregroundColor(.black)
          }
        }
      }
      .padding(.horizontal, 20)
      .frame(height: 96)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 17))
      .overlay(RoundedRectangle(cornerRadius: 17).stroke(AppTheme.stroke))
      .padding(.top, 18)

      Text("Pace")
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .padding(.top, 19)
        .padding(.bottom, 18)

      VStack(spacing: 8) {
        ForEach(paceOptions, id: \.value) { option in
          Button {
            vm.pace = option.value
          } label: {
            HStack {
              Text("\(option.title) · \(paceText(option.value)) kg/wk")
              Spacer()
              Text(option.date)
                .foregroundStyle(vm.pace == option.value ? AppTheme.ink : .secondary)
            }
            .font(.system(size: 13, weight: vm.pace == option.value ? .semibold : .regular))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 15)
            .frame(height: 52)
            .background(vm.pace == option.value ? AppTheme.lime : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(vm.pace == option.value ? AppTheme.ink : AppTheme.stroke))
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }

      Spacer()

      HStack {
        Button("Back", action: vm.back)
          .buttonStyle(.plain)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
          .foregroundColor(.black)
        Spacer()
        OnboardingButton(title: "Set goal", action: vm.next)
      }
    }
  }

  private func paceText(_ pace: Double) -> String {
    pace == 0.5 ? "0.5" : String(format: "%.2f", pace)
  }
}

#Preview {
  OnboardingGoalView(vm: OnboardingViewModel())
    .padding()
    .frame(width: 520, height: 650)
    .background(AppTheme.background)
}

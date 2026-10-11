//
//  OnboardingPermissionsView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI

struct OnboardingPermissionsView: View {
  @ObservedObject var vm: OnboardingViewModel
  let finish: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      title

      settingRow(
        title: "Apple Health",
        subtitle: "Read & write weight",
        icon: "heart",
        isOn: $vm.healthSync
      )
      .padding(.bottom, 8)

      settingRow(
        title: "iCloud sync",
        subtitle: "Mac, iPhone & iPad",
        icon: "icloud",
        isOn: $vm.cloudSync
      )
      .padding(.bottom, 8)

      settingRow(
        title: "Touch ID lock",
        subtitle: "Ask when opening",
        icon: "touchid",
        isOn: $vm.touchID
      )
      .padding(.bottom, 8)

      settingRow(
        title: "Morning reminder",
        subtitle: "07:30 daily",
        icon: "bell",
        isOn: $vm.reminder
      )
      .padding(.bottom, 16)

      trialBanner

      Spacer()

      bottomButtons
    }
    .font(.system(size: 13))
  }

  private var title: some View {
    Text("Sync it.\nLock it.")
      .font(.system(size: 33, weight: .bold))
      .tracking(-1)
      .foregroundStyle(AppTheme.ink)
      .padding(.bottom, 15)
  }

  private var trialBanner: some View {
    Label("Meal Lens AI is free for 7 days", systemImage: "sparkles")
      .font(.system(size: 13))
      .foregroundStyle(Color(red: 0.20, green: 0.17, blue: 0.48))
      .frame(maxWidth: .infinity, minHeight: 43, alignment: .leading)
      .padding(.horizontal, 14)
      .background(Color(red: 0.93, green: 0.91, blue: 1.0))
      .cornerRadius(11)
  }

  private var bottomButtons: some View {
    HStack {
      Button("Back") {
        vm.back()
      }
      .buttonStyle(.plain)
      .foregroundStyle(Color(red: 0.34, green: 0.34, blue: 0.34))

      Spacer()

      OnboardingButton(
        title: "Start tracking",
        style: .lime,
        action: finish
      )
    }
  }

  private func settingRow(
    title: String,
    subtitle: String,
    icon: String,
    isOn: Binding<Bool>
  ) -> some View {
    HStack(spacing: 13) {
      Image(systemName: icon)
        .font(.system(size: 16))
        .frame(width: 35, height: 35)
        .background(Color(red: 0.95, green: 0.94, blue: 0.92))
        .cornerRadius(10)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 14, weight: .semibold))
        Text(subtitle)
          .font(.system(size: 12))
          .foregroundStyle(Color(red: 0.42, green: 0.42, blue: 0.42))
      }

      Spacer()

      Toggle("", isOn: isOn)
        .labelsHidden()
        .toggleStyle(BlackSwitchStyle())
    }
    .padding(.horizontal, 14)
    .frame(height: 62)
    .background(.white)
    .cornerRadius(14)
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.stroke))
    .foregroundStyle(AppTheme.ink)
  }
}

private struct BlackSwitchStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button {
      withAnimation {
        configuration.isOn.toggle()
      }
    } label: {
      HStack(spacing: 0) {
        if configuration.isOn {
          Spacer()
        }

        Circle()
          .fill(Color.white)
          .frame(width: 19, height: 19)

        if !configuration.isOn {
          Spacer()
        }
      }
      .padding(2)
      .frame(width: 39, height: 23)
      .background(configuration.isOn ? AppTheme.ink : Color(red: 0.82, green: 0.81, blue: 0.78))
      .clipShape(Capsule())
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  OnboardingPermissionsView(vm: OnboardingViewModel(), finish: {})
    .padding()
    .frame(width: 520, height: 650)
    .background(AppTheme.background)
}

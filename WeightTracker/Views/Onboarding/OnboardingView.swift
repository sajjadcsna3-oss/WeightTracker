//
//  OnboardingView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftData
import SwiftUI

struct OnboardingFlowView: View {
  @Environment(\.modelContext) private var context
  @StateObject private var vm = OnboardingViewModel()
  let onComplete: () -> Void
  var body: some View {
    OnboardingFrame(step: vm.step) {
      Group {
        switch vm.step {
        case 0: OnboardingWelcomeView(onNext: vm.next)
        case 1: OnboardingProfileView(vm: vm)
        case 2: OnboardingGoalView(vm: vm)
        default:
          OnboardingPermissionsView(vm: vm) {
            Task {
              if await vm.finish(context: context) { onComplete() }
            }
          }
        }
      }
      if let error = vm.error {
        Text(error).font(.caption).foregroundStyle(.red).padding(.top, 8)
      }
    }
    .frame(minWidth: 900, minHeight: 650)
  }
}

#Preview {
  OnboardingFlowView(onComplete: {})
    .modelContainer(for: [WeightProfile.self, WeightEntry.self], inMemory: true)
}

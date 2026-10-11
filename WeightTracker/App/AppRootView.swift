import SwiftData
//
//  AppRootView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//
import SwiftUI

struct AppRootView: View {
  @Query private var profiles: [WeightProfile]
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  @State private var phase: AppLaunchPhase = .splash
  @State private var unlocked = false
  @State private var authenticating = false

  var body: some View {
    ZStack {
      switch phase {
      case .splash:
        SplashView()
          .transition(.opacity)

      case .onboarding:
        OnboardingFlowView {
          unlocked = true
          hasCompletedOnboarding = true
          withAnimation(.easeInOut(duration: 0.35)) {
            phase = .main
          }
        }
        .transition(.opacity)

      case .main:
        if let profile = completedProfile, profile.lockEnabled && !unlocked {
          lockScreen
            .transition(.opacity)
        } else {
          ContentView()
            .transition(.opacity)
        }
      }
    }
    .preferredColorScheme(.light)
    .task {
      guard phase == .splash else { return }
      try? await Task.sleep(for: .milliseconds(1600))
      guard !Task.isCancelled else { return }
      withAnimation(.easeInOut(duration: 0.35)) {
        phase = completedProfile == nil ? .onboarding : .main
      }
    }
  }

  private var completedProfile: WeightProfile? {
    guard hasCompletedOnboarding else { return nil }
    return profiles.first(where: \.onboardingComplete)
  }

  private var lockScreen: some View {
    VStack(spacing: 16) {
      Image(systemName: "lock.shield")
        .font(.system(size: 42))

      Text("Weight Tracker is locked")
        .font(.title2.bold())

      Button("Unlock") {
        Task {
          await unlock()
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(authenticating)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppTheme.background)
    .task {
      await unlock()
    }
  }

  @MainActor private func unlock() async {
    guard !authenticating else { return }
    authenticating = true
    unlocked = await AuthenticationService.authenticate()
    authenticating = false
  }
}

private enum AppLaunchPhase {
  case splash
  case onboarding
  case main
}

#Preview {
  AppRootView()
    .modelContainer(for: [WeightProfile.self, WeightEntry.self, MealEntry.self, FoodItem.self], inMemory: true)
}

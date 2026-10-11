//
//  WeightTrackerApp.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.

import AppKit
import SwiftData
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApplication.shared.setActivationPolicy(.regular)

    if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
      let icon = NSImage(contentsOf: iconURL)
    {
      NSApplication.shared.applicationIconImage = icon
    }

  }
}

@main
struct WeightTrackerApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      AppRootView()
    }
    .modelContainer(for: [WeightProfile.self, WeightEntry.self, MealEntry.self, FoodItem.self])
    .defaultSize(width: 1200, height: 800)
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentMinSize)
  }
}

//
//  ReminderService.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//
import Foundation
import UserNotifications

enum ReminderService {
  @MainActor
  static func enableMorningReminder() async -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
      let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
      guard granted else { return false }
      let content = UNMutableNotificationContent()
      content.title = "Log your weight"
      content.body = "A quick morning check-in helps you see your progress."
      content.sound = .default
      var components = DateComponents()
      components.hour = 7
      components.minute = 30
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
      let request = UNNotificationRequest(
        identifier: "weight.morning.reminder", content: content, trigger: trigger)
      try await center.add(request)
      return true
    } catch {
      return false
    }
  }
}

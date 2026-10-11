import Foundation
import HealthKit
import Security

enum HealthKitService {
  /// HealthKit requires a paid-development provisioning profile on macOS.
  /// Keep it hidden in locally signed builds and expose it automatically when
  /// the app is distributed with the HealthKit entitlement enabled.
  static var isAvailable: Bool {
    guard HKHealthStore.isHealthDataAvailable(),
      let task = SecTaskCreateFromSelf(nil),
      let value = SecTaskCopyValueForEntitlement(
        task, "com.apple.developer.healthkit" as CFString, nil
      )
    else { return false }
    return (value as? Bool) == true
  }

  static func save(kilocalories: Double, date: Date) async throws {
    guard isAvailable,
      let type = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)
    else { return }
    let store = HKHealthStore()
    try await store.requestAuthorization(toShare: [type], read: [])
    let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: kilocalories)
    let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
    try await store.save(sample)
  }
}

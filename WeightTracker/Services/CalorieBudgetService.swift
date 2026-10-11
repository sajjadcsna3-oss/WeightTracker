import Foundation

enum CalorieBudgetService {
  static func estimatedTarget(profile: WeightProfile?, latestWeight: Double?) -> Double {
    let kilograms = latestWeight ?? profile?.startingKilograms ?? 0
    guard kilograms > 0 else { return 2000 }
    let maintenanceEstimate = kilograms * 30
    let weeklyPace = max(profile?.paceKilogramsPerWeek ?? 0, 0)
    let dailyDeficit = weeklyPace * 7700 / 7
    return min(max((maintenanceEstimate - dailyDeficit).rounded(toNearest: 50), 1200), 4000)
  }
}

private extension Double {
  func rounded(toNearest step: Double) -> Double { (self / step).rounded() * step }
}

//
//  AuthenticationService.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import Foundation
import LocalAuthentication

enum AuthenticationService {
  static var isAvailable: Bool {
    let context = LAContext()
    var error: NSError?
    return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
  }
    static func authenticate() async -> Bool {
    let context = LAContext()
    do {
      return try await context.evaluatePolicy(
        .deviceOwnerAuthentication,
        localizedReason: "Unlock your weight tracker")
    } catch { return false }
  }
}

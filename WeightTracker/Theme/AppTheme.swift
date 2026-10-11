//
//  theme.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI

enum AppTheme {
  static let background = Color(red: 0.967, green: 0.961, blue: 0.949)
  static let sidebar = Color(red: 0.928, green: 0.922, blue: 0.907)
  static let ink = Color(red: 0.067, green: 0.071, blue: 0.078)
  static let lime = Color(red: 0.73, green: 0.96, blue: 0.32)
  static let violet = Color(red: 0.52, green: 0.43, blue: 0.98)
  static let stroke = Color(red: 0.88, green: 0.87, blue: 0.84)
}

extension AppTheme {
  static let purple = violet
  static let border = stroke
  static let black = ink
}

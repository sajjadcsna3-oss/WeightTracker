//
//  WeightEntry.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import Foundation
import SwiftData

@Model
final class WeightEntry {
    var id: UUID
    var date: Date
    var kilograms: Double
    var bodyFatPercent: Double?
    var note: String
    var source: String = "Manual"

    init(
        date: Date,
        kilograms: Double,
        bodyFatPercent: Double? = nil,
        note: String = "",
        source: String = "Manual"
    ) {
        self.id = UUID()
        self.date = date
        self.kilograms = kilograms
        self.bodyFatPercent = bodyFatPercent
        self.note = note
        self.source = source
    }
}

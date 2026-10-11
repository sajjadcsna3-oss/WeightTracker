//
//  ContentView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

//
//  ContentView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftUI
import SwiftData

enum AppSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case log = "Log"
    case trends = "Trends"
    case forecast = "Forecast"
    case bmi = "BMI"
    case mealLens = "Meal Lens"
    case challenges = "Challenges"
    case settings = "Settings"

    var id: String { rawValue }
}

struct ContentView: View {
    // MARK: - State
    @State private var selected: AppSection = .log
    @State private var mealLensDestination: MealLensDestination = .scan

    // MARK: - Body
    var body: some View {
        HStack(spacing: 0) {

            // Sidebar
            SidebarView(selected: $selected, mealLensDestination: $mealLensDestination)

            Rectangle()
                .fill(AppTheme.stroke)
                .frame(width: 1)

            // Main Content
            Group {
                switch selected {

                case .overview:
                    OverviewView {
                        selected = .log
                    }

                case .log:
                    WeightLogView()

                case .trends:
                    TrendsView()

                case .forecast:
                    ForecastView()

                case .bmi:
                    BMIView()

                case .mealLens:
                    MealLensView(destination: $mealLensDestination)

                case .challenges, .settings:
                    Color.clear
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .background(AppTheme.background)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .frame(minWidth: 900, minHeight: 650)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(
            for: [
                WeightProfile.self,
                WeightEntry.self,
                MealEntry.self,
                FoodItem.self
            ],
            inMemory: true
        )
}

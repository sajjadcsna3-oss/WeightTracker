import SwiftData
import SwiftUI

struct OverviewView: View {
  @Environment(\.modelContext) private var context
  @Query(sort: \WeightEntry.date, order: .forward) private var entries: [WeightEntry]
  @Query private var profiles: [WeightProfile]
  @StateObject private var vm = OverviewViewModel()
  @State private var selectedEntry: WeightEntry?
  @State private var showHistory = false
  var onOpenLog: () -> Void = {}

  private var profile: WeightProfile? { profiles.first }
  private var latest: WeightEntry? { entries.last }
  private var previous: WeightEntry? { entries.count > 1 ? entries[entries.count - 2] : nil }
  private var last30: [WeightEntry] {
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
    return entries.filter { $0.date >= cutoff }
  }

  var body: some View {
    GeometryReader { proxy in
      let narrow = proxy.size.width < 760
      let compactHeight = proxy.size.height < 780

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          header
          if let profile {
            CurrentWeightCard(
              current: latest?.kilograms, previous: previous?.kilograms,
              start: profile.startingKilograms, goal: profile.goalKilograms)
            stats(profile, narrow: narrow)
            dashboardCards(profile, narrow: narrow)
          } else {
            ProgressView("Preparing your profile...")
          }
          if !compactHeight {
            footerActions
          }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 23)
        .frame(maxWidth: .infinity, alignment: .topLeading)
      }
    }
    .background(AppTheme.background)
    .ignoresSafeArea(edges: .top)

    .sheet(isPresented: $vm.showLogSheet) {
      LogWeightSheet(initialWeight: latest?.kilograms ?? profile?.startingKilograms ?? 70) {
        kilograms, date, bodyFat, note, existing, modelContext in
        try vm.save(
          kilograms: kilograms, date: date, bodyFat: bodyFat, note: note, existing: existing,
          context: modelContext)
      }
    }
    .sheet(isPresented: $vm.showGoalSheet) {
      if let profile { GoalSettingsSheet(profile: profile) }
    }
    .sheet(isPresented: $showHistory) {
      WeightHistoryView(entries: entries, viewModel: vm)
    }
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 5) {
        Text(
          Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased()
        )
        .font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
        Text("Morning, \(profile?.displayName ?? "there")")
          .font(.system(size: 25, weight: .bold)).tracking(-1)
      }
      Spacer()
      Label(
        syncText,
        systemImage: profile?.healthSyncEnabled == true ? "heart" : "checkmark.circle"
      )
        .font(.system(size: 12)).foregroundStyle(.secondary).padding(11)
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(AppTheme.stroke))
      Button {
        vm.showLogSheet = true
      } label: {
        Label("Log weight", systemImage: "plus")
          .font(.system(size: 12, weight: .semibold))
          .padding(.horizontal, 17).frame(height: 39)
          .foregroundStyle(.white).background(AppTheme.ink)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }.buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private func stats(_ profile: WeightProfile, narrow: Bool) -> some View {
    let current = latest?.kilograms
    let change = current.map { $0 - profile.startingKilograms }
    let rate = WeightMath.weeklyRate(entries)
    let date = current.flatMap {
      WeightMath.goalDate(
        current: $0, goal: profile.goalKilograms,
        weeklyRate: rate, from: latest?.date ?? .now)
    }
    let cards = [
      OverviewStat(title: "Total change", value: change.map { String(format: "%+.1f", $0) } ?? "—", unit: "kg", icon: "arrow.down.right"),
      OverviewStat(title: "Remaining", value: current.map { String(format: "%.1f", abs(profile.goalKilograms - $0)) } ?? "—", unit: "kg", icon: "flag"),
      OverviewStat(title: "Weekly rate", value: rate.map { String(format: "%+.2f", $0) } ?? "—", unit: "kg/wk", icon: "speedometer"),
      OverviewStat(title: "Goal date", value: date?.formatted(.dateTime.day().month(.abbreviated)) ?? "—", unit: date?.formatted(.dateTime.year()) ?? "", icon: "calendar"),
    ]

    if narrow {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ForEach(cards) { card in
          StatCard(title: card.title, value: card.value, unit: card.unit, icon: card.icon)
        }
      }
    } else {
      HStack(spacing: 12) {
        ForEach(cards) { card in
          StatCard(title: card.title, value: card.value, unit: card.unit, icon: card.icon)
        }
      }
    }
  }

  @ViewBuilder
  private func dashboardCards(_ profile: WeightProfile, narrow: Bool) -> some View {
    if narrow {
      WeightChartView(entries: last30, startWeight: profile.startingKilograms)
      HStack(spacing: 12) {
        MealLensCard()
        ChallengePreviewCard()
      }
    } else {
      HStack(alignment: .top, spacing: 12) {
        WeightChartView(entries: last30, startWeight: profile.startingKilograms)
          .frame(maxWidth: .infinity)
        VStack(spacing: 12) {
          MealLensCard()
          ChallengePreviewCard()
        }
        .frame(width: 290)
      }
    }
  }

  private var footerActions: some View {
    HStack {
      Button("View and edit weight history") { showHistory = true }
      Button("Open full log", action: onOpenLog)
      Spacer()
      if profile != nil {
        Button("Edit goal") { vm.showGoalSheet = true }
      }
    }
    .buttonStyle(.borderless)
  }

  private var syncText: String {
    guard let latest else { return "No entries yet" }
    if Calendar.current.isDateInToday(latest.date) {
      return "Updated \(latest.date.formatted(date: .omitted, time: .shortened))"
    }
    return "Updated \(latest.date.formatted(.dateTime.day().month(.abbreviated)))"
  }

}

private struct OverviewStat: Identifiable {
  let title: String
  let value: String
  let unit: String
  let icon: String
  var id: String { title }
}

#if DEBUG
private struct OverviewPreview: View {
  private let container: ModelContainer

  init() {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    container = try! ModelContainer(
      for: WeightProfile.self, WeightEntry.self,
      configurations: configuration)

    let profile = WeightProfile(
      displayName: "Alex", startingKilograms: 82.4, goalKilograms: 70,
      heightCentimeters: 178, age: 31, paceKilogramsPerWeek: 0.5)
    container.mainContext.insert(profile)

    let weights: [Double] = [
      82.4, 82.1, 82.2, 81.6, 81.2, 81.4, 80.9, 80.4, 80.7, 80.1,
      79.7, 79.9, 79.2, 78.7, 78.9, 78.3, 78.0, 78.2, 77.7, 77.4,
      77.2, 76.9, 77.1, 76.6, 76.3, 76.1, 76.4, 75.9, 75.6, 75.4,
    ]
    for (offset, weight) in weights.enumerated() {
      let date = Calendar.current.date(
        byAdding: .day, value: offset - (weights.count - 1), to: .now) ?? .now
      container.mainContext.insert(WeightEntry(date: date, kilograms: weight))
    }
  }

  var body: some View {
    OverviewView()
      .modelContainer(container)
      .preferredColorScheme(.light)
      .frame(width: 890, height: 718)
  }
}

#Preview("Dashboard") {
  OverviewPreview()
}
#endif

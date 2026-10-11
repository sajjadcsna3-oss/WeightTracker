//
//  SidebarView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//
import SwiftUI
import SwiftData

struct SidebarView: View {
  @Binding var selected: AppSection
  @Binding var mealLensDestination: MealLensDestination
  @Query private var entries: [WeightEntry]
  private let items: [SidebarItem] = [
    SidebarItem(section: .overview, assetName: "OverViewIcon"),
    SidebarItem(section: .log, assetName: "LogIcon"),
    SidebarItem(section: .trends, assetName: "TrendIcon"),
    SidebarItem(section: .forecast, assetName: "ForecastIcon"),
    SidebarItem(section: .bmi, assetName: "BMIicon"),
    SidebarItem(section: .mealLens, assetName: "MealLensIcon"),
    SidebarItem(section: .challenges, assetName: "ChallengesIcon"),
    SidebarItem(section: .settings, systemName: "gearshape"),
  ]
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
       HStack(spacing: 5) {
        AppIconView(size: 28)
          
        VStack(alignment: .leading, spacing: 1) {
          Text("Weight Tracker").font(.system(size: 13, weight: .bold))
          Text("H E A L T H  A P P").font(.system(size: 7)).foregroundStyle(.secondary)
        }
      }.padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 20)
      ForEach(items) { item in
        Button {
          selected = item.section
          if item.section == .mealLens { mealLensDestination = .scan }
        } label: {
          HStack(spacing: 12) {
            sidebarIcon(item)
            Text(item.section.rawValue)
            Spacer()
            if item.section == .mealLens {
              Text("PRO")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 5).padding(.vertical, 4)
                .background(AppTheme.violet, in: RoundedRectangle(cornerRadius: 4))
            }
          }
          .font(.system(size: 13))
          .padding(.horizontal, 12)
          .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
          .contentShape(Rectangle())
          .foregroundStyle(selected == item.section ? .white : AppTheme.ink.opacity(0.8))
          .background(selected == item.section ? AppTheme.ink : .clear)
          .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .padding(.horizontal, 14)
        .padding(.bottom, 2)
        if item.section == .mealLens && selected == .mealLens {
          VStack(spacing: 2) {
            mealLensSubitem(.scan, icon: "camera")
            mealLensSubitem(.diary, icon: "book")
          }
          .padding(.horizontal, 13)
          .padding(.bottom, 4)
        }
      }
      Spacer()
      streakCard
        .padding(.horizontal, 14)
        .padding(.bottom, 16)
    }.frame(width: 212).background(AppTheme.sidebar)
  }

  private func mealLensSubitem(_ destination: MealLensDestination, icon: String) -> some View {
    Button {
      selected = .mealLens
      mealLensDestination = destination
    } label: {
      HStack(spacing: 11) {
        Image(systemName: icon).frame(width: 17)
        Text(destination.rawValue)
        Spacer()
      }
      .font(.system(size: 12))
      .padding(.leading, 27).padding(.trailing, 12)
      .frame(maxWidth: .infinity, minHeight: 36)
      .foregroundStyle(mealLensDestination == destination ? Color.white : AppTheme.ink.opacity(0.72))
      .background(mealLensDestination == destination ? AppTheme.ink : Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 9))
    }.buttonStyle(.plain)
  }

  private var streakCard: some View {
    HStack(spacing: 12) {
      Image(systemName: "flame")
        .font(.system(size: 16))
        .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.25))
      VStack(alignment: .leading, spacing: 3) {
        Text("\(WeightMath.streak(entries))-day streak")
          .font(.system(size: 12, weight: .semibold))
        Text("Logged every morning")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 13)
    .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
    .background(.white, in: RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.stroke))
  }

  @ViewBuilder
  private func sidebarIcon(_ item: SidebarItem) -> some View {
    if let assetName = item.assetName {
      Image(assetName)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 17, height: 17)
    } else if let systemName = item.systemName {
      Image(systemName: systemName)
        .frame(width: 17, height: 17)
    }
  }
}

private struct SidebarItem: Identifiable {
  let section: AppSection
  var assetName: String?
  var systemName: String?

  var id: AppSection { section }
}

#Preview {
  SidebarView(selected: .constant(.overview), mealLensDestination: .constant(.scan))
    .frame(height: 800)
}

//
//  WeightHistoryView.swift
//  WeightTracker
//
//  Created by Mac Mini on 08/10/2026.
//

import SwiftData
import SwiftUI

struct WeightHistoryView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var context
  let entries: [WeightEntry]
  @ObservedObject var viewModel: OverviewViewModel
  @State private var editing: WeightEntry?
  @State private var error: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Weight history").font(.title2.bold())
        Spacer()
        Button("Done") { dismiss() }
      }
      if entries.isEmpty {
        ContentUnavailableView(
          "No weight records", systemImage: "scalemass",
          description: Text("Log your first weight from Overview."))
      } else {
        List {
          ForEach(entries.sorted(by: { $0.date > $1.date })) { entry in
            HStack {
              VStack(alignment: .leading) {
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                if !entry.note.isEmpty {
                  Text(entry.note).font(.caption).foregroundStyle(.secondary)
                }
              }
              Spacer()
              Text(String(format: "%.1f kg", entry.kilograms)).bold()
              Button("Edit") { editing = entry }
              Button(role: .destructive) {
                context.delete(entry)
                do { try context.save() } catch { self.error = error.localizedDescription }
              } label: {
                Image(systemName: "trash")
              }
            }
          }
        }
      }
      if let error { Text(error).foregroundStyle(.red).font(.caption) }
    }.padding(24).frame(width: 650, height: 480)
      .sheet(item: $editing) { entry in
        LogWeightSheet(
          initialWeight: entry.kilograms, existing: entry,
          save: viewModel.save)
      }
  }
}

#Preview {
  WeightHistoryView(
    entries: [
      WeightEntry(date: .now, kilograms: 81.5, note: "Morning check-in"),
      WeightEntry(date: .now.addingTimeInterval(-86_400), kilograms: 81.9),
    ],
    viewModel: OverviewViewModel()
  )
  .modelContainer(for: [WeightProfile.self, WeightEntry.self], inMemory: true)
}

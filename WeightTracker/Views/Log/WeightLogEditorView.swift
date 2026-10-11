//
//  WeightLogEditorView.swift
//  WeightTracker
//
//  Created by Mac Mini on 09/10/2026.
//


import SwiftUI
import SwiftData

struct WeightLogEditorView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let entry: WeightEntry

    @State private var weight: Double
    @State private var date: Date
    @State private var bodyFat: String
    @State private var note: String
    @State private var errorMessage: String?

    init(entry: WeightEntry) {
        self.entry = entry
        _weight = State(initialValue: entry.kilograms)
        _date = State(initialValue: entry.date)
        _bodyFat = State(
            initialValue: entry.bodyFatPercent.map { String($0) } ?? ""
        )
        _note = State(initialValue: entry.note)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Edit weight")
                    .font(.system(size: 22, weight: .semibold))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("Close")
            }

            HStack {
                Button {
                    weight = max(20, (weight * 10 - 1).rounded() / 10)
                } label: {
                    Image(systemName: "minus")
                }

                Spacer()

                Text(weight, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 60, weight: .light))
                    .monospacedDigit()

                Text("kg")
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    weight = min(500, (weight * 10 + 1).rounded() / 10)
                } label: {
                    Image(systemName: "plus")
                }
            }
            .buttonStyle(.bordered)

            DatePicker(
                "Date & Time",
                selection: $date,
                displayedComponents: [.date, .hourAndMinute]
            )

            HStack {
                Text("Body fat %")
                Spacer()
                TextField("Optional", text: $bodyFat)
                    .frame(width: 100)
                    .textFieldStyle(.roundedBorder)
            }

            TextField("Note", text: $note)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
            }
        }
        .padding(28)
        .frame(width: 520, height: 390)
        .background(AppTheme.background)
    }

    private func save() {
        let trimmed = bodyFat.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let fat = Double(trimmed)

        if !trimmed.isEmpty &&
           (fat == nil || !(1...75).contains(fat!)) {
            errorMessage = "Enter a body fat value between 1 and 75%."
            return
        }

        guard date <= Date().addingTimeInterval(60) else {
            errorMessage = "You cannot log a future time."
            return
        }

        entry.kilograms = weight
        entry.date = date
        entry.bodyFatPercent = fat
        entry.note = note.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

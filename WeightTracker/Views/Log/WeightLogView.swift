//
//  WeightLogView.swift
//  WeightTracker
//
//  Created by Mac Mini on 09/10/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct WeightLogView: View {

    @Environment(\.modelContext) private var context

    @Query(sort: \WeightEntry.date, order: .reverse)
    private var entries: [WeightEntry]

    @State private var filter = "All"
    @State private var importing = false
    @State private var exporting = false
    @State private var exportDocument = WeightCSVDocument()
    @State private var selectedEntry: WeightEntry?
    @State private var message: String?

    private let background = Color(
        red: 0.965, green: 0.967, blue: 0.948
    )

    private let borderColor = Color(
        red: 0.89, green: 0.88, blue: 0.85
    )

    private let lime = Color(
        red: 0.78, green: 0.96, blue: 0.43
    )

    private var filtered: [WeightEntry] {
        switch filter {
        case "Manual":
            return entries.filter { $0.source == "Manual" }
        case "Health":
            return entries.filter { $0.source == "Apple Health" }
        default:
            return entries
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            header

            VStack(spacing: 0) {
                tableHeader

                Divider()

                if filtered.isEmpty {
                    ContentUnavailableView(
                        "No weight entries",
                        systemImage: "list.bullet.rectangle",
                        description: Text(
                            filter == "Health"
                            ? "No Health records have been imported."
                            : "Log your weight from Overview or import a CSV."
                        )
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(
                                Array(filtered.enumerated()),
                                id: \.element.id
                            ) { index, entry in

                                if index == 0 ||
                                   !Calendar.current.isDate(
                                    entry.date,
                                    equalTo: filtered[index - 1].date,
                                    toGranularity: .month
                                   ) {
                                    monthHeader(entry.date)
                                }

                                logRow(entry)
                            }
                        }
                    }
                }
            }
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 19)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 19)
                    .stroke(borderColor)
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [
                .commaSeparatedText,
                .plainText
            ]
        ) { result in
            importCSV(result)
        }
        .fileExporter(
            isPresented: $exporting,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "weight-history"
        ) { result in
            if case .failure(let error) = result {
                message = error.localizedDescription
            }
        }
        .sheet(item: $selectedEntry) { entry in
            WeightLogEditorView(entry: entry)
        }
        .alert(
            "Weight Log",
            isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )
        ) {
            Button("OK") { message = nil }
        } message: {
            Text(message ?? "")
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(entries.count) ENTRIES")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text("Log")
                    .font(.system(size: 27, weight: .bold))
            }

            Spacer(minLength: 12)

            HStack(spacing: 3) {
                ForEach(["All", "Manual", "Health"], id: \.self) { item in
                    Button {
                        filter = item
                    } label: {
                        Text(item)
                            .font(.system(
                                size: 12,
                                weight: filter == item ? .semibold : .regular
                            ))
                            .foregroundStyle(
                                filter == item ? .black : .gray
                            )
                            .padding(.horizontal, 13)
                            .frame(height: 30)
                            .background(
                                filter == item ? Color.white : Color.clear
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 9)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.black.opacity(0.055))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                importing = true
            } label: {
                headerAction("Import CSV", systemImage: "arrow.down.to.line")
            }
            .buttonStyle(.plain)

            Button {
                exportDocument = WeightCSVDocument(
                    text: CSVService.export(entries)
                )
                exporting = true
            } label: {
                headerAction("Export", systemImage: "arrow.up.to.line")
            }
            .buttonStyle(.plain)
        }
    }

    private func headerAction(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 12))
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(Color.white.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1)
            }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            column("DATE", width: 155)
            column("WEIGHT", width: 125)
            column("CHANGE", width: 115)
            column("NOTE", width: nil)
            column("SOURCE", width: 150)
        }
        .padding(.horizontal, 20)
        .frame(height: 39)
        .background(background)
    }

    private func column(
        _ title: String,
        width: CGFloat?
    ) -> some View {
        Text(title)
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(
                maxWidth: width == nil ? .infinity : nil,
                alignment: .leading
            )
            .frame(width: width, alignment: .leading)
    }

    private func monthHeader(_ date: Date) -> some View {
        Text(date.formatted(.dateTime.month(.wide).year()))
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .frame(height: 44)
    }

    private func logRow(_ entry: WeightEntry) -> some View {
        let previous = entries.first {
            $0.date < entry.date && $0.id != entry.id
        }

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(
                    entry.date.formatted(
                        .dateTime.weekday(.abbreviated)
                            .day()
                            .month(.abbreviated)
                    )
                )
                .frame(width: 155, alignment: .leading)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(
                        entry.kilograms,
                        format: .number.precision(.fractionLength(1))
                    )
                    .fontWeight(.semibold)

                    Text("kg")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 125, alignment: .leading)

                changeBadge(entry, previous: previous)
                    .frame(width: 115, alignment: .leading)

                Text(entry.note.isEmpty ? "—" : entry.note)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                sourceLabel(entry.source)
                .font(.system(size: 12))
                .frame(width: 150, alignment: .leading)
            }
            .font(.system(size: 13))
            .padding(.horizontal, 20)
            .frame(height: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedEntry = entry
            }
            .contextMenu {
                Button("Edit") {
                    selectedEntry = entry
                }

                Button("Delete", role: .destructive) {
                    context.delete(entry)
                    do {
                        try context.save()
                    } catch {
                        message = error.localizedDescription
                    }
                }
            }

            Divider()
        }
    }

    @ViewBuilder
    private func changeBadge(
        _ entry: WeightEntry,
        previous: WeightEntry?
    ) -> some View {
        if let previous {
            let delta = entry.kilograms - previous.kilograms

            Text(
                "\(delta < 0 ? "↘" : delta > 0 ? "↗" : "→") " +
                String(format: "%.1f", abs(delta))
            )
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                delta < 0
                    ? lime.opacity(0.55)
                    : delta > 0
                        ? Color.orange.opacity(0.22)
                        : Color.gray.opacity(0.12)
            )
            .clipShape(Capsule())
        } else {
            Text("—")
                .foregroundStyle(.secondary)
        }
    }

    private func sourceIcon(_ source: String) -> String {
        switch source {
        case "Apple Health": return "heart"
        case "Meal Lens": return "sparkles"
        case "CSV import": return "doc.text"
        default: return "pencil"
        }
    }

    private func sourceColor(_ source: String) -> Color {
        switch source {
        case "Apple Health": return Color(red: 1.0, green: 0.18, blue: 0.32)
        case "Meal Lens": return AppTheme.violet
        default: return .secondary
        }
    }

    private func sourceLabel(_ source: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: sourceIcon(source))
                .foregroundStyle(sourceColor(source))
                .frame(width: 15)
            Text(source)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func importCSV(
        _ result: Result<URL, Error>
    ) {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let text = try String(
                contentsOf: url,
                encoding: .utf8
            )
            let rows = try CSVService.parse(text)

            for row in rows {
                context.insert(
                    WeightEntry(
                        date: row.date,
                        kilograms: row.kilograms,
                        bodyFatPercent: row.bodyFatPercent,
                        note: row.note,
                        source: "CSV import"
                    )
                )
            }

            try context.save()
            message = "Imported \(rows.count) entries."
        } catch {
            message = error.localizedDescription
        }
    }
}

#Preview("Weight Log") {
    WeightLogView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}

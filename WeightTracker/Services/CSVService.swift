//
//  WeightCSVService.swift
//  WeightTracker
//
//  Created by Mac Mini on 09/10/2026.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct WeightCSVRow {
    let date: Date
    let kilograms: Double
    let bodyFatPercent: Double?
    let note: String
}

struct WeightCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.commaSeparatedText, .plainText]
    }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let value = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = value
    }

    func fileWrapper(
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        FileWrapper(
            regularFileWithContents: Data(text.utf8)
        )
    }
}

enum CSVService {

    static func export(_ entries: [WeightEntry]) -> String {
        let formatter = ISO8601DateFormatter()

        let rows = entries.map { entry in
            [
                formatter.string(from: entry.date),
                String(entry.kilograms),
                entry.bodyFatPercent.map { String($0) } ?? "",
                entry.note,
                entry.source
            ]
            .map(escape)
            .joined(separator: ",")
        }

        return (
            ["date,weight_kg,body_fat_percent,note,source"]
            + rows
        ).joined(separator: "\n")
    }

    static func parse(_ text: String) throws -> [WeightCSVRow] {
        let records = csvRecords(text)

        guard let first = records.first else {
            throw csvError("CSV file is empty.")
        }

        let header = first.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        }

        guard let dateIndex = header.firstIndex(of: "date"),
              let weightIndex = header.firstIndex(of: "weight_kg") else {
            throw csvError(
                "CSV requires date and weight_kg columns."
            )
        }

        let fatIndex = header.firstIndex(of: "body_fat_percent")
        let noteIndex = header.firstIndex(of: "note")

        let iso = ISO8601DateFormatter()
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.dateFormat = "yyyy-MM-dd"

        var output: [WeightCSVRow] = []

        for (index, fields) in records.dropFirst().enumerated() {
            guard fields.indices.contains(dateIndex),
                  fields.indices.contains(weightIndex) else {
                throw csvError("Missing fields at row \(index + 2).")
            }

            let rawDate = fields[dateIndex]
            let date = iso.date(from: rawDate)
                ?? dayFormatter.date(from: rawDate)

            guard let date,
                  let kg = Double(fields[weightIndex]),
                  (20...500).contains(kg) else {
                throw csvError(
                    "Invalid date or weight at row \(index + 2)."
                )
            }

            let fat = fatIndex.flatMap {
                fields.indices.contains($0)
                    ? Double(fields[$0]) : nil
            }

            let note = noteIndex.flatMap {
                fields.indices.contains($0)
                    ? fields[$0] : nil
            } ?? ""

            output.append(
                WeightCSVRow(
                    date: date,
                    kilograms: kg,
                    bodyFatPercent: fat,
                    note: note
                )
            )
        }

        return output
    }

    private static func escape(_ value: String) -> String {
        guard value.contains(",")
                || value.contains("\"")
                || value.contains("\n") else {
            return value
        }

        return "\""
            + value.replacingOccurrences(
                of: "\"", with: "\"\""
            )
            + "\""
    }

    private static func csvRecords(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false

        let characters = Array(text)
        var index = 0

        while index < characters.count {
            let char = characters[index]

            if char == "\"" {
                if inQuotes,
                   index + 1 < characters.count,
                   characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 1
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                row.append(field)
                field = ""
            } else if (char == "\n" || char == "\r")
                        && !inQuotes {
                row.append(field)
                field = ""
                if !row.allSatisfy(\.isEmpty) {
                    rows.append(row)
                }
                row = []
                if char == "\r",
                   index + 1 < characters.count,
                   characters[index + 1] == "\n" {
                    index += 1
                }
            } else {
                field.append(char)
            }

            index += 1
        }

        row.append(field)
        if !row.allSatisfy(\.isEmpty) {
            rows.append(row)
        }

        return rows
    }

    private static func csvError(_ message: String) -> Error {
        NSError(
            domain: "WeightCSV",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: message
            ]
        )
    }
}

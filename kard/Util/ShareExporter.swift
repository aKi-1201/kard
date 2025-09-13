// filepath: /Users/114-1iosclassstudent05/Desktop/kard/kard/Util/ShareExporter.swift
import Foundation
import SwiftUI
import UIKit

/// Exports a Card to temporary JSON (+ optional PNG) files for sharing (AirDrop).
struct ShareExporter {
    static func export(card: Card, store: CardStore) throws -> [URL] {
        let fm = FileManager.default
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("kard-export", isDirectory: true)
        if fm.fileExists(atPath: base.path) { try? fm.removeItem(at: base) }
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        let stem: String = {
            let trimmed = card.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return card.id.uuidString }
            let invalid = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_")).inverted
            let cleaned = trimmed.components(separatedBy: invalid).joined(separator: "_")
            return cleaned.isEmpty ? card.id.uuidString : cleaned
        }()
        var exportCard = card
        exportCard.updatedAt = Date()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportCard)
        let jsonURL = base.appendingPathComponent("\(stem).json")
        try data.write(to: jsonURL, options: .atomic)
        var urls: [URL] = [jsonURL]
        if let img = store.image(for: card), let pngData = img.pngData() {
            let pngURL = base.appendingPathComponent("\(stem).png")
            try pngData.write(to: pngURL, options: .atomic)
            urls.append(pngURL)
        }
        return urls
    }
}

/// UIKit share sheet constrained (best-effort) to AirDrop by excluding other activities.
struct AirDropShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.excludedActivityTypes = [
            .addToReadingList, .assignToContact, .copyToPasteboard, .mail, .message, .openInIBooks,
            .postToFacebook, .postToFlickr, .postToTencentWeibo, .postToTwitter, .postToVimeo,
            .postToWeibo, .print, .saveToCameraRoll, .markupAsPDF
        ]
        return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

// filepath: /Users/114-1iosclassstudent05/Desktop/kard/kard/Model/CardStore.swift
// Stage 1: In-memory persistence stub
import Foundation
import Combine
import SwiftUI
import UIKit

final class CardStore: ObservableObject {
    @Published private(set) var cards: [Card] = []
    
    var myCard: Card? { cards.first }
    
    // Exposed internally for helpers (palette store reuses directory path optional)
    let directoryURL: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("cards", isDirectory: true)
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted]
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    init() {
        loadFromDisk()
        if cards.isEmpty { seed() } // only seed if no persisted cards
    }
    
    // MARK: - Public API
    func add(_ card: Card) { cards.append(card) }
    func update(_ card: Card) {
        if let idx = cards.firstIndex(where: { $0.id == card.id }) { cards[idx] = card; try? write(card) }
    }
    
    /// Update an existing card and optionally replace (or add) its image, persisting both.
    func update(_ card: Card, newImage: UIImage?) {
        var updated = card
        if let newImage = newImage {
            // Ensure directory
            try? ensureDirectory()
            var filename = updated.imageFilename
            if filename.isEmpty { filename = "\(updated.id.uuidString).png" }
            let url = directoryURL.appendingPathComponent(filename)
            if let data = newImage.pngData() { try? data.write(to: url, options: .atomic) }
            updated.imageFilename = filename
        }
        if let idx = cards.firstIndex(where: { $0.id == updated.id }) { cards[idx] = updated }
        try? write(updated)
    }
    func remove(_ card: Card) {
        cards.removeAll { $0.id == card.id }
        deleteFiles(for: card)
    }
    
    /// Persist a new card and image (if provided) then insert into store.
    func persistNew(card: Card, image: UIImage?) throws {
        try ensureDirectory()
        if let image = image {
            let imageURL = directoryURL.appendingPathComponent(card.imageFilename)
            if let data = image.pngData() { try data.write(to: imageURL, options: .atomic) }
        }
        try write(card)
        DispatchQueue.main.async { [weak self] in
            self?.cards.append(card)
        }
    }
    
    func image(for card: Card) -> UIImage? {
        guard !card.imageFilename.isEmpty else { return nil }
        let url = directoryURL.appendingPathComponent(card.imageFilename)
        return UIImage(contentsOfFile: url.path)
    }
    
    // MARK: - Disk IO
    private func loadFromDisk() {
        do {
            try ensureDirectory()
            let jsonFiles = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }
            var loaded: [Card] = []
            for file in jsonFiles {
                do {
                    let data = try Data(contentsOf: file)
                    let card = try decoder.decode(Card.self, from: data)
                    loaded.append(card)
                } catch { continue }
            }
            loaded.sort { $0.createdAt < $1.createdAt }
            self.cards = loaded
        } catch {
            // Silent fail acceptable for MVP
        }
    }
    
    private func write(_ card: Card) throws {
        try ensureDirectory()
        let url = directoryURL.appendingPathComponent("\(card.id.uuidString).json")
        var mutableCard = card
        mutableCard.updatedAt = Date()
        let data = try encoder.encode(mutableCard)
        try data.write(to: url, options: .atomic)
    }
    
    private func deleteFiles(for card: Card) {
        let jsonURL = directoryURL.appendingPathComponent("\(card.id.uuidString).json")
        try? FileManager.default.removeItem(at: jsonURL)
        if !card.imageFilename.isEmpty {
            let imgURL = directoryURL.appendingPathComponent(card.imageFilename)
            try? FileManager.default.removeItem(at: imgURL)
        }
    }
    
    private func ensureDirectory() throws {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDir) || !isDir.boolValue {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Seed
    private func seed() {
        guard cards.isEmpty else { return }
        let me = Card(name: "My Name", title: "iOS Engineer", company: "Kard", phone: "+1 (555) 000-0000", email: "me@example.com", notes: "Owner", backgroundColor: "#0F1720")
        let sample = Card(name: "Ava Stone", title: "Product Manager", company: "Nimbus Labs", phone: "+1 (555) 741-2233", email: "ava@nimbuslabs.com", notes: "Met at WWDC", backgroundColor: "#0F1720")
        self.cards = [me, sample]
    }
    
    // MARK: - Import
    /// Import a card from a JSON file (and optional PNG located next to it). If UUID collides, new UUID assigned.
    @discardableResult
    func importCard(jsonURL: URL) throws -> Card {
        let data = try Data(contentsOf: jsonURL)
        var card = try decoder.decode(Card.self, from: data)
        // Collision check
        if cards.contains(where: { $0.id == card.id }) {
            let oldID = card.id
            let newID = UUID()
            card = Card(id: newID, name: card.name, title: card.title, company: card.company, phone: card.phone, email: card.email, notes: card.notes, backgroundColor: card.backgroundColor, imageFilename: card.imageFilename.isEmpty ? "" : "\(newID.uuidString).png", createdAt: card.createdAt, updatedAt: card.updatedAt)
            // We'll remap image filename below if needed
            if !card.imageFilename.isEmpty { card.imageFilename = "\(newID.uuidString).png" }
            // old image filename will be ignored
            _ = oldID // silence unused
        }
        // Copy image if exists (same stem .png)
        if !card.imageFilename.isEmpty {
            let possiblePNG = jsonURL.deletingPathExtension().appendingPathExtension("png")
            if FileManager.default.fileExists(atPath: possiblePNG.path) {
                try ensureDirectory()
                let dest = directoryURL.appendingPathComponent(card.imageFilename)
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: possiblePNG, to: dest)
            } else {
                // If png missing, drop reference
                card.imageFilename = ""
            }
        }
        try write(card)
        DispatchQueue.main.async { [weak self] in
            self?.cards.append(card)
        }
        return card
    }
}

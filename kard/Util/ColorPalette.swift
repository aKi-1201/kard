// ColorPalette.swift
// Stage 3: Persisted preset background colors for cards (JSON based)
import Foundation
import SwiftUI
import Combine

final class ColorPalette: ObservableObject {
    static let shared = ColorPalette()
    @Published private(set) var colors: [String] = [] // Hex strings with leading '#'
    private let filename = "palette.json"
    private struct PaletteFile: Codable { var colors: [String] }
    private let defaultColors = ["#0F1720", "#0A84FF", "#1E3A5F", "#22363F", "#D4AF37", "#B87333"] // + Gold, Copper
    private let requiredColors = ["#D4AF37", "#B87333"] // ensure gold & copper present
    
    private init() {
        load()
    }
    
    private var fileURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("cards", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(filename)
    }
    
    private func load() {
        let url = fileURL
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(PaletteFile.self, from: data),
           decoded.colors.isEmpty == false {
            var loaded = decoded.colors
            // Migration: ensure required colors exist
            for hex in requiredColors where loaded.contains(hex) == false { loaded.append(hex) }
            self.colors = loaded
            // Persist back if we added anything
            if loaded.count != decoded.colors.count { persist() }
        } else {
            // Write defaults (includes metallic gold & copper)
            self.colors = defaultColors
            persist()
        }
    }
    
    private func persist() {
        let url = fileURL
        let payload = PaletteFile(colors: colors)
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

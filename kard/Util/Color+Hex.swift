// filepath: /Users/114-1iosclassstudent05/Desktop/kard/kard/Util/Color+Hex.swift
// Stage 1: Hex -> Color helper & palette constants
import SwiftUI

extension Color {
    init?(hex: String) {
        var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if raw.hasPrefix("#") { raw.removeFirst() }
        guard raw.count == 6, let val = Int(raw, radix: 16) else { return nil }
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
    
    struct KardPalette {
        static let background = Color(hex: "0B0B0D")!
        static let card = Color(hex: "0F1720")!
        static let accent = Color(hex: "0A84FF")!
    }
}

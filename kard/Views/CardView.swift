// filepath: /Users/114-1iosclassstudent05/Desktop/kard/kard/Views/CardView.swift
// Stage 1: Visual representation of a card (single horizontal template)
import SwiftUI

struct CardView: View {
    let card: Card
    
    private var bgColor: Color {
        Color(hex: card.backgroundColor.replacingOccurrences(of: "#", with: "")) ?? Color.KardPalette.card
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            MetallicBackground(base: bgColor, cornerRadius: 18)
            VStack(alignment: .leading, spacing: 6) {
                Text(card.name)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                Text("\(card.title) • \(card.company)")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                Spacer(minLength: 4)
                VStack(alignment: .leading, spacing: 2) {
                    if !card.phone.isEmpty { Text(card.phone).font(.caption2).foregroundColor(.white.opacity(0.7)) }
                    if !card.email.isEmpty { Text(card.email).font(.caption2).foregroundColor(.white.opacity(0.7)) }
                }
            }
            .padding(16)
        }
        .aspectRatio(1.59, contentMode: .fit)
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Metallic Background
private struct MetallicBackground: View {
    let base: Color
    var cornerRadius: CGFloat = 18
    var body: some View {
        ZStack {
            // Base color
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(base)
            // Diagonal specular highlight
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(LinearGradient(colors: [
                    Color.white.opacity(0.35),
                    .clear,
                    Color.black.opacity(0.35)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blendMode(.overlay)
            // Subtle cross sheen
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(LinearGradient(colors: [
                    Color.white.opacity(0.18),
                    .clear,
                    Color.black.opacity(0.18)
                ], startPoint: .top, endPoint: .bottom))
                .blendMode(.overlay)
            // Angular shimmer ring
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AngularGradient(gradient: Gradient(colors: [
                    Color.white.opacity(0.10), .clear, Color.black.opacity(0.10), .clear, Color.white.opacity(0.08)
                ]), center: .center))
                .blendMode(.overlay)
            // Brushed metal hairline texture
            BrushedOverlay(intensity: 0.08, lineWidth: 0.6, spacing: 2, angle: .degrees(-8))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .blendMode(.overlay)
                .opacity(0.9)
            // Soft vignette to emphasize depth
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                .blendMode(.overlay)
        }
        .compositingGroup() // ensure blend modes apply within the shape
    }
}

// Brushed metal overlay using fine parallel lines
private struct BrushedOverlay: View {
    var intensity: Double = 0.08
    var lineWidth: CGFloat = 0.5
    var spacing: CGFloat = 2
    var angle: Angle = .degrees(0)
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lines = stride(from: 0.0, through: size.height, by: spacing)
                let color = Color.white.opacity(intensity)
                for y in lines {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: lineWidth)
                    context.fill(Path(CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)), with: .color(color))
                }
            }
            .blur(radius: 0.3)
            .rotationEffect(angle, anchor: .center)
        }
        .allowsHitTesting(false)
    }
}

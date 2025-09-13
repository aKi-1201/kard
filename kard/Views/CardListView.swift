// filepath: /Users/114-1iosclassstudent05/Desktop/kard/kard/Views/CardListView.swift
// Stage 1: Card list container
import SwiftUI

struct CardListView: View {
    let cards: [Card]
    @EnvironmentObject private var store: CardStore
    var body: some View {
        LazyVStack(spacing: 20) {
            ForEach(cards) { card in
                NavigationLink(destination: CardDetailView(card: card).environmentObject(store)) {
                    CardView(card: card)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 140) // space for floating button
    }
}

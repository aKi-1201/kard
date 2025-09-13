// filepath: /Users/114-1iosclassstudent05/Desktop/kard/kard/Views/HomeView.swift
// Stage 1: Home screen
import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var store: CardStore
    @State private var showingScan = false // Stage 2: sheet control
    @State private var showingImporter = false
    @State private var importError: String? = nil
    @State private var importCount: Int = 0
    // New: creation mode selection
    @State private var showNewCardOptions = false
    @State private var scanAutoOpen = true
    
    var body: some View {
        NavigationView { // Added NavigationView for detail navigation
            ZStack(alignment: .bottomTrailing) {
                Color.KardPalette.background
                    .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if let my = store.myCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("My Card")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 20)
                                NavigationLink(destination: CardDetailView(card: my).environmentObject(store)) {
                                    CardView(card: my)
                                        .padding(.horizontal, 20)
                                }.buttonStyle(.plain)
                            }
                        }
                        if store.cards.dropFirst().isEmpty == false {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Cards")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 20)
                                CardListView(cards: Array(store.cards.dropFirst()))
                                    .environmentObject(store)
                            }
                        }
                    }
                    .padding(.top, 32)
                }
                newCardButton
            }
            .navigationTitle("Kard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .sheet(isPresented: $showingScan) {
                ScanView(autoOpenPicker: scanAutoOpen)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingImporter) { ImportPicker(onURLs: handleImport) }
            .alert(importError ?? "Imported \(importCount) card(s)", isPresented: Binding(get: { importError != nil || importCount > 0 }, set: { if !$0 { importError = nil; importCount = 0 } })) {
                Button("OK", role: .cancel) { importError = nil; importCount = 0 }
            }
            .confirmationDialog("New Card", isPresented: $showNewCardOptions, titleVisibility: .visible) {
                Button("Take Photo") { scanAutoOpen = true; showingScan = true }
                Button("Manual Entry Only") { scanAutoOpen = false; showingScan = true }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingImporter = true }) { Image(systemName: "square.and.arrow.down") }.accessibilityLabel("Import Card JSON")
        }
    }
    
    private var newCardButton: some View {
        Button(action: { showNewCardOptions = true }) {
            Image(systemName: "plus")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(Color.KardPalette.accent)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 6)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 32)
        .accessibilityLabel("New Card")
    }
    
    private func handleImport(_ urls: [URL]) {
        var success = 0
        for url in urls {
            guard url.pathExtension.lowercased() == "json" else { continue }
            do { _ = try store.importCard(jsonURL: url); success += 1 } catch { importError = "Failed to import one or more cards." }
        }
        if success > 0 && importError == nil { importCount = success }
    }
}

// MARK: - ImportPicker
private struct ImportPicker: UIViewControllerRepresentable {
    var onURLs: ([URL]) -> Void
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Allow user to multi-select JSON plus optional PNG assets; we only process JSON files, but letting them pick both keeps them together when shared.
        let types: [UTType] = [.json, .png]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onURLs: onURLs) }
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onURLs: ([URL]) -> Void
        init(onURLs: @escaping ([URL]) -> Void) { self.onURLs = onURLs }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { onURLs(urls) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { }
    }
}

// CardDetailView.swift
// Stage 3: View & edit an existing card (fields, color, image) + delete

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CardDetailView: View {
    @EnvironmentObject private var store: CardStore
    @Environment(\.dismiss) private var dismiss
    @State private var working: Card
    @State private var pickedImage: UIImage? // New (unsaved) image
    @State private var showingImagePicker = false
    @State private var useCamera = false
    @State private var showDeleteConfirm = false
    @State private var isSaving = false
    @ObservedObject private var palette = ColorPalette.shared
    @State private var shareItems: [Any] = []
    @State private var showingShare = false
    @State private var isExporting = false
    @State private var exportError: String? = nil
    
    init(card: Card) {
        _working = State(initialValue: card)
    }
    
    private var original: Card? { store.cards.first(where: { $0.id == working.id }) }
    
    private var hasChanges: Bool {
        guard let original else { return true }
        if original.name != working.name { return true }
        if original.title != working.title { return true }
        if original.company != working.company { return true }
        if original.phone != working.phone { return true }
        if original.email != working.email { return true }
        if original.notes != working.notes { return true }
        if original.backgroundColor != working.backgroundColor { return true }
        if pickedImage != nil { return true }
        return false
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                previewCard
                imageSection
                formSection
                colorSection
                deleteSection
            }
            .padding(20)
        }
        .background(Color.KardPalette.background.ignoresSafeArea())
        .navigationTitle(working.name.isEmpty ? "Card" : working.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .sheet(isPresented: $showingImagePicker) { imagePickerSheet }
        .sheet(isPresented: $showingShare) { AirDropShareSheet(items: shareItems) }
        .confirmationDialog("Delete this card?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Card", role: .destructive, action: deleteCard)
            Button("Cancel", role: .cancel) { }
        }
        .alert(exportError ?? "", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) { exportError = nil }
        }
        .onAppear { useCamera = UIImagePickerController.isSourceTypeAvailable(.camera) }
    }
    
    // MARK: - Sections
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let img = displayImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(1.59, contentMode: .fit)
                    .cornerRadius(18)
                    .shadow(radius: 6)
            } else {
                CardView(card: working)
            }
            HStack(spacing: 12) {
                Button(action: { showingImagePicker = true }) {
                    Label(pickedImage == nil ? (displayImage == nil ? "Add Image" : "Replace Image") : "Change Image", systemImage: "photo.on.rectangle")
                        .font(.footnote.bold())
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.KardPalette.accent)
                        .clipShape(Capsule())
                }
                if pickedImage != nil {
                    Button(role: .destructive) { pickedImage = nil } label: {
                        Text("Discard New Image")
                            .font(.footnote)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.red.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private var imageSection: some View { EmptyView() } // kept for possible future metadata
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Field("Name *", text: $working.name)
            Field("Title", text: $working.title)
            Field("Company", text: $working.company)
            Field("Phone", text: $working.phone, keyboard: .phonePad)
            Field("Email", text: $working.email, keyboard: .emailAddress)
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes").font(.caption).foregroundColor(.white.opacity(0.5))
                TextEditor(text: $working.notes)
                    .frame(minHeight: 90)
                    .padding(10)
                    .background(Color.KardPalette.card)
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .overlay(Text(working.notes.isEmpty ? "Notes" : "").foregroundColor(.white.opacity(0.35)).padding(.horizontal, 16).padding(.vertical, 14), alignment: .topLeading)
            }
        }
        .foregroundColor(.white)
    }
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Color").font(.caption).foregroundColor(.white.opacity(0.5))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                ForEach(palette.colors, id: \.self) { hex in
                    let clean = hex.replacingOccurrences(of: "#", with: "")
                    Circle()
                        .fill(Color(hex: clean) ?? .black)
                        .overlay(Circle().stroke(Color.white.opacity(working.backgroundColor == hex ? 0.9 : 0.15), lineWidth: working.backgroundColor == hex ? 3 : 1))
                        .frame(width: 36, height: 36)
                        .onTapGesture { withAnimation { working.backgroundColor = hex } }
                        .accessibilityLabel(hex)
                }
            }
        }
        .foregroundColor(.white)
    }
    
    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().background(Color.white.opacity(0.2))
            Button(role: .destructive) { showDeleteConfirm = true } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Card")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.2))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") { dismiss() }
        }
        ToolbarItem(placement: .primaryAction) {
            Button(action: share) {
                if isExporting { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) } else { Image(systemName: "square.and.arrow.up") }
            }
            .disabled(isExporting)
            .accessibilityLabel("Share via AirDrop")
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(action: save) {
                if isSaving { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) } else { Text("Save") }
            }
            .disabled(!hasChanges || working.name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
        }
    }
    
    // MARK: - Helpers
    private var displayImage: UIImage? {
        if let pickedImage { return pickedImage }
        return store.image(for: working)
    }
    
    private func save() {
        guard hasChanges, working.name.trimmingCharacters(in: .whitespaces).isEmpty == false else { return }
        isSaving = true
        let cardToSave = working
        let newImg = pickedImage
        DispatchQueue.global(qos: .userInitiated).async {
            store.update(cardToSave, newImage: newImg)
            DispatchQueue.main.async {
                isSaving = false
                pickedImage = nil
                // Refresh working copy from store (ensures updatedAt updated)
                if let refreshed = store.cards.first(where: { $0.id == cardToSave.id }) { working = refreshed }
            }
        }
    }
    
    private func deleteCard() {
        store.remove(working)
        dismiss()
    }
    
    private var imagePickerSheet: some View {
        ImagePicker(sourceType: useCamera ? .camera : .photoLibrary) { img in
            if let img { pickedImage = ImageCropper.cropCenterToCardAspect(img) }
            showingImagePicker = false
        }
        .ignoresSafeArea()
    }
    
    private func share() {
        guard !isExporting else { return }
        isExporting = true
        let cardToShare = working
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let urls = try ShareExporter.export(card: cardToShare, store: store)
                DispatchQueue.main.async {
                    shareItems = urls
                    isExporting = false
                    showingShare = true
                }
            } catch {
                DispatchQueue.main.async {
                    exportError = "Failed to export card."; isExporting = false
                }
            }
        }
    }
}

// MARK: - Field helper (duplicated lightweight from ScanView)
private struct Field: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    init(_ title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) {
        self.title = title
        self._text = text
        self.keyboard = keyboard
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.white.opacity(0.5))
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding(10)
                .background(Color.KardPalette.card)
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }
}

// MARK: - UIKit Image Picker (local copy)
private struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    var onImage: (UIImage?) -> Void
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage?) -> Void
        init(onImage: @escaping (UIImage?) -> Void) { self.onImage = onImage }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onImage(nil); picker.dismiss(animated: true) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = (info[.originalImage] as? UIImage)
            onImage(image)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    NavigationView {
        CardDetailView(card: Card(name: "Jane Appleseed", title: "Designer", company: "Fruit Co", phone: "555-111-2222", email: "jane@fruit.co"))
            .environmentObject(CardStore())
    }
}

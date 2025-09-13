// ScanView.swift
// Stage 2: Image capture + manual metadata form & save
import SwiftUI
import UIKit

struct ScanView: View { // Ensure correct name (was HomeView causing redeclaration)
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CardStore
    @StateObject private var vm = CardCreationViewModel()
    @State private var showingPicker = false
    @State private var useCamera = false
    @State private var showError = false
    // New: control whether to auto-open picker on appear (manual mode disables this)
    var autoOpenPicker: Bool = true
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("New Card")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .background(Color.KardPalette.background.ignoresSafeArea())
                .alert(isPresented: $showError) {
                    Alert(title: Text("Error"), message: Text(vm.errorMessage ?? "Unknown"), dismissButton: .default(Text("OK")))
                }
        }
        .sheet(isPresented: $showingPicker) {
            ImagePicker(sourceType: useCamera ? .camera : .photoLibrary) { image in
                if let image = image { vm.image = ImageCropper.cropCenterToCardAspect(image) }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            // Decide whether camera available
            useCamera = UIImagePickerController.isSourceTypeAvailable(.camera)
            if autoOpenPicker, vm.image == nil { showingPicker = true }
        }
    }
    
    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let img = vm.image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(1.59, contentMode: .fit)
                        .cornerRadius(18)
                        .shadow(radius: 6)
                        .overlay(alignment: .topTrailing) {
                            Button(action: { showingPicker = true }) {
                                Image(systemName: "camera.rotate")
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Capsule())
                            }
                            .padding(8)
                        }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Capture a card")
                            .foregroundColor(.white.opacity(0.7))
                        Button(action: { showingPicker = true }) {
                            Text("Open \(useCamera ? "Camera" : "Library")")
                                .font(.footnote.bold())
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Color.KardPalette.accent)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
                formSection
            }
            .padding(20)
        }
    }
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Group {
                Field("Name *", text: $vm.name)
                Field("Title", text: $vm.title)
                Field("Company", text: $vm.company)
                Field("Phone", text: $vm.phone, keyboard: .phonePad)
                Field("Email", text: $vm.email, keyboard: .emailAddress)
                TextEditor(text: $vm.notes)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.KardPalette.card)
                    .cornerRadius(12)
                    .overlay(Text(vm.notes.isEmpty ? "Notes" : "").foregroundColor(.white.opacity(0.35)).padding(12), alignment: .topLeading)
            }
        }
        .foregroundColor(.white)
    }
    
    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .disabled(vm.isSaving)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(action: save) {
                if vm.isSaving { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) } else { Text("Save") }
            }
            .disabled(!vm.canSave)
        }
    }
    
    private func save() {
        guard vm.canSave else { return }
        vm.isSaving = true
        let card = vm.makeCard()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try store.persistNew(card: card, image: vm.image)
                DispatchQueue.main.async {
                    vm.isSaving = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    vm.errorMessage = error.localizedDescription
                    vm.isSaving = false
                    showError = true
                }
            }
        }
    }
}

// MARK: - Field helper
private struct Field: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    // Added convenience init matching call sites without 'title:' label
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

// MARK: - UIKit Image Picker Wrapper
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
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
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

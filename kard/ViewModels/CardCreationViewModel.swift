// CardCreationViewModel.swift
// Stage 2: View model for manual metadata entry & saving
import Foundation
import UIKit
import Combine

final class CardCreationViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var name: String = ""
    @Published var title: String = ""
    @Published var company: String = ""
    @Published var phone: String = ""
    @Published var email: String = ""
    @Published var notes: String = ""
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving }
    
    func makeCard() -> Card {
        let id = UUID()
        let filename = image == nil ? "" : "\(id.uuidString).png"
        return Card(id: id,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                    phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    backgroundColor: "#0F1720",
                    imageFilename: filename,
                    createdAt: Date(),
                    updatedAt: Date())
    }
}

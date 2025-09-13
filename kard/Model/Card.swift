// filepath: /Users/114-1iosclassstudent05/Desktop/kard/kard/Model/Card.swift
// Stage 1: Card model (in-memory only)
import Foundation

struct Card: Identifiable, Hashable, Codable { // Added Codable
    let id: UUID
    var name: String
    var title: String
    var company: String
    var phone: String
    var email: String
    var notes: String
    var backgroundColor: String // hex string like #RRGGBB
    var imageFilename: String // png filename stored in cards directory
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String, title: String, company: String, phone: String, email: String, notes: String = "", backgroundColor: String = "#0F1720", imageFilename: String = "", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.title = title
        self.company = company
        self.phone = phone
        self.email = email
        self.notes = notes
        self.backgroundColor = backgroundColor
        self.imageFilename = imageFilename
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

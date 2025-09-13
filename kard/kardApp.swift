//
//  kardApp.swift
//  kard
//
//  Created by 114-1iosClassStudent05 on 2025/9/13.
//
//  Stage 1: Real App entry point.
import SwiftUI

@main
struct KardApp: App {
    @StateObject private var store = CardStore()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
        }
    }
}

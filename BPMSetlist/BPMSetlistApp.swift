//
//  BPMSetlistApp.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import SwiftUI
import SwiftData

@main
struct BPMSetlistApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, delete existing data and try again
            print("Failed to create ModelContainer: \(error)")
            print("Attempting to delete existing store and recreate...")
            
            // Delete the existing store
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            
            // Also try to remove any related files
            let storeDirectory = URL.applicationSupportDirectory
            if let contents = try? FileManager.default.contentsOfDirectory(at: storeDirectory, includingPropertiesForKeys: nil) {
                for file in contents where file.lastPathComponent.contains("default") {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after cleanup: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

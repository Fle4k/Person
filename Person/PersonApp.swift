//
//  PersonApp.swift
//  Person
//
//  Created by Shahin on 25.03.25.
//

import SwiftUI

@main
struct PersonApp: App {
    @StateObject private var viewModel = PersonViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}

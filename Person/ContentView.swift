//
//  ContentView.swift
//  Person
//
//  Created by Shahin on 25.03.25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isDrawerPresented = false
    @State private var hasGeneratedNames = false
    @StateObject private var viewModel = PersonViewModel()
    @StateObject private var nameStore = NameStore()
    
    init() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.dynamicText)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.dynamicText)]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NameGeneratorView(
                    viewModel: viewModel,
                    showingGeneratedNames: $isDrawerPresented,
                    hasGeneratedNames: $hasGeneratedNames
                )
                .environmentObject(nameStore)
            }
            .tint(Color.dynamicText)
            .tabItem {
                Label("Neuer Name", systemImage: "person")
            }
            .tag(0)
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.width < -50 {
                            withAnimation {
                                selectedTab = min(selectedTab + 1, 1)
                            }
                        } else if gesture.translation.width > 50 {
                            withAnimation {
                                selectedTab = max(selectedTab - 1, 0)
                            }
                        }
                    }
            )
            
            NavigationStack {
                FavoritesView()
                    .environmentObject(viewModel)
                    .environmentObject(nameStore)
            }
            .tint(Color.dynamicText)
            .tabItem {
                Label("Favoriten", systemImage: "star.fill")
            }
            .tag(1)
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.width < -50 {
                            withAnimation {
                                selectedTab = min(selectedTab + 1, 1)
                            }
                        } else if gesture.translation.width > 50 {
                            withAnimation {
                                selectedTab = max(selectedTab - 1, 0)
                            }
                        }
                    }
            )
        }
        .tabViewStyle(.automatic)
        .animation(.easeInOut(duration: 0.5), value: selectedTab)
    }
}

#Preview {
    ContentView()
        .environmentObject(PersonViewModel())
        .environmentObject(NameStore())
}

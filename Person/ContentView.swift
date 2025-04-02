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
    @State private var favoritesRefreshID = UUID()
    @StateObject private var viewModel = PersonViewModel()
    @StateObject private var nameStore = NameStore()
    
    init() {
        // Customize tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.dynamicText)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.dynamicText)]
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Remove navigation bar divider
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.shadowColor = .clear
        navigationBarAppearance.backgroundColor = .systemBackground
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Set tint color for all UI elements including alerts
        UIView.appearance().tintColor = UIColor(Color.dynamicText)
        
        // Set alert button appearance specifically
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(Color.dynamicText)
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
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshFavorites"))) { _ in
                        // Force reload of NameStore favorites
                        nameStore.loadFavorites()
                    }
            }
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
        .onChange(of: selectedTab) { oldTab, newTab in
            if newTab == 1 {
                favoritesRefreshID = UUID()
                NotificationCenter.default.post(name: NSNotification.Name("RefreshFavorites"), object: nil)
            }
        }
        .tabViewStyle(.automatic)
        .animation(.easeInOut(duration: 0.5), value: selectedTab)
        .tint(Color.dynamicText)
    }
}

#Preview {
    ContentView()
        .environmentObject(PersonViewModel())
        .environmentObject(NameStore())
}

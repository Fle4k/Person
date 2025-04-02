import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var nameStore: NameStore
    @State private var showingDeleteConfirmation = false
    @State private var showingRemoveAlert = false
    @State private var personToRemove: Person?
    @State private var refreshID = UUID()
    
    var sortedFavorites: [Person] {
        nameStore.favorites.sorted { (person1, person2) in
            let date1 = person1.favoritedAt ?? .distantPast
            let date2 = person2.favoritedAt ?? .distantPast
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedFavorites) { person in
                    NavigationLink {
                        PersonDetailView(person: person)
                            .id(person.id)
                    } label: {
                        PersonRow(person: person, onStarTap: {
                            personToRemove = person
                            showingRemoveAlert = true
                        })
                    }
                }
            }
            .listStyle(.plain)
            .id(refreshID)
            .onAppear {
                print("Debug - FavoritesView appeared: \(nameStore.favorites.count) favorites")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshFavorites"))) { _ in
                print("Debug - Received refresh notification")
                refreshID = UUID()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !nameStore.favorites.isEmpty {
                        Menu {
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                Label("Alle löschen", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Color.dynamicText)
                        }
                    }
                }
            }
            .alert("Alle Favoriten löschen?", isPresented: $showingDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    nameStore.removeAllFavorites()
                }
            } message: {
                Text("Möchten Sie wirklich alle Favoriten löschen?")
            }
            .alert("Von Favoriten entfernen?", isPresented: $showingRemoveAlert) {
                Button("Abbrechen", role: .cancel) {
                    personToRemove = nil
                }
                Button("Entfernen", role: .destructive) {
                    if let person = personToRemove {
                        nameStore.removeFromFavorites(person)
                    }
                }
            } message: {
                if let person = personToRemove {
                    Text("Möchten Sie \(person.firstName) \(person.lastName) wirklich von den Favoriten entfernen?")
                }
            }
        }
    }
}

struct PersonRow: View {
    let person: Person
    let onStarTap: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onStarTap) {
                Image(systemName: "star.fill")
            }
            .buttonStyle(.plain)
            
            Text("\(person.firstName) \(person.lastName)")
                .font(.body)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = "\(person.firstName) \(person.lastName)"
            }) {
                Label("Namen kopieren", systemImage: "doc.on.doc")
            }
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(NameStore())
} 

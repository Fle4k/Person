import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var nameStore: NameStore
    @State private var showingDeleteConfirmation = false
    @State private var isSelectionMode = false
    @State private var selectedPersons: Set<UUID> = []
    @State private var showingRemoveAlert = false
    @State private var personToRemove: Person?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(nameStore.favorites) { person in
                    NavigationLink(value: person) {
                        PersonRow(person: person, isSelectionMode: isSelectionMode, isSelected: selectedPersons.contains(person.id), onStarTap: {
                            personToRemove = person
                            showingRemoveAlert = true
                        })
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelectionMode {
                                    if selectedPersons.contains(person.id) {
                                        selectedPersons.remove(person.id)
                                    } else {
                                        selectedPersons.insert(person.id)
                                    }
                                }
                            }
                    }
                    .disabled(isSelectionMode)
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: Person.self) { person in
                PersonDetailView(person: person)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !nameStore.favorites.isEmpty {
                        Menu {
                            Button(action: {
                                isSelectionMode.toggle()
                                if !isSelectionMode {
                                    selectedPersons.removeAll()
                                }
                            }) {
                                Label(isSelectionMode ? "Fertig" : "Auswählen", systemImage: isSelectionMode ? "checkmark" : "checkmark.circle")
                            }
                            
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                Label("Alle löschen", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                
                if isSelectionMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            for person in nameStore.favorites {
                                if selectedPersons.contains(person.id) {
                                    nameStore.removeFromFavorites(person)
                                }
                            }
                            isSelectionMode = false
                            selectedPersons.removeAll()
                        }) {
                            Text("Löschen")
                        }
                        .disabled(selectedPersons.isEmpty)
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
    let isSelectionMode: Bool
    let isSelected: Bool
    let onStarTap: () -> Void
    
    var body: some View {
        HStack {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
            } else {
                Button(action: onStarTap) {
                    Image(systemName: "star.fill")
                }
                .buttonStyle(.plain)
            }
            
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

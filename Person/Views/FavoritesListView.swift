import SwiftUI

struct FavoritesListView: View {
    @EnvironmentObject private var nameStore: NameStore
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var personToDelete: Person?
    @State private var showingTagFilter = false
    @State private var selectedTag: String?
    
    var filteredFavorites: [Person] {
        var filtered = nameStore.favorites
        
        // Apply tag filter
        if let tag = selectedTag {
            filtered = filtered.filter { $0.tags.contains(tag) }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { person in
                person.firstName.localizedCaseInsensitiveContains(searchText) ||
                person.lastName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.firstName < $1.firstName }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFavorites) { person in
                    NavigationLink(destination: PersonDetailView(person: person)) {
                        HStack {
                            Button {
                                personToDelete = person
                                showingDeleteAlert = true
                            } label: {
                                Image(systemName: "star.fill")
                            }
                            .buttonStyle(.plain)
                            
                            VStack(alignment: .leading) {
                                Text("\(person.firstName) \(person.lastName)")
                                    .font(.headline)
                                
                                if hasAdditionalData(for: person) {
                                    Text("Zusätzliche Informationen")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        personToDelete = filteredFavorites[index]
                        showingDeleteAlert = true
                    }
                }
            }
            .navigationTitle("Favoriten")
            .searchable(text: $searchText, prompt: "Suche")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTagFilter = true
                    } label: {
                        Image(systemName: "tag")
                    }
                }
            }
            .sheet(isPresented: $showingTagFilter) {
                TagFilterView(selectedTag: $selectedTag)
            }
            .alert("Von Favoriten entfernen?", isPresented: $showingDeleteAlert) {
                Button("Abbrechen", role: .cancel) {
                    personToDelete = nil
                }
                Button("Entfernen", role: .destructive) {
                    if let person = personToDelete {
                        nameStore.removeFromFavorites(person)
                    }
                }
            } message: {
                if let person = personToDelete {
                    Text("Möchten Sie \(person.firstName) \(person.lastName) wirklich von den Favoriten entfernen?")
                }
            }
        }
    }
    
    private func hasAdditionalData(for person: Person) -> Bool {
        let details = nameStore.getDetails(for: person)
        return !details.height.isEmpty ||
               !details.hairColor.isEmpty ||
               !details.eyeColor.isEmpty ||
               !details.characteristics.isEmpty ||
               !details.style.isEmpty ||
               !details.type.isEmpty ||
               !details.hashtag.isEmpty ||
               !details.notes.isEmpty ||
               person.imageData != nil
    }
} 
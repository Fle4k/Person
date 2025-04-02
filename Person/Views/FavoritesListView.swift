import SwiftUI

struct FavoritesListView: View {
    @EnvironmentObject private var nameStore: NameStore
    @State private var searchText = ""
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
        
        // Sort by favoritedAt timestamp, most recent first
        return filtered.sorted { (person1: Person, person2: Person) in
            let date1 = person1.favoritedAt ?? Date.distantPast
            let date2 = person2.favoritedAt ?? Date.distantPast
            return date1 > date2
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFavorites) { person in
                    NavigationLink(destination: PersonDetailView(person: person)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(person.firstName) \(person.lastName)")
                                    .font(.headline)
                                
                                if hasAdditionalData(for: person) {
                                    Text("Zusätzliche Informationen")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Favoriten")
            .searchable(text: $searchText, prompt: "Suche")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !filteredFavorites.isEmpty {
                        Button {
                            showingTagFilter = true
                        } label: {
                            Image(systemName: "tag")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingTagFilter) {
                TagFilterView(selectedTag: $selectedTag)
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
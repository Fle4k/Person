import SwiftUI

struct GeneratedNamesListView: View {
    let names: [Person]
    @Binding var sheetDetent: PresentationDetent
    @EnvironmentObject private var nameStore: NameStore
    @State private var nameToUnfavorite: Person?
    @State private var showingUnfavoriteAlert = false
    @State private var favoriteStates: [UUID: Bool] = [:]
    
    var body: some View {
        List {
            ForEach(names) { person in
                HStack(spacing: 0) {
                    // Leading star button
                    Button {
                        handleFavoriteAction(for: person)
                    } label: {
                        Image(systemName: favoriteStates[person.id] ?? person.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(Color.dynamicText)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 32)
                    
                    // Name
                    Text("\(person.firstName) \(person.lastName)")
                        .foregroundStyle(Color.dynamicText)
                        .padding(.leading, 8)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("")  // Empty title for sheet
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.dynamicText)
        .alert(
            "Name entfernen?",
            isPresented: $showingUnfavoriteAlert,
            presenting: nameToUnfavorite
        ) { person in
            Button("Abbrechen", role: .cancel) {}
            Button("Entfernen", role: .destructive) {
                withAnimation {
                    favoriteStates[person.id] = false
                    nameStore.removeFromFavorites(person)
                }
            }
        } message: { person in
            Text("Möchtest du '\(person.firstName) \(person.lastName)' wirklich aus deinen Favoriten entfernen? Alle gespeicherten Informationen gehen dabei verloren.")
        }
    }
    
    private func handleFavoriteAction(for person: Person) {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        
        if favoriteStates[person.id] ?? person.isFavorite {
            handleUnfavorite(person)
        } else {
            withAnimation {
                generator.selectionChanged()
                var updatedPerson = person
                updatedPerson.isFavorite = true
                favoriteStates[person.id] = true
                nameStore.addToFavorites(updatedPerson)
            }
        }
    }
    
    private func handleUnfavorite(_ person: Person) {
        if hasAdditionalData(person) {
            nameToUnfavorite = person
            showingUnfavoriteAlert = true
        } else {
            withAnimation {
                favoriteStates[person.id] = false
                nameStore.removeFromFavorites(person)
            }
        }
    }
    
    private func hasAdditionalData(_ person: Person) -> Bool {
        let details = nameStore.getDetails(for: person)
        return !details.height.isEmpty ||
               !details.hairColor.isEmpty ||
               !details.eyeColor.isEmpty ||
               !details.characteristics.isEmpty ||
               !details.style.isEmpty ||
               !details.type.isEmpty ||
               !details.hashtag.isEmpty ||
               !details.notes.isEmpty
    }
}

#Preview {
    NavigationStack {
        GeneratedNamesListView(
            names: [
                Person(firstName: "Max", lastName: "Mustermann", gender: .male, nationality: .german, decade: "1990"),
                Person(firstName: "Erika", lastName: "Musterfrau", gender: .female, nationality: .german, decade: "1990")
            ],
            sheetDetent: .constant(.height(40))
        )
        .environmentObject(NameStore())
    }
} 
import SwiftUI

struct GeneratedNamesListView: View {
    let names: [Person]
    @Binding var sheetDetent: PresentationDetent
    @EnvironmentObject private var viewModel: PersonViewModel
    @State private var nameToUnfavorite: Person?
    @State private var showingUnfavoriteAlert = false
    
    var body: some View {
        List {
            ForEach(names) { person in
                HStack(spacing: 0) {
                    // Leading star button
                    Button {
                        handleFavoriteAction(for: person)
                    } label: {
                        Image(systemName: person.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(Color.dynamicText)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 32)
                    
                    // Name with context menu
                    Text("\(person.firstName) \(person.lastName)")
                        .foregroundStyle(Color.dynamicText)
                        .padding(.leading, 8)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = "\(person.firstName) \(person.lastName)"
                            }) {
                                Label("Kopieren", systemImage: "doc.on.doc")
                            }
                        }
                    
                    Spacer()
                    
                    // Navigation chevron
                    if person.isFavorite {
                        NavigationLink(destination: PersonDetailView(person: person)) {
                            EmptyView()
                        }
                        .tint(Color.dynamicText)
                    }
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
                    viewModel.removePerson(person)
                }
            }
        } message: { person in
            Text("Möchtest du '\(person.firstName) \(person.lastName)' wirklich aus deinen Favoriten entfernen? Alle gespeicherten Informationen gehen dabei verloren.")
        }
    }
    
    private func handleFavoriteAction(for person: Person) {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        
        if person.isFavorite {
            handleUnfavorite(person)
        } else {
            withAnimation {
                generator.selectionChanged()
                viewModel.addPerson(person)
            }
        }
    }
    
    private func handleUnfavorite(_ person: Person) {
        if hasAdditionalData(person) {
            nameToUnfavorite = person
            showingUnfavoriteAlert = true
        } else {
            withAnimation {
                viewModel.removePerson(person)
            }
        }
    }
    
    private func hasAdditionalData(_ person: Person) -> Bool {
        !person.notes.isEmpty ||
        !person.tags.isEmpty ||
        person.imageData != nil ||
        person.height != nil ||
        person.hairColor != nil ||
        person.eyeColor != nil ||
        person.characteristics != nil ||
        person.style != nil ||
        person.type != nil ||
        person.hashtag != nil
    }
}

#Preview {
    NavigationStack {
        GeneratedNamesListView(
            names: [
                Person(firstName: "Max", lastName: "Mustermann", gender: .male),
                Person(firstName: "Erika", lastName: "Musterfrau", gender: .female)
            ],
            sheetDetent: .constant(.height(40))
        )
        .environmentObject(PersonViewModel())
    }
} 
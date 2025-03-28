import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var viewModel: PersonViewModel
    @State private var searchText = ""
    @State private var selectedPerson: Person?
    
    var filteredPersons: [Person] {
        if searchText.isEmpty {
            return viewModel.favorites
        } else {
            return viewModel.favorites.filter { person in
                let fullName = "\(person.firstName) \(person.lastName)".lowercased()
                return fullName.contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        Group {
            if viewModel.favorites.isEmpty {
                ContentUnavailableView {
                    Label("Keine Favoriten", systemImage: "star.slash")
                        .foregroundStyle(Color.dynamicText)
                } description: {
                    Text("Generierte Namen können zu den Favoriten hinzugefügt werden")
                        .foregroundStyle(Color.dynamicText.opacity(0.6))
                }
            } else {
                List {
                    ForEach(filteredPersons) { person in
                        NavigationLink(value: person) {
                            VStack(alignment: .leading) {
                                Text("\(person.firstName) \(person.lastName)")
                                    .font(.headline)
                                    .foregroundStyle(Color.dynamicText)
                                
                                HStack {
                                    Text(person.gender.displayName)
                                    Text("•")
                                    Text(person.nationality.displayName)
                                    if let decade = person.decade {
                                        Text("•")
                                        Text(decade)
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(Color.dynamicText.opacity(0.6))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deletePerson)
                }
                .searchable(text: $searchText, prompt: "Nach Namen suchen")
            }
        }
        .navigationDestination(for: Person.self) { person in
            PersonDetailView(person: person)
        }
        .navigationTitle("Favoriten")
    }
    
    private func deletePerson(at offsets: IndexSet) {
        for index in offsets {
            let person = filteredPersons[index]
            viewModel.removePerson(person)
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
            .environmentObject(PersonViewModel())
    }
} 
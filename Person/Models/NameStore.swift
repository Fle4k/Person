import SwiftUI

class NameStore: ObservableObject {
    @Published var favorites: [Person] = [] {
        didSet {
            saveFavorites()
        }
    }
    
    private let favoritesKey = "favorites"
    private let detailsKey = "personDetails"
    private var detailsCache: [UUID: PersonDetails] = [:]
    
    init() {
        loadFavorites()
        loadDetails()
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decodedFavorites = try? JSONDecoder().decode([Person].self, from: data) {
            favorites = decodedFavorites
        }
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func loadDetails() {
        if let data = UserDefaults.standard.data(forKey: detailsKey),
           let decodedDetails = try? JSONDecoder().decode([UUID: PersonDetails].self, from: data) {
            detailsCache = decodedDetails
        }
    }
    
    private func saveDetails() {
        if let encoded = try? JSONEncoder().encode(detailsCache) {
            UserDefaults.standard.set(encoded, forKey: detailsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func getDetails(for person: Person) -> PersonDetails {
        if detailsCache[person.id] == nil {
            detailsCache[person.id] = PersonDetails()
            saveDetails()
        }
        return detailsCache[person.id] ?? PersonDetails()
    }
    
    func saveDetails(_ details: PersonDetails, for person: Person) {
        detailsCache[person.id] = details
        saveDetails()
    }
    
    var allTags: [String] {
        Set(favorites.flatMap { $0.tags }).sorted()
    }
    
    func personsWithTag(_ tag: String) -> [Person] {
        favorites.filter { $0.tags.contains(tag) }
    }
    
    func addToFavorites(_ person: Person) {
        var updatedPerson = person
        updatedPerson.isFavorite = true
        favorites.append(updatedPerson)
        if detailsCache[person.id] == nil {
            detailsCache[person.id] = PersonDetails()
            saveDetails()
        }
    }
    
    func removeFromFavorites(_ person: Person) {
        favorites.removeAll { $0.id == person.id }
        detailsCache.removeValue(forKey: person.id)
        saveDetails()
    }
    
    func removeAllFavorites() {
        favorites.removeAll()
        detailsCache.removeAll()
        saveDetails()
    }
    
    func updatePerson(_ person: Person) {
        if let index = favorites.firstIndex(where: { $0.id == person.id }) {
            favorites[index] = person
            saveFavorites()
        }
    }
    
    func saveImage(_ image: UIImage, for person: Person) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            var updatedPerson = person
            updatedPerson.imageData = imageData
            updatePerson(updatedPerson)
        }
    }
    
    func deleteImage(for person: Person) {
        var updatedPerson = person
        updatedPerson.imageData = nil
        updatePerson(updatedPerson)
    }
    
    func loadImage(for person: Person) -> UIImage? {
        guard let imageData = person.imageData else { return nil }
        return UIImage(data: imageData)
    }
} 
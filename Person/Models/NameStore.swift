import SwiftUI

class NameStore: ObservableObject {
    @Published var favorites: [Person] = [] {
        didSet {
            saveFavorites()
        }
    }
    
    private let favoritesKey = "favorites"
    private let detailsKey = "personDetails"
    internal var detailsCache: [UUID: PersonDetails] = [:]
    
    init() {
        loadFavorites()
        loadDetails()
    }
    
    public func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decodedFavorites = try? JSONDecoder().decode([Person].self, from: data) {
            favorites = decodedFavorites
        }
    }
    
    public func saveFavorites() {
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
    
    public func saveDetails() {
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
        updatedPerson.favoritedAt = Date()
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
        saveFavorites()
    }
    
    func toggleFavorite(_ person: Person) {
        if person.isFavorite {
            removeFromFavorites(person)
        } else {
            addToFavorites(person)
        }
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
    
    // Direct method that doesn't rely on other methods
    func removePersonFromFavoritesById(id personID: UUID) {
        print("🔍 BEFORE REMOVAL - Current favorites:")
        for (index, person) in favorites.enumerated() {
            print("   [\(index)] ID: \(person.id) - \(person.firstName) \(person.lastName)")
        }
        
        let countBefore = favorites.count
        
        // Remove only items with a DIFFERENT ID (keep everything except the one we want to remove)
        let filteredFavorites = favorites.filter { $0.id != personID }
        
        // Only update if we actually found and removed something
        if filteredFavorites.count < countBefore {
            // Replace the entire array at once
            favorites = filteredFavorites
            
            // Handle details cache separately
            detailsCache.removeValue(forKey: personID)
            saveDetails()
            
            print("✅ REMOVED - Person with ID: \(personID)")
        } else {
            print("⚠️ NOT FOUND - Person with ID: \(personID) was not in favorites")
        }
        
        print("🔍 AFTER REMOVAL - Current favorites:")
        for (index, person) in favorites.enumerated() {
            print("   [\(index)] ID: \(person.id) - \(person.firstName) \(person.lastName)")
        }
        
        // Notify UI to refresh
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("RefreshFavorites"), object: nil)
        }
    }
    
    // Complete rewrite of removal functionality that only uses index-based removal
    func removeSingleFavoriteByID(_ id: UUID) -> Bool {
        // Check if favorites is empty - nothing to remove
        if favorites.isEmpty {
            print("🚫 ERROR - Favorites list is empty")
            return false
        }
        
        print("🔍 Current favorites: \(favorites.count) items")
        for (i, p) in favorites.enumerated() {
            print("  - [\(i)] \(p.firstName) \(p.lastName) (ID: \(p.id))")
        }
        
        print("🎯 Trying to remove person with ID: \(id)")
        
        // CRITICAL: Find the specific index by ID
        guard let indexToRemove = favorites.firstIndex(where: { $0.id == id }) else {
            print("❌ Person with ID \(id) not found in favorites")
            return false
        }
        
        print("✅ Found person at index \(indexToRemove), removing...")
        
        // Only remove this single specific item by index
        favorites.remove(at: indexToRemove)
        
        // Clean up details cache
        detailsCache.removeValue(forKey: id)
        
        // Directly save to UserDefaults to ensure persistence
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
            UserDefaults.standard.synchronize()
        }
        if let encoded = try? JSONEncoder().encode(detailsCache) {
            UserDefaults.standard.set(encoded, forKey: detailsKey)
            UserDefaults.standard.synchronize()
        }
        
        print("✅ Success! Favorites now has \(favorites.count) items")
        for (i, p) in favorites.enumerated() {
            print("  - [\(i)] \(p.firstName) \(p.lastName) (ID: \(p.id))")
        }
        
        // Force UI refresh
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("RefreshFavorites"), object: nil)
        }
        
        return true
    }
} 
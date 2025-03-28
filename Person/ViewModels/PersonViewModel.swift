import SwiftUI
import Foundation

@MainActor
class PersonViewModel: ObservableObject {
    @Published var favorites: [Person] = []
    private var namesData: [String: Any] = [:]
    
    init() {
        loadNamesData()
    }
    
    private func loadNamesData() {
        print("=== Debug: Starting loadNamesData ===")
        
        // 1. Check if file exists
        guard let url = Bundle.main.url(forResource: "names", withExtension: "json") else {
            print("Error: names.json not found in bundle")
            print("Bundle path: \(Bundle.main.bundlePath)")
            print("Resource paths: \(Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil))")
            return
        }
        print("Found names.json at: \(url)")
        
        do {
            // 2. Read file contents
            let data = try Data(contentsOf: url)
            print("Successfully read \(data.count) bytes from names.json")
            
            // 3. Parse JSON
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Error: Failed to parse JSON data")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON content: \(jsonString.prefix(200))...") // Print first 200 chars
                }
                return
            }
            print("Successfully parsed JSON")
            
            // 4. Store and validate data
            namesData = json
            print("Data structure validation:")
            if let firstNames = namesData["firstNames"] as? [String: Any] {
                print("- firstNames exists")
                print("  Available nationalities: \(firstNames.keys.sorted())")
                
                for nationality in Nationality.allCases {
                    if let nationalityData = firstNames[nationality.rawValue] as? [String: Any] {
                        print("  - \(nationality.rawValue) exists")
                        print("    Available genders: \(nationalityData.keys.sorted())")
                        
                        for gender in Gender.allCases {
                            if let genderData = nationalityData[gender.rawValue] as? [String: Any] {
                                print("    - \(gender.rawValue) exists")
                                print("      Available decades: \(genderData.keys.sorted())")
                            } else {
                                print("    - \(gender.rawValue) missing or invalid")
                            }
                        }
                    } else {
                        print("  - \(nationality.rawValue) missing or invalid")
                    }
                }
            } else {
                print("- firstNames section missing or invalid")
            }
            
            if let lastNames = namesData["lastNames"] as? [String: Any] {
                print("- lastNames exists")
                print("  Available nationalities: \(lastNames.keys.sorted())")
                
                for nationality in Nationality.allCases {
                    if let nationalityNames = lastNames[nationality.rawValue] as? [String] {
                        print("  - \(nationality.rawValue) exists with \(nationalityNames.count) names")
                    } else {
                        print("  - \(nationality.rawValue) missing or invalid")
                    }
                }
            } else {
                print("- lastNames section missing or invalid")
            }
            
            print("=== Debug: Finished loadNamesData ===")
            
        } catch {
            print("Error loading names.json: \(error)")
        }
    }
    
    var allTags: [String] {
        Set(favorites.flatMap { $0.tags }).sorted()
    }
    
    func getRandomFirstName(gender: Gender, nationality: Nationality, decade: String, useDoubleName: Bool = false) -> String? {
        print("Debug - Accessing: gender: \(gender.rawValue), nationality: \(nationality.rawValue), decade: \(decade)")
        
        guard let names = namesData["firstNames"] as? [String: Any],
              let nationalityData = names[nationality.rawValue] as? [String: Any],
              let genderData = nationalityData[gender.rawValue] as? [String: Any] else {
            print("Failed to get first names for gender: \(gender.rawValue), nationality: \(nationality.rawValue)")
            return nil
        }
        
        // Handle "Egal" case - combine all decades
        if decade == "Egal" {
            var allNames: [String] = []
            for (_, decadeNames) in genderData {
                if let names = decadeNames as? [String] {
                    allNames.append(contentsOf: names)
                }
            }
            
            if useDoubleName {
                let names = allNames.shuffled()
                if names.count >= 2 {
                    return "\(names[0])-\(names[1])"
                }
            }
            
            return allNames.randomElement()
        }
        
        // Regular case - specific decade
        guard let decadeNames = genderData[decade] as? [String] else {
            print("Failed to get names for decade: \(decade)")
            return nil
        }
        
        if useDoubleName {
            let names = decadeNames.shuffled()
            if names.count >= 2 {
                return "\(names[0])-\(names[1])"
            }
        }
        
        return decadeNames.randomElement()
    }
    
    func getRandomLastName(nationality: Nationality, startingWith: String? = nil) -> String? {
        guard let lastNames = namesData["lastNames"] as? [String: Any],
              let nationalityNames = lastNames[nationality.rawValue] as? [String] else {
            print("Failed to get last names for nationality: \(nationality)")
            return nil
        }
        
        if let startingWith = startingWith {
            // Filter names starting with the specified letter
            let filteredNames = nationalityNames.filter { $0.lowercased().hasPrefix(startingWith.lowercased()) }
            return filteredNames.randomElement()
        }
        
        return nationalityNames.randomElement()
    }
    
    func generatePerson(gender: Gender, nationality: Nationality, decade: String, useAlliteration: Bool, useDoubleName: Bool) -> Person? {
        print("Debug - Generating person with: gender: \(gender.rawValue), nationality: \(nationality.rawValue), decade: \(decade)")
        
        // If using alliteration, first get a random first name and then find a matching last name
        if useAlliteration {
            if let firstName = getRandomFirstName(gender: gender, nationality: nationality, decade: decade, useDoubleName: useDoubleName) {
                let firstLetter = String(firstName.prefix(1))
                if let lastName = getRandomLastName(nationality: nationality, startingWith: firstLetter) {
                    return Person(
                        firstName: firstName,
                        lastName: lastName,
                        gender: gender,
                        nationality: nationality,
                        decade: decade
                    )
                }
            }
        } else {
            // Regular name generation
            if let firstName = getRandomFirstName(gender: gender, nationality: nationality, decade: decade, useDoubleName: useDoubleName),
               let lastName = getRandomLastName(nationality: nationality) {
                return Person(
                    firstName: firstName,
                    lastName: lastName,
                    gender: gender,
                    nationality: nationality,
                    decade: decade
                )
            }
        }
        
        print("Debug - Failed to generate person")
        return nil
    }
    
    // MARK: - Favorites Management
    func addPerson(_ person: Person) {
        var updatedPerson = person
        updatedPerson.isFavorite = true
        favorites.append(updatedPerson)
        objectWillChange.send()
    }
    
    func updatePerson(_ person: Person) {
        if let index = favorites.firstIndex(where: { $0.id == person.id }) {
            favorites[index] = person
            objectWillChange.send()
        }
    }
    
    func removePerson(_ person: Person) {
        favorites.removeAll { $0.id == person.id }
        objectWillChange.send()
    }
} 
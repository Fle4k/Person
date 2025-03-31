import SwiftUI
import Foundation

@MainActor
class PersonViewModel: ObservableObject {
    @Published var favorites: [Person] = []
    @Published var isDataLoaded: Bool = false
    @Published var generatedNames: [Person] = []
    private var namesData: [String: Any] = [:]
    
    // Track recently used names to avoid repetition
    private var recentFirstNames: Set<String> = []
    private var recentLastNames: Set<String> = []
    private let maxHistorySize = 100 // Prevent unlimited growth
    
    init() {
        loadNamesData()
    }
    
    func loadNamesData() {
        print("=== Debug: Starting loadNamesData ===")
        
        // 1. Check if file exists
        guard let url = Bundle.main.url(forResource: "names", withExtension: "json") else {
            print("Error: names.json not found in bundle")
            print("Bundle path: \(Bundle.main.bundlePath)")
            print("Resource paths: \(Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil))")
            isDataLoaded = false
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
                    print("Raw JSON content: \(jsonString.prefix(200))...")
                }
                isDataLoaded = false
                return
            }
            print("Successfully parsed JSON")
            
            // 4. Store and validate data
            namesData = json
            isDataLoaded = true
            
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
    
    private func addToRecentNames(_ firstName: String, _ lastName: String) {
        recentFirstNames.insert(firstName)
        recentLastNames.insert(lastName)
        
        // Trim history if it gets too large
        if recentFirstNames.count > maxHistorySize {
            recentFirstNames.remove(recentFirstNames.randomElement()!)
        }
        if recentLastNames.count > maxHistorySize {
            recentLastNames.remove(recentLastNames.randomElement()!)
        }
    }
    
    func getRandomFirstName(gender: Gender, nationality: Nationality, decade: String, useDoubleName: Bool = false) -> String? {
        print("Debug - Accessing: gender: \(gender.rawValue), nationality: \(nationality.rawValue), decade: \(decade)")
        
        guard let names = namesData["firstNames"] as? [String: Any],
              let nationalityData = names[nationality.rawValue] as? [String: Any],
              let genderData = nationalityData[gender.rawValue] as? [String: Any] else {
            print("Failed to get first names for gender: \(gender.rawValue), nationality: \(nationality.rawValue)")
            return nil
        }
        
        // Handle "Alle" case - combine all decades
        if decade == "Alle" {
            var allNames: [String] = []
            for (_, decadeNames) in genderData {
                if let names = decadeNames as? [String] {
                    // Filter out recently used names
                    allNames.append(contentsOf: names.filter { !recentFirstNames.contains($0) })
                }
            }
            print("Debug - Found \(allNames.count) available names for 'Alle' case")
            
            if useDoubleName {
                let names = allNames.shuffled()
                if names.count >= 2 {
                    let doubleName = "\(names[0])-\(names[1])"
                    return doubleName
                }
            }
            
            return allNames.randomElement()
        }
        
        // Regular case - specific decade
        guard let decadeNames = genderData[decade] as? [String] else {
            print("Failed to get names for decade: \(decade)")
            return nil
        }
        
        // Filter out recently used names
        let availableNames = decadeNames.filter { !recentFirstNames.contains($0) }
        print("Debug - Found \(availableNames.count) available names for decade: \(decade)")
        
        if useDoubleName {
            let names = availableNames.shuffled()
            if names.count >= 2 {
                let doubleName = "\(names[0])-\(names[1])"
                return doubleName
            }
        }
        
        return availableNames.randomElement()
    }
    
    func getRandomLastName(nationality: Nationality, startingWith: String? = nil) -> String? {
        print("Debug - Getting last name for nationality: \(nationality.rawValue), startingWith: \(startingWith ?? "nil")")
        
        guard let lastNames = namesData["lastNames"] as? [String: Any] else {
            print("Debug - Failed to get lastNames dictionary")
            return nil
        }
        
        guard let nationalityNames = lastNames[nationality.rawValue] as? [String] else {
            print("Debug - Failed to get last names for nationality: \(nationality.rawValue)")
            return nil
        }
        
        // Filter out recently used names
        let availableNames = nationalityNames.filter { !recentLastNames.contains($0) }
        print("Debug - Found \(availableNames.count) available last names for \(nationality.rawValue)")
        
        if let startingWith = startingWith {
            // Filter names starting with the specified letter
            let filteredNames = availableNames.filter { $0.lowercased().hasPrefix(startingWith.lowercased()) }
            print("Debug - Found \(filteredNames.count) available last names starting with '\(startingWith)'")
            return filteredNames.randomElement()
        }
        
        return availableNames.randomElement()
    }
    
    func generatePerson(gender: Gender, nationality: Nationality, decade: String, useAlliteration: Bool, useDoubleName: Bool) -> Person? {
        guard isDataLoaded else {
            print("Debug - Names data not loaded yet")
            loadNamesData()
            return nil
        }
        
        print("Debug - Generating person with: gender: \(gender.rawValue), nationality: \(nationality.rawValue), decade: \(decade)")
        
        // First get a random first name
        guard let firstName = getRandomFirstName(gender: gender, nationality: nationality, decade: decade, useDoubleName: useDoubleName) else {
            print("Debug - Failed to get first name")
            return nil
        }
        
        // If using alliteration, get the first letter of the first name
        let startingLetter = useAlliteration ? String(firstName.prefix(1)) : nil
        print("Debug - Using alliteration: \(useAlliteration), starting letter: \(startingLetter ?? "none")")
        
        // Then get a matching last name
        guard let lastName = getRandomLastName(nationality: nationality, startingWith: startingLetter) else {
            print("Debug - Failed to get last name")
            return nil
        }
        
        // Add names to history
        addToRecentNames(firstName, lastName)
        
        print("Debug - Successfully created person: \(firstName) \(lastName)")
        return Person(
            firstName: firstName,
            lastName: lastName,
            gender: gender,
            nationality: nationality,
            decade: decade
        )
    }
    
    // New method to generate alphabetical names
    func generateAlphabeticalNames(gender: Gender, nationality: Nationality, decade: String, useDoubleName: Bool, useAlliteration: Bool = false) -> [Person] {
        var alphabeticalNames: [Person] = []
        let alphabet = "abcdefghijklmnopqrstuvwxyz"
        var usedFirstNamesThisGeneration: Set<String> = [] // Track first names used in this generation
        
        for letter in alphabet {
            // Try multiple times for each letter
            var attempts = 0
            var found = false
            let maxAttempts = letter.lowercased() == "y" || letter.lowercased() == "z" ? 10 : 30
            
            while !found && attempts < maxAttempts {
                // Get a first name
                if let firstName = getRandomFirstName(gender: gender, nationality: nationality, decade: decade, useDoubleName: useDoubleName) {
                    // Skip if this first name was already used in this generation
                    if usedFirstNamesThisGeneration.contains(firstName) {
                        attempts += 1
                        continue
                    }
                    
                    // If using alliteration, ensure first name starts with current letter
                    if !useAlliteration || firstName.lowercased().hasPrefix(String(letter)) {
                        // Get a last name, with alliteration if enabled
                        if let lastName = getRandomLastName(nationality: nationality, startingWith: useAlliteration ? String(letter) : nil) {
                            // Add names to history
                            addToRecentNames(firstName, lastName)
                            usedFirstNamesThisGeneration.insert(firstName) // Track this first name as used
                            
                            let person = Person(
                                firstName: firstName,
                                lastName: lastName,
                                gender: gender,
                                nationality: nationality,
                                decade: decade
                            )
                            alphabeticalNames.append(person)
                            found = true
                            print("Debug - Generated name: \(firstName) \(lastName)")
                        }
                    }
                }
                attempts += 1
            }
            
            if !found {
                print("Debug - Could not find name for letter: \(letter) after \(attempts) attempts")
                // For letters other than Y and Z, try one more time
                if letter.lowercased() != "y" && letter.lowercased() != "z" {
                    if let firstName = getRandomFirstName(gender: gender, nationality: nationality, decade: decade, useDoubleName: useDoubleName),
                       !usedFirstNamesThisGeneration.contains(firstName), // Check for duplicate first names
                       (!useAlliteration || firstName.lowercased().hasPrefix(String(letter))),
                       let lastName = getRandomLastName(nationality: nationality, startingWith: useAlliteration ? String(letter) : nil) {
                        usedFirstNamesThisGeneration.insert(firstName) // Track this first name as used
                        let person = Person(
                            firstName: firstName,
                            lastName: lastName,
                            gender: gender,
                            nationality: nationality,
                            decade: decade
                        )
                        alphabeticalNames.append(person)
                        print("Debug - Generated name on second attempt: \(firstName) \(lastName)")
                    }
                }
            }
        }
        
        // Sort by last name
        let sortedNames = alphabeticalNames.sorted { $0.lastName.lowercased() < $1.lastName.lowercased() }
        print("Debug - Generated \(sortedNames.count) names in alphabetical order")
        
        // If we don't have enough names, try one final time for missing letters
        if sortedNames.count < 24 {
            print("Debug - Not enough names generated, trying one final time for missing letters")
            let missingLetters = alphabet.filter { letter in
                !sortedNames.contains { $0.lastName.lowercased().hasPrefix(String(letter)) }
            }
            
            for letter in missingLetters {
                if letter.lowercased() != "y" && letter.lowercased() != "z" {
                    if let firstName = getRandomFirstName(gender: gender, nationality: nationality, decade: decade, useDoubleName: useDoubleName),
                       !usedFirstNamesThisGeneration.contains(firstName), // Check for duplicate first names
                       (!useAlliteration || firstName.lowercased().hasPrefix(String(letter))),
                       let lastName = getRandomLastName(nationality: nationality, startingWith: useAlliteration ? String(letter) : nil) {
                        usedFirstNamesThisGeneration.insert(firstName) // Track this first name as used
                        let person = Person(
                            firstName: firstName,
                            lastName: lastName,
                            gender: gender,
                            nationality: nationality,
                            decade: decade
                        )
                        alphabeticalNames.append(person)
                        print("Debug - Generated missing letter name: \(firstName) \(lastName)")
                    }
                }
            }
        }
        
        // Final sort
        let finalSortedNames = alphabeticalNames.sorted { $0.lastName.lowercased() < $1.lastName.lowercased() }
        print("Debug - Final count: \(finalSortedNames.count) names")
        return finalSortedNames
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
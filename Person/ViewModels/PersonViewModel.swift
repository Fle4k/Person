import SwiftUI
import Foundation

@MainActor
class PersonViewModel: ObservableObject {
    @Published var favorites: [Person] = []
    @Published var isDataLoaded: Bool = false
    @Published var generatedNames: [Person] = []
    private var germanNamesData: [String: Any] = [:]
    private var britishNamesData: [String: Any] = [:]
    
    // Track recently used names to avoid repetition
    private var recentFirstNames: Set<String> = []
    private var recentLastNames: Set<String> = []
    private let maxHistorySize = 100 // Prevent unlimited growth
    
    init() {
        loadNamesData()
    }
    
    func loadNamesData() {
        print("=== Debug: Starting loadNamesData ===")
        
        // Load German names
        guard let germanUrl = Bundle.main.url(forResource: "GermanNames", withExtension: "json") else {
            print("Error: GermanNames.json not found in bundle")
            print("Bundle path: \(Bundle.main.bundlePath)")
            print("Resource paths: \(Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil))")
            isDataLoaded = false
            return
        }
        print("Found GermanNames.json at: \(germanUrl)")
        
        // Load British names
        guard let britishUrl = Bundle.main.url(forResource: "BritishNames", withExtension: "json") else {
            print("Error: BritishNames.json not found in bundle")
            print("Bundle path: \(Bundle.main.bundlePath)")
            print("Resource paths: \(Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil))")
            isDataLoaded = false
            return
        }
        print("Found BritishNames.json at: \(britishUrl)")
        
        do {
            // Load German names
            let germanData = try Data(contentsOf: germanUrl)
            guard let germanJson = try JSONSerialization.jsonObject(with: germanData) as? [String: Any] else {
                print("Error: Failed to parse German names data")
                isDataLoaded = false
                return
            }
            germanNamesData = germanJson
            print("Successfully loaded German names data")
            
            // Load British names
            let britishData = try Data(contentsOf: britishUrl)
            guard let britishJson = try JSONSerialization.jsonObject(with: britishData) as? [String: Any] else {
                print("Error: Failed to parse British names data")
                isDataLoaded = false
                return
            }
            britishNamesData = britishJson
            print("Successfully loaded British names data")
            
            isDataLoaded = true
            print("Successfully loaded both name files")
            
            // Validate data structure
            validateDataStructure()
            
        } catch {
            print("Error loading name files: \(error.localizedDescription)")
            isDataLoaded = false
        }
    }
    
    private func validateDataStructure() {
        print("=== Validating data structure ===")
        
        for (nationality, data) in [("German", germanNamesData), ("British", britishNamesData)] {
            print("\nValidating \(nationality) names:")
            
            if let firstNames = data["firstNames"] as? [String: Any] {
                print("- firstNames exists")
                
                for gender in Gender.allCases {
                    if let genderData = firstNames[gender.rawValue] as? [String: Any] {
                        print("  - \(gender.rawValue) exists")
                        print("    Available decades: \(genderData.keys.sorted())")
                        
                        // Print sample names for each decade
                        for decade in genderData.keys {
                            if let names = genderData[decade] as? [String] {
                                print("    - \(decade): Found \(names.count) names. Sample: \(names.prefix(3).joined(separator: ", "))")
                            }
                        }
                    } else {
                        print("  - \(gender.rawValue) missing or invalid")
                    }
                }
            } else {
                print("- firstNames section missing or invalid")
            }
            
            if let lastNames = data["lastNames"] as? [String] {
                print("- lastNames exists with \(lastNames.count) names")
                print("  Sample last names: \(lastNames.prefix(3).joined(separator: ", "))")
            } else {
                print("- lastNames section missing or invalid")
            }
        }
        
        print("=== Finished validation ===")
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
        
        // Select appropriate data source based on nationality
        let namesData = nationality == .german ? germanNamesData : britishNamesData
        print("Debug - Selected \(nationality == .german ? "German" : "British") names data")
        
        guard let firstNames = namesData["firstNames"] as? [String: Any] else {
            print("Debug - Failed to get firstNames dictionary")
            return nil
        }
        
        guard let genderData = firstNames[gender.rawValue] as? [String: Any] else {
            print("Debug - Failed to get gender data for \(gender.rawValue)")
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
                    print("Debug - Generated double name: \(doubleName)")
                    return doubleName
                }
            }
            
            let selectedName = allNames.randomElement()
            print("Debug - Selected name: \(selectedName ?? "nil")")
            return selectedName
        }
        
        // Regular case - specific decade
        guard let decadeNames = genderData[decade] as? [String] else {
            print("Debug - Failed to get names for decade: \(decade)")
            print("Debug - Available decades: \(genderData.keys.sorted())")
            return nil
        }
        
        // Filter out recently used names
        let availableNames = decadeNames.filter { !recentFirstNames.contains($0) }
        print("Debug - Found \(availableNames.count) available names for decade: \(decade)")
        
        if useDoubleName {
            let names = availableNames.shuffled()
            if names.count >= 2 {
                let doubleName = "\(names[0])-\(names[1])"
                print("Debug - Generated double name: \(doubleName)")
                return doubleName
            }
        }
        
        let selectedName = availableNames.randomElement()
        print("Debug - Selected name: \(selectedName ?? "nil")")
        return selectedName
    }
    
    func getRandomLastName(nationality: Nationality, startingWith: String? = nil) -> String? {
        print("Debug - Getting last name for nationality: \(nationality.rawValue), startingWith: \(startingWith ?? "nil")")
        
        // Select appropriate data source based on nationality
        let namesData = nationality == .german ? germanNamesData : britishNamesData
        print("Debug - Selected \(nationality == .german ? "German" : "British") names data")
        
        guard let lastNames = namesData["lastNames"] as? [String] else {
            print("Debug - Failed to get lastNames array")
            return nil
        }
        
        // Filter out recently used names
        let availableNames = lastNames.filter { !recentLastNames.contains($0) }
        print("Debug - Found \(availableNames.count) available last names for \(nationality.rawValue)")
        
        if let startingWith = startingWith {
            // Filter names starting with the specified letter
            let filteredNames = availableNames.filter { $0.lowercased().hasPrefix(startingWith.lowercased()) }
            print("Debug - Found \(filteredNames.count) available last names starting with '\(startingWith)'")
            let selectedName = filteredNames.randomElement()
            print("Debug - Selected last name: \(selectedName ?? "nil")")
            return selectedName
        }
        
        let selectedName = availableNames.randomElement()
        print("Debug - Selected last name: \(selectedName ?? "nil")")
        return selectedName
    }
    
    func generatePerson(gender: Gender, nationality: Nationality, decade: String, useAlliteration: Bool, useDoubleName: Bool) -> Person? {
        print("\n=== Starting generatePerson ===")
        print("Parameters: gender: \(gender.rawValue), nationality: \(nationality.rawValue), decade: \(decade)")
        print("useAlliteration: \(useAlliteration), useDoubleName: \(useDoubleName)")
        
        guard isDataLoaded else {
            print("Debug - Names data not loaded yet")
            loadNamesData()
            return nil
        }
        
        // First get a random first name
        guard let firstName = getRandomFirstName(gender: gender, nationality: nationality, decade: decade, useDoubleName: useDoubleName) else {
            print("Debug - Failed to get first name")
            return nil
        }
        print("Generated first name: \(firstName)")
        
        // If using alliteration, get the first letter of the first name
        let startingLetter = useAlliteration ? String(firstName.prefix(1)) : nil
        print("Using alliteration: \(useAlliteration), starting letter: \(startingLetter ?? "none")")
        
        // Then get a matching last name
        guard let lastName = getRandomLastName(nationality: nationality, startingWith: startingLetter) else {
            print("Debug - Failed to get last name")
            return nil
        }
        print("Generated last name: \(lastName)")
        
        // Add names to history
        addToRecentNames(firstName, lastName)
        
        let person = Person(
            firstName: firstName,
            lastName: lastName,
            gender: gender,
            nationality: nationality,
            decade: decade
        )
        print("Successfully created person: \(firstName) \(lastName)")
        print("=== Finished generatePerson ===\n")
        return person
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
                // For letters other than Y and Z, try one more time with strict nationality check
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
        
        // If we don't have enough names, try one final time for missing letters with strict nationality check
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
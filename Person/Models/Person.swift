import Foundation

enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case diverse = "diverse"
    
    var displayName: String {
        switch self {
        case .male: return "Männlich"
        case .female: return "Weiblich"
        case .diverse: return "Divers"
        }
    }
}

enum Nationality: String, CaseIterable, Codable {
    case german = "german"
    case british = "british"
    
    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .british: return "Britisch"
        }
    }
}

struct PersonDetails: Codable {
    var height: String = ""
    var hairColor: String = ""
    var eyeColor: String = ""
    var characteristics: String = ""
    var style: String = ""
    var type: String = ""
    var hashtag: String = ""
    var notes: String = ""
}

struct Person: Identifiable, Codable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var gender: Gender
    var nationality: Nationality
    var decade: String
    var isFavorite: Bool
    var imageData: Data?
    var tags: [String]
    var favoritedAt: Date?
    
    init(id: UUID = UUID(), firstName: String, lastName: String, gender: Gender, nationality: Nationality, decade: String, isFavorite: Bool = false, imageData: Data? = nil, tags: [String] = [], favoritedAt: Date? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.nationality = nationality
        self.decade = decade
        self.isFavorite = isFavorite
        self.imageData = imageData
        self.tags = tags
        self.favoritedAt = favoritedAt
    }
    
    static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func debugDescription() -> String {
        return "Person(id: \(id), name: \(firstName) \(lastName), favorite: \(isFavorite))"
    }
} 
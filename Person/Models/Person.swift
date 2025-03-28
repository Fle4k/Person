import Foundation

enum Gender: String, CaseIterable {
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

enum Nationality: String, CaseIterable {
    case german = "german"
    case british = "british"
    
    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .british: return "Britisch"
        }
    }
}

struct Person: Identifiable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var gender: Gender
    var nationality: Nationality
    var decade: String?
    var imageData: Data?
    var notes: String = ""
    var tags: Set<String> = []
    var isFavorite: Bool = false
    
    // Optional details
    var height: String?
    var hairColor: String?
    var eyeColor: String?
    var characteristics: String?
    var style: String?
    var type: String?
    var hashtag: String?
    
    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        gender: Gender = .female,
        nationality: Nationality = .german,
        decade: String? = nil,
        imageData: Data? = nil,
        notes: String = "",
        tags: Set<String> = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.nationality = nationality
        self.decade = decade
        self.imageData = imageData
        self.notes = notes
        self.tags = tags
        self.isFavorite = isFavorite
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.id == rhs.id
    }
} 
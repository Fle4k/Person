import Foundation

struct NameData: Codable {
    struct Names: Codable {
        struct FirstNames: Codable {
            let male: [String]
            let female: [String]
        }
        
        let firstNames: [String: [String: [String]]] // nationality -> gender -> decade -> names
        let lastNames: [String: [String]] // nationality -> names
    }
    
    let firstNames: Names.FirstNames
    let lastNames: [String]
    
    static func load() -> NameData? {
        guard let url = Bundle.main.url(forResource: "names", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        return try? JSONDecoder().decode(NameData.self, from: data)
    }
} 
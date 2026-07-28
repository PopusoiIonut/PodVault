import Foundation

enum CredentialType: String, Codable, CaseIterable {
    case seedPhrase = "Seed Phrase"
    case privateKey = "Private Key"
    case pin = "Security PIN"
    
    var iconName: String {
        switch self {
        case .seedPhrase: return "text.quote"
        case .privateKey: return "key.horizontal.fill"
        case .pin: return "lock.ipad"
        }
    }
}

struct VaultCredential: Identifiable, Codable {
    var id = UUID()
    let name: String
    let value: String // The secret key content
    let type: CredentialType
    let dateAdded: Date
}

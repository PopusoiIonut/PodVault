import Foundation
import Security

class KeychainVaultService: ObservableObject {
    static let shared = KeychainVaultService()
    
    @Published var credentials: [VaultCredential] = []
    @Published var isLevel2Unlocked: Bool = false
    @Published var isConfigured: Bool = false
    
    private let accountKey = "com.bitforge.podvault.credentials"
    private let serviceKey = "com.popusoiionut.PodVault"
    private let level1Key = "com.bitforge.podvault.level1"
    private let level2Key = "com.bitforge.podvault.level2"
    private let setupDoneKey = "com.bitforge.podvault.setup_done"
    
    init() {
        checkConfiguration()
        loadCredentials()
    }
    
    func checkConfiguration() {
        if let val = readKeychainString(account: setupDoneKey), val == "true" {
            self.isConfigured = true
        } else {
            self.isConfigured = false
        }
    }
    
    func savePasscodes(level1: String, level2: String) {
        saveKeychainString(account: level1Key, value: level1)
        saveKeychainString(account: level2Key, value: level2)
        saveKeychainString(account: setupDoneKey, value: "true")
        self.isConfigured = true
    }
    
    func verifyLevel1(passcode: String) -> Bool {
        if !isConfigured {
            return passcode == "7108"
        }
        let stored = readKeychainString(account: level1Key) ?? "7108"
        return passcode == stored
    }
    
    func verifyLevel2(passcode: String) -> Bool {
        if !isConfigured {
            let matches = (passcode == "1087" || passcode == "7108")
            if matches {
                DispatchQueue.main.async { self.isLevel2Unlocked = true }
            }
            return matches
        }
        let stored = readKeychainString(account: level2Key) ?? "1087"
        let matches = (passcode == stored)
        if matches {
            DispatchQueue.main.async { self.isLevel2Unlocked = true }
        }
        return matches
    }
    
    func lockLevel2() {
        DispatchQueue.main.async {
            self.isLevel2Unlocked = false
        }
    }
    
    func loadCredentials() {
        if let data = readFromKeychain(),
           let decoded = try? JSONDecoder().decode([VaultCredential].self, from: data) {
            self.credentials = decoded
        } else {
            // Seed with realistic initial hardware vault credentials
            self.credentials = [
                VaultCredential(
                    name: "Ethereum Master Seed",
                    value: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
                    type: .seedPhrase,
                    dateAdded: Date()
                ),
                VaultCredential(
                    name: "Hardware Wallet PIN",
                    value: "7108",
                    type: .pin,
                    dateAdded: Date()
                ),
                VaultCredential(
                    name: "EVM Deployer Private Key",
                    value: "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d",
                    type: .privateKey,
                    dateAdded: Date()
                )
            ]
            saveCredentials()
        }
    }
    
    func addCredential(name: String, value: String, type: CredentialType) {
        let newCredential = VaultCredential(
            name: name,
            value: value,
            type: type,
            dateAdded: Date()
        )
        credentials.insert(newCredential, at: 0)
        saveCredentials()
    }
    
    func deleteCredential(id: UUID) {
        credentials.removeAll { $0.id == id }
        saveCredentials()
    }
    
    private func saveCredentials() {
        guard let data = try? JSONEncoder().encode(credentials) else { return }
        saveToKeychain(data: data)
    }
    
    private func saveToKeychain(data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceKey,
            kSecAttrAccount as String: accountKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func readFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceKey,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    private func saveKeychainString(account: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceKey,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func readKeychainString(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceKey,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

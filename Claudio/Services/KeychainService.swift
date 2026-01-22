import Foundation
import Security

/// Service for secure API key storage using macOS Keychain
struct KeychainService {
    private static let serviceName = "com.claudio.app"

    /// Save an API key for a provider
    /// - Parameters:
    ///   - key: The API key to store
    ///   - provider: The provider identifier (e.g., "claude", "openai")
    static func saveAPIKey(_ key: String, for provider: String) {
        guard let data = key.data(using: .utf8) else { return }

        // Delete any existing key first
        deleteAPIKey(for: provider)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: provider,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }

    /// Retrieve an API key for a provider
    /// - Parameter provider: The provider identifier
    /// - Returns: The stored API key, or nil if not found
    static func getAPIKey(for provider: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: provider,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    /// Delete an API key for a provider
    /// - Parameter provider: The provider identifier
    static func deleteAPIKey(for provider: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: provider
        ]

        SecItemDelete(query as CFDictionary)
    }

    /// Check if an API key exists for a provider
    /// - Parameter provider: The provider identifier
    /// - Returns: True if a key exists
    static func hasAPIKey(for provider: String) -> Bool {
        return getAPIKey(for: provider) != nil
    }
}

import Foundation

/// Centralized helper for data that must survive app deletion.
/// - Keychain: createdAt, name (same device reinstall)
/// - iCloud KV: createdAt, name, email, streaks (new device reinstall)
enum UserPersistenceHelper {

    // MARK: - Keys

    private static func key(_ base: String, userId: String) -> String {
        "\(base)_\(userId)"
    }

    // MARK: - Name

    static func saveName(_ name: String, userId: String) {
        let k = key("userName", userId: userId)
        KeychainHelper.save(name, forKey: k)
        iCloud.set(name, forKey: k)
    }

    static func resolveName(
        fromAppleCredentialName credentialName: String?,
        userId: String
    ) -> String? {
        let k = key("userName", userId: userId)

        // 1. Apple gave it (first ever sign-in)
        if let name = credentialName, !name.isEmpty {
            saveName(name, userId: userId)
            return name
        }

        // 2. Same device reinstall → Keychain
        if let name = KeychainHelper.read(forKey: k), !name.isEmpty {
            return name
        }

        // 3. New device reinstall → iCloud KV
        if let name = iCloud.string(forKey: k), !name.isEmpty {
            KeychainHelper.save(name, forKey: k) // restore to Keychain
            return name
        }

        return nil
    }

    // MARK: - Email

    static func saveEmail(_ email: String, userId: String) {
        let k = key("userEmail", userId: userId)
        iCloud.set(email, forKey: k)
    }

    /// Resolves email from Apple credential first, then iCloud KV as fallback.
    /// Note: Apple only sends email on the very first sign-in ever, so iCloud KV
    /// is the only recovery path on reinstall.
    static func resolveEmail(
        fromAppleCredentialEmail credentialEmail: String?,
        userId: String
    ) -> String? {
        let k = key("userEmail", userId: userId)

        // 1. Apple gave it (first ever sign-in)
        if let email = credentialEmail, !email.isEmpty {
            saveEmail(email, userId: userId)
            return email
        }

        // 2. iCloud KV fallback (reinstall / new device)
        if let email = iCloud.string(forKey: k), !email.isEmpty {
            return email
        }

        return nil
    }

    // MARK: - CreatedAt

    static func saveCreatedAt(_ date: Date, userId: String) {
        let k = key("createdAt", userId: userId)
        let value = String(date.timeIntervalSince1970)
        KeychainHelper.save(value, forKey: k)
        iCloud.set(value, forKey: k)
    }

    static func resolveCreatedAt(userId: String) -> Date? {
        let k = key("createdAt", userId: userId)

        // Keychain first (same device)
        if let raw = KeychainHelper.read(forKey: k),
           let ti = TimeInterval(raw) {
            return Date(timeIntervalSince1970: ti)
        }

        // iCloud KV (new device)
        if let raw = iCloud.string(forKey: k),
           let ti = TimeInterval(raw) {
            KeychainHelper.save(raw, forKey: k) // restore to Keychain
            return Date(timeIntervalSince1970: ti)
        }

        return nil
    }

    // MARK: - Streaks

    static func saveStreaks(current: Int, longest: Int, userId: String) {
        let currentKey = key("currentStreak", userId: userId)
        let longestKey = key("longestStreak", userId: userId)
        iCloud.set(String(current), forKey: currentKey)
        iCloud.set(String(longest), forKey: longestKey)
    }

    static func resolveStreaks(userId: String) -> (current: Int, longest: Int)? {
        let currentKey = key("currentStreak", userId: userId)
        let longestKey = key("longestStreak", userId: userId)

        guard let currentRaw = iCloud.string(forKey: currentKey),
              let current = Int(currentRaw),
              let longestRaw = iCloud.string(forKey: longestKey),
              let longest = Int(longestRaw) else {
            return nil
        }

        return (current, longest)
    }

    // MARK: - Cleanup (on delete account)

    static func deleteAll(userId: String) {
        let keys = ["userName", "userEmail", "createdAt", "currentStreak", "longestStreak"]
        for base in keys {
            let k = key(base, userId: userId)
            KeychainHelper.delete(forKey: k)
            iCloud.removeObject(forKey: k)
        }
        iCloud.synchronize()
    }

    // MARK: - iCloud KV shorthand

    private enum iCloud {
        static func set(_ value: String, forKey key: String) {
            NSUbiquitousKeyValueStore.default.set(value, forKey: key)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
        static func string(forKey key: String) -> String? {
            NSUbiquitousKeyValueStore.default.string(forKey: key)
        }
        static func removeObject(forKey key: String) {
            NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
        }
        static func synchronize() {
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
}
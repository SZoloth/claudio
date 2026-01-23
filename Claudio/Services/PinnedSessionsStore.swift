import Foundation

final class PinnedSessionsStore {
    private let key = "pinnedSessions"

    func loadPinnedIDs() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: key) as? [String] else {
            return []
        }
        return Set(array)
    }

    func savePinnedIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}

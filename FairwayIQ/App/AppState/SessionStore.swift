import Foundation

@Observable
final class SessionStore {
    private enum DefaultsKey {
        static let currentProfileId = "currentProfileId"
    }

    var currentProfileId: UUID? {
        didSet { persistCurrentProfileId() }
    }

    init() {
        currentProfileId = Self.loadCurrentProfileId()
    }

    func clearCurrentProfile() {
        currentProfileId = nil
    }

    private func persistCurrentProfileId() {
        guard let currentProfileId else {
            UserDefaults.standard.removeObject(forKey: DefaultsKey.currentProfileId)
            return
        }
        UserDefaults.standard.set(currentProfileId.uuidString, forKey: DefaultsKey.currentProfileId)
    }

    private static func loadCurrentProfileId() -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: DefaultsKey.currentProfileId) else { return nil }
        return UUID(uuidString: raw)
    }
}


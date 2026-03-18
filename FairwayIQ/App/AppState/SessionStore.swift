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

extension SessionStore {
    func resolvedProfile(in profiles: [UserProfile]) -> UserProfile? {
        if let currentProfileId,
           let profile = profiles.first(where: { $0.id == currentProfileId }) {
            return profile
        }
        return profiles.sorted(by: { $0.createdAt < $1.createdAt }).first
    }

    func roundsForCurrentProfile(_ rounds: [Round], profiles: [UserProfile]) -> [Round] {
        guard let profile = resolvedProfile(in: profiles) else { return rounds }

        let hasMultipleProfiles = profiles.count > 1
        return rounds.filter { round in
            if let playerId = round.player?.id {
                return playerId == profile.id
            }
            return !hasMultipleProfiles
        }
    }
}


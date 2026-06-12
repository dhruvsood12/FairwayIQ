import Foundation

extension SessionStore {
    func practiceSessionsForCurrentProfile(_ sessions: [PracticeSession], profiles: [UserProfile]) -> [PracticeSession] {
        guard let profile = resolvedProfile(in: profiles) else { return sessions }

        let hasMultipleProfiles = profiles.count > 1
        return sessions.filter { session in
            if let playerId = session.player?.id {
                return playerId == profile.id
            }
            return !hasMultipleProfiles
        }
    }

    func goalsForCurrentProfile(_ goals: [PlayerGoal], profiles: [UserProfile]) -> [PlayerGoal] {
        guard let profile = resolvedProfile(in: profiles) else { return goals }

        let hasMultipleProfiles = profiles.count > 1
        return goals.filter { goal in
            if let playerId = goal.player?.id {
                return playerId == profile.id
            }
            return !hasMultipleProfiles
        }
    }
}

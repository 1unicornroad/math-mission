//
//  PlayerProfileStore.swift
//  Math Mission
//
//  Created by Oz on 3/11/26.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

enum PlayerAvatar: String, CaseIterable, Codable {
    case avatar1 = "avatar-1"
    case avatar2 = "avatar-2"
    case avatar3 = "avatar-3"
    case avatar4 = "avatar-4"
    case avatar5 = "avatar-5"
    case avatar6 = "avatar-6"

    var imageName: String {
        rawValue
    }

    var title: String {
        switch self {
        case .avatar1: return "Character 1"
        case .avatar2: return "Character 2"
        case .avatar3: return "Character 3"
        case .avatar4: return "Character 4"
        case .avatar5: return "Character 5"
        case .avatar6: return "Character 6"
        }
    }
}

struct PlayerRank {
    let title: String
    let detail: String
}

struct PlayerProgress: Equatable {
    var completedTables: [Int] = []
    var completedDifficulties: [String] = []
    var unlockedShips: [String] = ["craft_speederA.dae"]
    var lifetimeStars: Int = 0
}

struct MissionStarReward {
    let earned: Int
    let newTotal: Int
}

enum ActivePlayerSession: Equatable {
    case guest
    case profile(UUID)
}

struct PlayerRecordSummary {
    let lifetimeStars: Int
    let bestStreak: Int
    let bestRunCleared: Int
    let totalRuns: Int
    let missionsCompleted: Int
    let totalQuestionsSeen: Int
    let totalCorrectAnswers: Int
    let totalFirstAttemptCorrect: Int
    let totalMisses: Int

    var firstAttemptAccuracy: Int {
        guard totalQuestionsSeen > 0 else { return 0 }
        return Int((Double(totalFirstAttemptCorrect) / Double(totalQuestionsSeen) * 100).rounded())
    }
}

struct TablePerformanceSummary: Identifiable {
    let mode: ArithmeticMode
    let tableNumber: Int
    let attempts: Int
    let firstAttemptCorrect: Int
    let correctAnswers: Int
    let misses: Int

    var id: String {
        "\(mode.rawValue)-\(tableNumber)"
    }

    var accuracyPercentage: Int {
        guard attempts > 0 else { return 0 }
        return Int((Double(firstAttemptCorrect) / Double(attempts) * 100).rounded())
    }
}

struct PlayerSessionStatUpdate {
    let arithmeticMode: ArithmeticMode
    let totalCleared: Int
    let bestStreak: Int
    let totalQuestionsSeen: Int
    let totalCorrectAnswers: Int
    let totalFirstAttemptCorrect: Int
    let totalMisses: Int
    let didCompleteMission: Bool
    let tableAttempts: [Int: Int]
    let tableFirstAttemptCorrect: [Int: Int]
    let tableCorrectAnswers: [Int: Int]
    let tableMisses: [Int: Int]
}

@Model
final class PlayerProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var avatarRawValue: String
    var completedTables: [Int]
    var completedDifficulties: [String]
    var unlockedShips: [String]
    var lifetimeStars: Int
    var bestStreak: Int
    var bestRunCleared: Int
    var totalRuns: Int
    var missionsCompleted: Int
    var totalQuestionsSeen: Int
    var totalCorrectAnswers: Int
    var totalFirstAttemptCorrect: Int
    var totalMisses: Int
    @Relationship(deleteRule: .cascade, inverse: \PlayerTablePerformance.profile) var tablePerformances: [PlayerTablePerformance]

    init(
        id: UUID = UUID(),
        name: String,
        avatar: PlayerAvatar,
        progress: PlayerProgress = PlayerProgress()
    ) {
        self.id = id
        self.name = name
        self.avatarRawValue = avatar.rawValue
        self.completedTables = progress.completedTables
        self.completedDifficulties = progress.completedDifficulties
        self.unlockedShips = progress.unlockedShips
        self.lifetimeStars = progress.lifetimeStars
        self.bestStreak = 0
        self.bestRunCleared = 0
        self.totalRuns = 0
        self.missionsCompleted = 0
        self.totalQuestionsSeen = 0
        self.totalCorrectAnswers = 0
        self.totalFirstAttemptCorrect = 0
        self.totalMisses = 0
        self.tablePerformances = []
    }

    var avatar: PlayerAvatar {
        get { PlayerAvatar(rawValue: avatarRawValue) ?? .avatar1 }
        set { avatarRawValue = newValue.rawValue }
    }
}

@Model
final class PlayerTablePerformance {
    @Attribute(.unique) var id: UUID
    var modeRawValue: String
    var tableNumber: Int
    var attempts: Int
    var firstAttemptCorrect: Int
    var correctAnswers: Int
    var misses: Int
    var profile: PlayerProfile?

    init(
        id: UUID = UUID(),
        mode: ArithmeticMode,
        tableNumber: Int,
        attempts: Int = 0,
        firstAttemptCorrect: Int = 0,
        correctAnswers: Int = 0,
        misses: Int = 0,
        profile: PlayerProfile? = nil
    ) {
        self.id = id
        self.modeRawValue = mode.rawValue
        self.tableNumber = tableNumber
        self.attempts = attempts
        self.firstAttemptCorrect = firstAttemptCorrect
        self.correctAnswers = correctAnswers
        self.misses = misses
        self.profile = profile
    }

    var mode: ArithmeticMode {
        get { ArithmeticMode(rawValue: modeRawValue) ?? .multiplication }
        set { modeRawValue = newValue.rawValue }
    }
}

private struct LegacyPlayerProgress: Codable {
    var completedTables: [Int] = []
    var completedDifficulties: [String] = []
    var unlockedShips: [String] = ["craft_speederA.dae"]
    var lifetimeStars: Int = 0
}

private struct LegacyPlayerProfile: Codable {
    let id: UUID
    var name: String
    var avatar: PlayerAvatar
    var progress: LegacyPlayerProgress
}

enum ShipCatalog {
    static let allShips: [SpaceShip] = [
        SpaceShip(name: "Nova Striker", modelName: "craft_speederA.dae", unlockRequirement: "Default", unlockLevel: 0),
        SpaceShip(name: "Photon Blade", modelName: "craft_racer.dae", unlockRequirement: "Complete 2× table", unlockLevel: 1),
        SpaceShip(name: "Starfire Interceptor", modelName: "craft_speederB.dae", unlockRequirement: "Complete 3× and 4× tables", unlockLevel: 2),
        SpaceShip(name: "Nebula Runner", modelName: "craft_speederC.dae", unlockRequirement: "Complete 5× and 6× tables", unlockLevel: 3),
        SpaceShip(name: "Asteroid Crusher", modelName: "craft_miner.dae", unlockRequirement: "Complete 7× and 8× tables", unlockLevel: 4),
        SpaceShip(name: "Quantum Falcon", modelName: "craft_speederD.dae", unlockRequirement: "Complete 8× and 9× tables or earn 60 stars", unlockLevel: 5),
        SpaceShip(name: "Titan Hauler", modelName: "craft_cargoA.dae", unlockRequirement: "Complete 11× and 12× tables or earn 120 stars", unlockLevel: 6),
        SpaceShip(name: "Voidbreaker Prime", modelName: "craft_cargoB.dae", unlockRequirement: "Beat Medium and Hard modes or earn 200 stars", unlockLevel: 7)
    ]
}

enum ShipProgression {
    static let starThresholds: [Int: Int] = [
        5: 60,
        6: 120,
        7: 200
    ]

    static func starRequirement(for unlockLevel: Int) -> Int? {
        starThresholds[unlockLevel]
    }

    static func isUnlocked(_ ship: SpaceShip, progress: PlayerProgress) -> Bool {
        if progress.unlockedShips.contains(ship.modelName) || ship.unlockLevel == 0 {
            return true
        }

        switch ship.unlockLevel {
        case 1:
            return progress.completedTables.contains(2)
        case 2:
            return progress.completedTables.contains(3) && progress.completedTables.contains(4)
        case 3:
            return progress.completedTables.contains(5) && progress.completedTables.contains(6)
        case 4:
            return progress.completedTables.contains(7) && progress.completedTables.contains(8)
        case 5:
            return (progress.completedTables.contains(8) && progress.completedTables.contains(9))
                || progress.lifetimeStars >= (starRequirement(for: 5) ?? .max)
        case 6:
            return (progress.completedTables.contains(11) && progress.completedTables.contains(12))
                || progress.lifetimeStars >= (starRequirement(for: 6) ?? .max)
        case 7:
            return (progress.completedDifficulties.contains("medium") && progress.completedDifficulties.contains("hard"))
                || progress.lifetimeStars >= (starRequirement(for: 7) ?? .max)
        default:
            return false
        }
    }

    static func requirementText(for ship: SpaceShip) -> String {
        switch ship.unlockLevel {
        case 5:
            return "Complete 8× and 9× tables or earn \(starRequirement(for: 5) ?? 0) stars"
        case 6:
            return "Complete 11× and 12× tables or earn \(starRequirement(for: 6) ?? 0) stars"
        case 7:
            return "Beat Medium and Hard modes or earn \(starRequirement(for: 7) ?? 0) stars"
        default:
            return ship.unlockRequirement
        }
    }
}

@MainActor
final class PlayerProfileStore: ObservableObject {
    static let shared = PlayerProfileStore()

    let modelContainer: ModelContainer

    @Published private(set) var profiles: [PlayerProfile] = []
    @Published private(set) var activeSession: ActivePlayerSession = .guest
    @Published private(set) var guestProgress = PlayerProgress()

    private let legacyProfilesKey = "playerProfiles"
    private let activeProfileKey = "activeProfileID"
    private let migrationFlagKey = "didMigrateProfilesToSwiftData"

    private var context: ModelContext {
        modelContainer.mainContext
    }

    private init() {
        do {
            modelContainer = try ModelContainer(for: PlayerProfile.self, PlayerTablePerformance.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }

        migrateLegacyProfilesIfNeeded()
        refreshProfiles()
        restoreActiveSession()
    }

    var activeProfile: PlayerProfile? {
        guard case .profile(let id) = activeSession else { return nil }
        return profiles.first(where: { $0.id == id })
    }

    var activeProgress: PlayerProgress {
        switch activeSession {
        case .guest:
            return guestProgress
        case .profile:
            return progressSnapshot(for: activeProfile)
        }
    }

    var activeDisplayName: String {
        activeProfile?.name ?? "Guest"
    }

    var activeAvatar: PlayerAvatar {
        activeProfile?.avatar ?? .avatar1
    }

    var isGuestActive: Bool {
        if case .guest = activeSession {
            return true
        }
        return false
    }

    var activeRank: PlayerRank {
        rank(for: activeProfile)
    }

    func continueAsGuest() {
        guestProgress = PlayerProgress()
        activeSession = .guest
        UserDefaults.standard.removeObject(forKey: activeProfileKey)
    }

    func selectProfile(_ profile: PlayerProfile) {
        activeSession = .profile(profile.id)
        saveActiveProfileID(profile.id)
        refreshProfiles()
    }

    @discardableResult
    func createProfile(name: String, avatar: PlayerAvatar) -> PlayerProfile {
        let cleanName = sanitizedName(name)
        let profile = PlayerProfile(name: cleanName, avatar: avatar)
        context.insert(profile)
        saveContext()
        refreshProfiles()
        if let savedProfile = profiles.first(where: { $0.id == profile.id }) {
            selectProfile(savedProfile)
            return savedProfile
        }
        selectProfile(profile)
        return profile
    }

    func updateProfile(_ profile: PlayerProfile, name: String, avatar: PlayerAvatar) {
        profile.name = sanitizedName(name)
        profile.avatar = avatar
        saveContext()
        refreshProfiles()
    }

    func updateProgress(_ update: (inout PlayerProgress) -> Void) {
        switch activeSession {
        case .guest:
            update(&guestProgress)
        case .profile:
            guard let profile = activeProfile else { return }
            var progress = progressSnapshot(for: profile)
            update(&progress)
            apply(progress: progress, to: profile)
            saveContext()
            refreshProfiles()
        }
        objectWillChange.send()
    }

    @discardableResult
    func awardStars(_ amount: Int) -> MissionStarReward {
        let safeAmount = max(0, amount)
        var newTotal = 0
        updateProgress { progress in
            progress.lifetimeStars += safeAmount
            newTotal = progress.lifetimeStars
        }
        return MissionStarReward(earned: safeAmount, newTotal: newTotal)
    }

    func recordSummary(for profile: PlayerProfile? = nil) -> PlayerRecordSummary {
        let targetProfile = profile ?? activeProfile
        if let targetProfile {
            return PlayerRecordSummary(
                lifetimeStars: targetProfile.lifetimeStars,
                bestStreak: targetProfile.bestStreak,
                bestRunCleared: targetProfile.bestRunCleared,
                totalRuns: targetProfile.totalRuns,
                missionsCompleted: targetProfile.missionsCompleted,
                totalQuestionsSeen: targetProfile.totalQuestionsSeen,
                totalCorrectAnswers: targetProfile.totalCorrectAnswers,
                totalFirstAttemptCorrect: targetProfile.totalFirstAttemptCorrect,
                totalMisses: targetProfile.totalMisses
            )
        }

        return PlayerRecordSummary(
            lifetimeStars: guestProgress.lifetimeStars,
            bestStreak: 0,
            bestRunCleared: 0,
            totalRuns: 0,
            missionsCompleted: 0,
            totalQuestionsSeen: 0,
            totalCorrectAnswers: 0,
            totalFirstAttemptCorrect: 0,
            totalMisses: 0
        )
    }

    func rank(for profile: PlayerProfile? = nil) -> PlayerRank {
        let summary = recordSummary(for: profile)
        let score = summary.lifetimeStars + summary.missionsCompleted * 8 + summary.bestStreak * 2 + summary.firstAttemptAccuracy

        switch score {
        case ..<20:
            return PlayerRank(title: "CADET", detail: "STARTING FLIGHT TRAINING")
        case ..<50:
            return PlayerRank(title: "WINGMAN", detail: "HOLDING A CLEAN FORMATION")
        case ..<90:
            return PlayerRank(title: "PILOT", detail: "CLEARING DECKS WITH CONFIDENCE")
        case ..<140:
            return PlayerRank(title: "ACE", detail: "STACKING STARS ACROSS THE BOARD")
        case ..<210:
            return PlayerRank(title: "COMMANDER", detail: "LEADING THE TRAINING SQUAD")
        default:
            return PlayerRank(title: "STAR CAPTAIN", detail: "MASTER OF THE FULL FLIGHT DECK")
        }
    }

    func unlockedShips(for profile: PlayerProfile? = nil) -> [SpaceShip] {
        let progress = progressSnapshot(for: profile ?? activeProfile)
        return ShipCatalog.allShips.filter { ShipProgression.isUnlocked($0, progress: progress) }
    }

    func performanceSummaries(for mode: ArithmeticMode, profile: PlayerProfile? = nil) -> [TablePerformanceSummary] {
        let targetProfile = profile ?? activeProfile
        let performances = targetProfile?.tablePerformances.filter { $0.mode == mode } ?? []

        return (1...12).map { tableNumber in
            let performance = performances.first(where: { $0.tableNumber == tableNumber })
            return TablePerformanceSummary(
                mode: mode,
                tableNumber: tableNumber,
                attempts: performance?.attempts ?? 0,
                firstAttemptCorrect: performance?.firstAttemptCorrect ?? 0,
                correctAnswers: performance?.correctAnswers ?? 0,
                misses: performance?.misses ?? 0
            )
        }
    }

    func recordSession(_ update: PlayerSessionStatUpdate) {
        guard let profile = activeProfile else { return }

        profile.bestStreak = max(profile.bestStreak, update.bestStreak)
        profile.bestRunCleared = max(profile.bestRunCleared, update.totalCleared)
        profile.totalRuns += 1
        profile.totalQuestionsSeen += update.totalQuestionsSeen
        profile.totalCorrectAnswers += update.totalCorrectAnswers
        profile.totalFirstAttemptCorrect += update.totalFirstAttemptCorrect
        profile.totalMisses += update.totalMisses

        if update.didCompleteMission {
            profile.missionsCompleted += 1
        }

        for tableNumber in 1...12 {
            let attempts = update.tableAttempts[tableNumber, default: 0]
            let firstAttempt = update.tableFirstAttemptCorrect[tableNumber, default: 0]
            let correct = update.tableCorrectAnswers[tableNumber, default: 0]
            let misses = update.tableMisses[tableNumber, default: 0]

            guard attempts > 0 || firstAttempt > 0 || correct > 0 || misses > 0 else { continue }

            let performance = performanceRecord(for: profile, mode: update.arithmeticMode, tableNumber: tableNumber)
                ?? createPerformanceRecord(for: profile, mode: update.arithmeticMode, tableNumber: tableNumber)

            performance.attempts += attempts
            performance.firstAttemptCorrect += firstAttempt
            performance.correctAnswers += correct
            performance.misses += misses
        }

        saveContext()
        refreshProfiles()
    }

    func sanitizedName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(20))
    }

    func refreshProfiles() {
        let descriptor = FetchDescriptor<PlayerProfile>(sortBy: [SortDescriptor(\.name)])
        profiles = (try? context.fetch(descriptor)) ?? []

        if case .profile(let id) = activeSession,
           !profiles.contains(where: { $0.id == id }) {
            activeSession = .guest
        }
    }

    private func progressSnapshot(for profile: PlayerProfile?) -> PlayerProgress {
        guard let profile else { return PlayerProgress() }
        return PlayerProgress(
            completedTables: profile.completedTables,
            completedDifficulties: profile.completedDifficulties,
            unlockedShips: profile.unlockedShips,
            lifetimeStars: profile.lifetimeStars
        )
    }

    private func apply(progress: PlayerProgress, to profile: PlayerProfile) {
        profile.completedTables = Array(Set(progress.completedTables)).sorted()
        profile.completedDifficulties = Array(Set(progress.completedDifficulties)).sorted()
        profile.unlockedShips = Array(Set(progress.unlockedShips)).sorted()
        profile.lifetimeStars = progress.lifetimeStars
    }

    private func performanceRecord(for profile: PlayerProfile, mode: ArithmeticMode, tableNumber: Int) -> PlayerTablePerformance? {
        profile.tablePerformances.first {
            $0.mode == mode && $0.tableNumber == tableNumber
        }
    }

    private func createPerformanceRecord(for profile: PlayerProfile, mode: ArithmeticMode, tableNumber: Int) -> PlayerTablePerformance {
        let record = PlayerTablePerformance(mode: mode, tableNumber: tableNumber, profile: profile)
        context.insert(record)
        profile.tablePerformances.append(record)
        return record
    }

    private func restoreActiveSession() {
        let defaults = UserDefaults.standard
        if let rawID = defaults.string(forKey: activeProfileKey),
           let profileID = UUID(uuidString: rawID),
           profiles.contains(where: { $0.id == profileID }) {
            activeSession = .profile(profileID)
        } else {
            activeSession = .guest
        }
    }

    private func migrateLegacyProfilesIfNeeded() {
        let defaults = UserDefaults.standard
        let descriptor = FetchDescriptor<PlayerProfile>()
        let existingProfiles = (try? context.fetchCount(descriptor)) ?? 0

        guard existingProfiles == 0 || defaults.bool(forKey: migrationFlagKey) == false else { return }

        if let data = defaults.data(forKey: legacyProfilesKey),
           let decoded = try? JSONDecoder().decode([LegacyPlayerProfile].self, from: data) {
            for legacyProfile in decoded {
                let profile = PlayerProfile(
                    id: legacyProfile.id,
                    name: legacyProfile.name,
                    avatar: legacyProfile.avatar,
                    progress: PlayerProgress(
                        completedTables: legacyProfile.progress.completedTables,
                        completedDifficulties: legacyProfile.progress.completedDifficulties,
                        unlockedShips: legacyProfile.progress.unlockedShips,
                        lifetimeStars: legacyProfile.progress.lifetimeStars
                    )
                )
                context.insert(profile)
            }
            saveContext()
        }

        defaults.set(true, forKey: migrationFlagKey)
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save player profile context: \(error)")
        }
    }

    private func saveActiveProfileID(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: activeProfileKey)
    }
}

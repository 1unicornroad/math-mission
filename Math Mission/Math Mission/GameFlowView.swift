//
//  GameFlowView.swift
//  Math Mission
//
//  Created by John Ostler on 3/7/26.
//

import SwiftUI

struct GameFlowView: View {
    let selectedShipModel: String
    let selectedTables: [Int]
    let arithmeticMode: ArithmeticMode
    let customProblems: [String]
    let difficulty: Difficulty
    let onExitToMenu: () -> Void
    @StateObject private var profileStore = PlayerProfileStore.shared
    
    @State private var showingUnlockScreen = false
    @State private var newlyUnlockedShips: [SpaceShip] = []
    @State private var currentCustomProblems: [String]
    @State private var replayFocusProblems: [String]
    @State private var isReplaySession = false
    @State private var gameKey = UUID()  // Force recreate game view
    @State private var shouldBeginGameplay = false
    @State private var transitionOpacity = 1.0
    
    init(
        selectedShipModel: String,
        selectedTables: [Int],
        arithmeticMode: ArithmeticMode,
        customProblems: [String],
        difficulty: Difficulty,
        onExitToMenu: @escaping () -> Void
    ) {
        self.selectedShipModel = selectedShipModel
        self.selectedTables = selectedTables
        self.arithmeticMode = arithmeticMode
        self.customProblems = customProblems
        self.difficulty = difficulty
        self.onExitToMenu = onExitToMenu
        self._currentCustomProblems = State(initialValue: customProblems)
        self._replayFocusProblems = State(initialValue: [])
    }
    
    func beginLaunchSequence() {
        withAnimation(.easeOut(duration: 0.18)) {
            transitionOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            shouldBeginGameplay = true
            
            withAnimation(.easeInOut(duration: 0.55)) {
                transitionOpacity = 0.0
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Game view
            GameViewControllerWrapper(
                selectedShipModel: selectedShipModel,
                selectedTables: selectedTables,
                arithmeticMode: arithmeticMode,
                customProblems: currentCustomProblems,
                replayFocusProblems: replayFocusProblems,
                isReplaySession: isReplaySession,
                shouldBeginGameplay: shouldBeginGameplay,
                difficulty: difficulty,
                onGameOver: handleGameOver,
                onPlayAgain: handlePlayAgain,
                onExitToMenu: onExitToMenu
            )
            .id(gameKey)  // Recreate when key changes
            .ignoresSafeArea()
            
            Color.black
                .ignoresSafeArea()
                .opacity(transitionOpacity)
                .allowsHitTesting(transitionOpacity > 0.01)
                .zIndex(showingUnlockScreen ? 0 : 2)
            
            // Unlock screen overlay
            if showingUnlockScreen && !newlyUnlockedShips.isEmpty {
                ShipUnlockView(unlockedShips: newlyUnlockedShips) {
                    // Continue to main menu after viewing unlocks
                    onExitToMenu()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            beginLaunchSequence()
        }
    }
    
    func handleGameOver(meteorsDestroyed: Int, firstAttemptCorrect: Int, perfectProblems: [String: Int]) {
        // Check for newly unlocked ships
        let unlockedShips = checkForUnlocks(
            meteorsDestroyed: meteorsDestroyed,
            firstAttemptCorrect: firstAttemptCorrect,
            perfectProblems: perfectProblems,
            selectedTables: selectedTables,
            arithmeticMode: arithmeticMode,
            difficulty: difficulty
        )
        
        if !unlockedShips.isEmpty {
            newlyUnlockedShips = unlockedShips
            // Show unlock screen after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showingUnlockScreen = true
                }
            }
        } else {
            onExitToMenu()
        }
    }
    
    func handlePlayAgain(missedProblems: [String]) {
        print("🎮 Restarting game with \(missedProblems.count) missed problems")
        let normalizedMissed = missedProblems.map(normalizedProblemKey)
        replayFocusProblems = Array(Set(normalizedMissed)).sorted()
        currentCustomProblems = buildReplayProblemDeck(from: normalizedMissed)
        isReplaySession = true
        shouldBeginGameplay = false
        transitionOpacity = 1.0
        // Force recreate the game view
        gameKey = UUID()
        DispatchQueue.main.async {
            beginLaunchSequence()
        }
    }
    
    func checkForUnlocks(meteorsDestroyed: Int, firstAttemptCorrect: Int, perfectProblems: [String: Int], selectedTables: [Int], arithmeticMode: ArithmeticMode, difficulty: Difficulty) -> [SpaceShip] {
        var updatedProgress = profileStore.activeProgress
        
        var newlyUnlocked: [SpaceShip] = []
        
        // Check each selected table to see if all 12 multiples were answered perfectly at least once
        if arithmeticMode == .multiplication {
            for table in selectedTables {
                if updatedProgress.completedTables.contains(table) {
                    continue  // Already completed
                }
                
                var completedAll = true
                for multiplier in 1...12 {
                    let problem1 = "\(multiplier)×\(table)"
                    let problem2 = "\(table)×\(multiplier)"
                    let count1 = perfectProblems[problem1] ?? 0
                    let count2 = perfectProblems[problem2] ?? 0
                    
                    if count1 + count2 < 1 {
                        completedAll = false
                        break
                    }
                }
                
                if completedAll {
                    updatedProgress.completedTables.append(table)
                }
            }
        }
            
        
        // Mark difficulty as completed only when the player actually clears the mission
        if meteorsDestroyed >= 30 {
            let difficultyString = difficultyToString(difficulty)
            if !updatedProgress.completedDifficulties.contains(difficultyString) {
                updatedProgress.completedDifficulties.append(difficultyString)
            }
        }
        
        // Check which ships are newly unlocked
        let allShips = ShipCatalog.allShips
        
        // Get previously unlocked ships
        let previouslyUnlockedShips = updatedProgress.unlockedShips
        var currentlyUnlockedShips = previouslyUnlockedShips
        
        for ship in allShips {
            if previouslyUnlockedShips.contains(ship.modelName) {
                continue // Already unlocked before this game
            }
            
            let isNowUnlocked = ShipProgression.isUnlocked(ship, progress: updatedProgress)
            
            if isNowUnlocked {
                newlyUnlocked.append(ship)
                currentlyUnlockedShips.append(ship.modelName)
            }
        }
        updatedProgress.completedTables = Array(Set(updatedProgress.completedTables)).sorted()
        updatedProgress.completedDifficulties = Array(Set(updatedProgress.completedDifficulties)).sorted()
        updatedProgress.unlockedShips = Array(Set(currentlyUnlockedShips)).sorted()
        profileStore.updateProgress { progress in
            progress = updatedProgress
        }
        
        return newlyUnlocked
    }
    
    func difficultyToString(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        }
    }

    func buildReplayProblemDeck(from missedProblems: [String]) -> [String] {
        let baseProblems: [String]
        if !customProblems.isEmpty {
            baseProblems = customProblems.map(normalizedProblemKey)
        } else {
            baseProblems = selectedTables
                .sorted()
                .flatMap { table in
                    (1...12).map { arithmeticMode.practiceKey(lhs: $0, rhs: table) }
                }
        }

        let normalizedBase = Array(Set(baseProblems)).sorted()
        let weightedMissed = missedProblems + missedProblems + missedProblems
        let weightedDeck = normalizedBase + weightedMissed
        return weightedDeck.isEmpty ? Array(Set(missedProblems)).sorted() : weightedDeck
    }

    func normalizedProblemKey(_ problem: String) -> String {
        problem
            .replacingOccurrences(of: " = ?", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

// Wrapper that can communicate back to SwiftUI
struct GameViewControllerWrapper: UIViewControllerRepresentable {
    let selectedShipModel: String
    let selectedTables: [Int]
    let arithmeticMode: ArithmeticMode
    let customProblems: [String]
    let replayFocusProblems: [String]
    let isReplaySession: Bool
    let shouldBeginGameplay: Bool
    let difficulty: Difficulty
    let onGameOver: (Int, Int, [String: Int]) -> Void
    let onPlayAgain: ([String]) -> Void
    let onExitToMenu: () -> Void
    
    func makeUIViewController(context: Context) -> GameViewController {
        let gameVC = GameViewController()
        gameVC.selectedShipModel = selectedShipModel
        gameVC.selectedTables = selectedTables
        gameVC.arithmeticMode = arithmeticMode
        gameVC.customProblems = customProblems
        gameVC.replayFocusProblems = replayFocusProblems
        gameVC.isReplaySession = isReplaySession
        gameVC.difficulty = difficulty
        
        // Set callbacks
        context.coordinator.onGameOver = onGameOver
        context.coordinator.onPlayAgain = onPlayAgain
        context.coordinator.onExitToMenu = onExitToMenu
        
        gameVC.gameOverCallback = { meteorsDestroyed, firstAttemptCorrect, perfectProblems in
            context.coordinator.onGameOver(meteorsDestroyed, firstAttemptCorrect, perfectProblems)
        }
        
        gameVC.playAgainCallback = { missedProblems in
            context.coordinator.onPlayAgain(missedProblems)
        }
        
        gameVC.exitToMenuCallback = {
            context.coordinator.onExitToMenu()
        }
        
        return gameVC
    }
    
    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        uiViewController.arithmeticMode = arithmeticMode
        uiViewController.customProblems = customProblems
        uiViewController.replayFocusProblems = replayFocusProblems
        uiViewController.isReplaySession = isReplaySession
        if shouldBeginGameplay {
            uiViewController.beginGameplayIfNeeded()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var onGameOver: (Int, Int, [String: Int]) -> Void = { _, _, _ in }
        var onPlayAgain: ([String]) -> Void = { _ in }
        var onExitToMenu: () -> Void = {}
    }
}

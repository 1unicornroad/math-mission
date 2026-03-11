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
        let defaults = UserDefaults.standard
        var previouslyCompletedTables = defaults.array(forKey: "completedTables") as? [Int] ?? []
        var previouslyCompletedDifficulties = defaults.array(forKey: "completedDifficulties") as? [String] ?? []
        
        var newlyUnlocked: [SpaceShip] = []
        
        // Check each selected table to see if all 12 multiples were answered perfectly TWICE
        if arithmeticMode == .multiplication {
            for table in selectedTables {
                if previouslyCompletedTables.contains(table) {
                    continue  // Already completed
                }
                
                var completedAll = true
                for multiplier in 1...12 {
                    let problem1 = "\(multiplier)×\(table)"
                    let problem2 = "\(table)×\(multiplier)"
                    let count1 = perfectProblems[problem1] ?? 0
                    let count2 = perfectProblems[problem2] ?? 0
                    
                    if count1 + count2 < 2 {
                        completedAll = false
                        break
                    }
                }
                
                if completedAll {
                    previouslyCompletedTables.append(table)
                }
            }
        }
            
        
        // Mark difficulty as completed if player got 10+ perfect in medium/hard
        if firstAttemptCorrect >= 10 {
            let difficultyString = difficultyToString(difficulty)
            if !previouslyCompletedDifficulties.contains(difficultyString) {
                previouslyCompletedDifficulties.append(difficultyString)
            }
        }
        
        // Save to UserDefaults
        defaults.set(previouslyCompletedTables, forKey: "completedTables")
        defaults.set(previouslyCompletedDifficulties, forKey: "completedDifficulties")
        
        // Check which ships are newly unlocked
        let allShips: [SpaceShip] = [
            SpaceShip(name: "Nova Striker", modelName: "craft_speederA.dae", unlockRequirement: "Default", unlockLevel: 0),
            SpaceShip(name: "Photon Blade", modelName: "craft_racer.dae", unlockRequirement: "Complete 2× table", unlockLevel: 1),
            SpaceShip(name: "Starfire Interceptor", modelName: "craft_speederB.dae", unlockRequirement: "Complete 3× and 4× tables", unlockLevel: 2),
            SpaceShip(name: "Nebula Runner", modelName: "craft_speederC.dae", unlockRequirement: "Complete 5× and 6× tables", unlockLevel: 3),
            SpaceShip(name: "Asteroid Crusher", modelName: "craft_miner.dae", unlockRequirement: "Complete 7× and 8× tables", unlockLevel: 4),
            SpaceShip(name: "Quantum Falcon", modelName: "craft_speederD.dae", unlockRequirement: "Complete 8× and 9× tables", unlockLevel: 5),
            SpaceShip(name: "Titan Hauler", modelName: "craft_cargoA.dae", unlockRequirement: "Complete 11× and 12× tables", unlockLevel: 6),
            SpaceShip(name: "Voidbreaker Prime", modelName: "craft_cargoB.dae", unlockRequirement: "Beat Medium and Hard modes", unlockLevel: 7)
        ]
        
        // Get previously unlocked ships
        let previouslyUnlockedShips = defaults.array(forKey: "previouslyUnlockedShips") as? [String] ?? ["craft_speederA.dae"]
        var currentlyUnlockedShips = previouslyUnlockedShips
        
        for ship in allShips {
            if previouslyUnlockedShips.contains(ship.modelName) {
                continue // Already unlocked before this game
            }
            
            let isNowUnlocked: Bool
            switch ship.unlockLevel {
            case 0:
                isNowUnlocked = true
            case 1:
                isNowUnlocked = previouslyCompletedTables.contains(2)  // Just 2× table now
            case 2:
                isNowUnlocked = previouslyCompletedTables.contains(3) && previouslyCompletedTables.contains(4)
            case 3:
                isNowUnlocked = previouslyCompletedTables.contains(5) && previouslyCompletedTables.contains(6)
            case 4:
                isNowUnlocked = previouslyCompletedTables.contains(7) && previouslyCompletedTables.contains(8)
            case 5:
                isNowUnlocked = previouslyCompletedTables.contains(8) && previouslyCompletedTables.contains(9)
            case 6:
                isNowUnlocked = previouslyCompletedTables.contains(11) && previouslyCompletedTables.contains(12)
            case 7:
                isNowUnlocked = previouslyCompletedDifficulties.contains("medium") && previouslyCompletedDifficulties.contains("hard")
            default:
                isNowUnlocked = false
            }
            
            if isNowUnlocked {
                newlyUnlocked.append(ship)
                currentlyUnlockedShips.append(ship.modelName)
            }
        }
        
        // Save updated unlocked ships
        defaults.set(currentlyUnlockedShips, forKey: "previouslyUnlockedShips")
        
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

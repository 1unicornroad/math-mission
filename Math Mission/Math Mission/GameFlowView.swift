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
    let customProblems: [String]
    let difficulty: Difficulty
    let onExitToMenu: () -> Void
    
    @State private var showingUnlockScreen = false
    @State private var newlyUnlockedShips: [SpaceShip] = []
    @State private var currentCustomProblems: [String]
    @State private var isReplaySession = false
    @State private var gameKey = UUID()  // Force recreate game view
    
    init(
        selectedShipModel: String,
        selectedTables: [Int],
        customProblems: [String],
        difficulty: Difficulty,
        onExitToMenu: @escaping () -> Void
    ) {
        self.selectedShipModel = selectedShipModel
        self.selectedTables = selectedTables
        self.customProblems = customProblems
        self.difficulty = difficulty
        self.onExitToMenu = onExitToMenu
        self._currentCustomProblems = State(initialValue: customProblems)
    }
    
    var body: some View {
        ZStack {
            // Game view
            GameViewControllerWrapper(
                selectedShipModel: selectedShipModel,
                selectedTables: selectedTables,
                customProblems: currentCustomProblems,
                isReplaySession: isReplaySession,
                difficulty: difficulty,
                onGameOver: handleGameOver,
                onPlayAgain: handlePlayAgain,
                onExitToMenu: onExitToMenu
            )
            .id(gameKey)  // Recreate when key changes
            .ignoresSafeArea()
            
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
    }
    
    func handleGameOver(meteorsDestroyed: Int, firstAttemptCorrect: Int, perfectProblems: [String: Int]) {
        // Check for newly unlocked ships
        let unlockedShips = checkForUnlocks(
            meteorsDestroyed: meteorsDestroyed,
            firstAttemptCorrect: firstAttemptCorrect,
            perfectProblems: perfectProblems,
            selectedTables: selectedTables,
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
        // Update to use missed problems as custom problems
        currentCustomProblems = missedProblems
        isReplaySession = true
        // Force recreate the game view
        gameKey = UUID()
    }
    
    func checkForUnlocks(meteorsDestroyed: Int, firstAttemptCorrect: Int, perfectProblems: [String: Int], selectedTables: [Int], difficulty: Difficulty) -> [SpaceShip] {
        let defaults = UserDefaults.standard
        var previouslyCompletedTables = defaults.array(forKey: "completedTables") as? [Int] ?? []
        var previouslyCompletedDifficulties = defaults.array(forKey: "completedDifficulties") as? [String] ?? []
        
        var newlyUnlocked: [SpaceShip] = []
        
        // Check each selected table to see if all 12 multiples were answered perfectly TWICE
        for table in selectedTables {
            if previouslyCompletedTables.contains(table) {
                continue  // Already completed
            }
            
            // Check if all 12 problems for this table were answered perfectly at least twice
            var completedAll = true
            for multiplier in 1...12 {
                let problem1 = "\(multiplier)×\(table)"  // e.g. "3×4"
                let problem2 = "\(table)×\(multiplier)"  // e.g. "4×3" (commutative)
                
                let count1 = perfectProblems[problem1] ?? 0
                let count2 = perfectProblems[problem2] ?? 0
                
                // Need at least 2 perfect answers (can be either order or combination)
                if count1 + count2 < 2 {
                    completedAll = false
                    break
                }
            }
            
            // If all 12 problems for this table were perfect at least twice, mark it complete
            if completedAll {
                previouslyCompletedTables.append(table)
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
            SpaceShip(name: "Quantum Falcon", modelName: "craft_speederD.dae", unlockRequirement: "Complete 9× and 10× tables", unlockLevel: 5),
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
                isNowUnlocked = previouslyCompletedTables.contains(9) && previouslyCompletedTables.contains(10)
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
}

// Wrapper that can communicate back to SwiftUI
struct GameViewControllerWrapper: UIViewControllerRepresentable {
    let selectedShipModel: String
    let selectedTables: [Int]
    let customProblems: [String]
    let isReplaySession: Bool
    let difficulty: Difficulty
    let onGameOver: (Int, Int, [String: Int]) -> Void
    let onPlayAgain: ([String]) -> Void
    let onExitToMenu: () -> Void
    
    func makeUIViewController(context: Context) -> GameViewController {
        let gameVC = GameViewController()
        gameVC.selectedShipModel = selectedShipModel
        gameVC.selectedTables = selectedTables
        gameVC.customProblems = customProblems
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
        uiViewController.customProblems = customProblems
        uiViewController.isReplaySession = isReplaySession
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

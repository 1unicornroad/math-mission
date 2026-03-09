//
//  ShipSelectionView.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import SwiftUI

struct ShipSelectionView: View {
    let selectedTables: [Int]
    let isCustomMode: Bool
    var selectedProblems: [String] = []
    let onReturnToMenu: () -> Void
    
    @Binding var selectedDifficulty: Difficulty
    @State private var selectedShip: SpaceShip
    @State private var showingGame = false
    @Environment(\.dismiss) private var dismiss
    
    let ships: [SpaceShip] = [
        SpaceShip(name: "Nova Striker", modelName: "craft_speederA.dae", unlockRequirement: "Default", unlockLevel: 0),
        SpaceShip(name: "Photon Blade", modelName: "craft_racer.dae", unlockRequirement: "Complete 2× table", unlockLevel: 1),
        SpaceShip(name: "Starfire Interceptor", modelName: "craft_speederB.dae", unlockRequirement: "Complete 3× and 4× tables", unlockLevel: 2),
        SpaceShip(name: "Nebula Runner", modelName: "craft_speederC.dae", unlockRequirement: "Complete 5× and 6× tables", unlockLevel: 3),
        SpaceShip(name: "Asteroid Crusher", modelName: "craft_miner.dae", unlockRequirement: "Complete 7× and 8× tables", unlockLevel: 4),
        SpaceShip(name: "Quantum Falcon", modelName: "craft_speederD.dae", unlockRequirement: "Complete 9× and 10× tables", unlockLevel: 5),
        SpaceShip(name: "Titan Hauler", modelName: "craft_cargoA.dae", unlockRequirement: "Complete 11× and 12× tables", unlockLevel: 6),
        SpaceShip(name: "Voidbreaker Prime", modelName: "craft_cargoB.dae", unlockRequirement: "Beat Medium and Hard modes", unlockLevel: 7)
    ]
    
    init(
        selectedTables: [Int],
        selectedDifficulty: Binding<Difficulty>,
        isCustomMode: Bool,
        selectedProblems: [String] = [],
        onReturnToMenu: @escaping () -> Void = {}
    ) {
        self.selectedTables = selectedTables
        self.isCustomMode = isCustomMode
        self.selectedProblems = selectedProblems
        self.onReturnToMenu = onReturnToMenu
        self._selectedDifficulty = selectedDifficulty
        self._selectedShip = State(initialValue: ships[0])
    }
    
    var body: some View {
        ZStack {
            ArcadeBackground(variant: .quiet)
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    hangarHeader
                    difficultySelector
                    
                    TabView(selection: $selectedShip) {
                        ForEach(ships, id: \.modelName) { ship in
                            ShipCardView(
                                ship: ship,
                                isUnlocked: checkIfUnlocked(ship),
                                isSelected: selectedShip.modelName == ship.modelName
                            )
                            .tag(ship)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 320)
                    
                    HStack(spacing: 8) {
                        ForEach(ships.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == selectedShipIndex ? ArcadePalette.signalBright : Color.white.opacity(0.14))
                                .frame(width: index == selectedShipIndex ? 28 : 10, height: 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) {
                            Button {
                                dismiss()
                            } label: {
                                ArcadeSecondaryActionLabel(title: "Back")
                            }
                            .buttonStyle(.plain)
                            .frame(width: 148)
                            
                            startButton
                        }
                        
                        VStack(spacing: 12) {
                            Button {
                                dismiss()
                            } label: {
                                ArcadeSecondaryActionLabel(title: "Back")
                            }
                            .buttonStyle(.plain)
                            
                            startButton
                        }
                    }
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 34)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
        }
        .fullScreenCover(isPresented: $showingGame) {
            GameFlowView(
                selectedShipModel: selectedShip.modelName,
                selectedTables: selectedTables,
                customProblems: selectedProblems,
                difficulty: selectedDifficulty,
                onExitToMenu: returnToTopLevelMenu
            )
        }
        .statusBar(hidden: true)
    }
    
    private var hangarHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SELECT SHIP")
                .font(.custom("Orbitron-Bold", size: 34))
                .foregroundColor(ArcadePalette.textPrimary)
            
            Text(hangarSummary)
                .font(.custom("Exo 2 SemiBold", size: 13))
                .foregroundColor(ArcadePalette.signalBright)
                .tracking(1.2)
        }
        .padding(.horizontal, 4)
    }
    
    private var difficultySelector: some View {
        ArcadePanel(accent: ArcadePalette.coolLine) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("DIFFICULTY")
                        .font(.custom("Exo 2 SemiBold", size: 12))
                        .foregroundColor(ArcadePalette.textPrimary)
                        .tracking(1.2)
                    
                    Spacer(minLength: 8)
                    
                    Text(selectedDifficulty.title)
                        .font(.custom("Exo 2 SemiBold", size: 11))
                        .foregroundColor(ArcadePalette.textSecondary)
                        .tracking(0.8)
                }
                
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        difficultyOptions
                    }
                    
                    VStack(spacing: 10) {
                        difficultyOptions
                    }
                }
            }
        }
    }
    
    private var selectedShipUnlocked: Bool {
        checkIfUnlocked(selectedShip)
    }
    
    private var selectedShipIndex: Int {
        ships.firstIndex(where: { $0.modelName == selectedShip.modelName }) ?? 0
    }
    
    private var hangarSummary: String {
        if isCustomMode {
            return "\(selectedProblems.count) TARGETS"
        }
        
        guard !selectedTables.isEmpty else { return "NO TABLES" }
        return selectedTables
            .sorted()
            .map { "\($0)×" }
            .joined(separator: " • ")
    }
    
    private var difficultyOptions: some View {
        ForEach([Difficulty.easy, .medium, .hard], id: \.self) { difficulty in
            Button {
                selectedDifficulty = difficulty
            } label: {
                HangarDifficultyCard(
                    difficulty: difficulty,
                    isSelected: selectedDifficulty == difficulty
                )
            }
        }
    }
    
    private var startButton: some View {
        Button {
            if selectedShipUnlocked {
                showingGame = true
            }
        } label: {
            ArcadePrimaryActionLabel(
                title: "Launch",
                enabled: selectedShipUnlocked
            )
        }
        .buttonStyle(.plain)
        .disabled(!selectedShipUnlocked)
    }
    
    func checkIfUnlocked(_ ship: SpaceShip) -> Bool {
        if ship.unlockLevel == 0 { return true }
        
        let defaults = UserDefaults.standard
        let completedTables = defaults.array(forKey: "completedTables") as? [Int] ?? []
        let completedDifficulties = defaults.array(forKey: "completedDifficulties") as? [String] ?? []
        
        switch ship.unlockLevel {
        case 1: return completedTables.contains(2)  // Just 2× table now
        case 2: return completedTables.contains(3) && completedTables.contains(4)
        case 3: return completedTables.contains(5) && completedTables.contains(6)
        case 4: return completedTables.contains(7) && completedTables.contains(8)
        case 5: return completedTables.contains(9) && completedTables.contains(10)
        case 6: return completedTables.contains(11) && completedTables.contains(12)
        case 7: return completedDifficulties.contains("medium") && completedDifficulties.contains("hard")
        default: return false
        }
    }
    
    private func returnToTopLevelMenu() {
        showingGame = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            onReturnToMenu()
        }
    }
}

struct ShipCardView: View {
    let ship: SpaceShip
    let isUnlocked: Bool
    let isSelected: Bool
    
    var body: some View {
        ArcadePanel(accent: accentColor) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [ArcadePalette.panelBottom.opacity(0.96), Color.black.opacity(0.62)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(ArcadePalette.panelLine.opacity(0.9), lineWidth: 1.0)
                    
                    ArcadeAssetPreviewView(
                        modelName: ship.modelName,
                        isDimmed: false,
                        cameraZ: 3.5,
                        scale: 1.0,
                        yRotation: Float.pi / 4,
                        rotationDuration: 6
                    )
                    .padding(8)
                    
                    if !isUnlocked {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.42))
                        Image(systemName: "lock.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(ArcadePalette.warning)
                            .padding(18)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.62))
                            )
                            .overlay(
                                Circle()
                                    .stroke(ArcadePalette.warning.opacity(0.72), lineWidth: 1.4)
                            )
                    }
                }
                .frame(height: 180)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(ship.name.uppercased())
                        .font(.custom("Orbitron-Bold", size: 19))
                        .foregroundColor(ArcadePalette.textPrimary)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                    
                    Text(isUnlocked ? "READY" : "LOCKED")
                        .font(.custom("Exo 2 SemiBold", size: 12))
                        .foregroundColor(isUnlocked ? ArcadePalette.signalBright : ArcadePalette.warning)
                        .tracking(1.4)
                    
                    if !isUnlocked {
                        Text(ship.unlockRequirement.uppercased())
                            .font(.custom("Exo 2 Medium", size: 13))
                            .foregroundColor(ArcadePalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var accentColor: Color {
        if isSelected && isUnlocked { return ArcadePalette.signal }
        if isUnlocked { return ArcadePalette.coolLine }
        return ArcadePalette.warning
    }
}

private struct HangarDifficultyCard: View {
    let difficulty: Difficulty
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(difficulty.title)
                .font(.custom("Orbitron-Bold", size: 16))
                .foregroundColor(.white)
            Text(description)
                .font(.custom("Exo 2 SemiBold", size: 10))
                .foregroundColor(isSelected ? Color.white.opacity(0.78) : ArcadePalette.textSecondary)
                .tracking(1.1)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isSelected
                        ? ArcadePalette.coolLine.opacity(0.18)
                        : ArcadePalette.panelBottom.opacity(0.82)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isSelected ? ArcadePalette.coolLine : ArcadePalette.panelLine.opacity(0.85),
                    lineWidth: isSelected ? 1.5 : 1.0
                )
        )
    }
    
    private var description: String {
        switch difficulty {
        case .easy:
            return "2 chances"
        case .medium:
            return "1 chance"
        case .hard:
            return "4 answers"
        }
    }
}

//
//  ShipSelectionView.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import SwiftUI

struct ShipSelectionView: View {
    let selectedTables: [Int]
    let arithmeticMode: ArithmeticMode
    let isCustomMode: Bool
    var selectedProblems: [String] = []
    let onReturnToMenu: () -> Void
    
    @StateObject private var profileStore = PlayerProfileStore.shared
    @Binding var selectedDifficulty: Difficulty
    @State private var selectedShip: SpaceShip
    @State private var showingGame = false
    @State private var isLaunching = false
    @State private var launchFadeOpacity = 0.0
    @Environment(\.dismiss) private var dismiss
    
    let ships: [SpaceShip] = ShipCatalog.allShips
    
    init(
        selectedTables: [Int],
        arithmeticMode: ArithmeticMode,
        selectedDifficulty: Binding<Difficulty>,
        isCustomMode: Bool,
        selectedProblems: [String] = [],
        onReturnToMenu: @escaping () -> Void = {}
    ) {
        self.selectedTables = selectedTables
        self.arithmeticMode = arithmeticMode
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
                                ship: shipWithProgressText(ship),
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
                                AudioManager.shared.playButtonTap()
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
                                AudioManager.shared.playButtonTap()
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
            
            Color.black
                .ignoresSafeArea()
                .opacity(launchFadeOpacity)
                .allowsHitTesting(isLaunching)
        }
        .fullScreenCover(isPresented: $showingGame) {
            GameFlowView(
                selectedShipModel: selectedShip.modelName,
                selectedTables: selectedTables,
                arithmeticMode: arithmeticMode,
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
            return arithmeticMode == .multiplication
                ? "\(selectedProblems.count) TARGETS"
                : "\(selectedProblems.count) DIVISION TARGETS"
        }
        
        guard !selectedTables.isEmpty else { return "NO TABLES" }
        return selectedTables
            .sorted()
            .map { arithmeticMode.tableSummary(for: $0) }
            .joined(separator: " • ")
    }
    
    private var difficultyOptions: some View {
        ForEach([Difficulty.easy, .medium, .hard], id: \.self) { difficulty in
            Button {
                AudioManager.shared.playButtonTap()
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
                AudioManager.shared.playButtonTap()
                beginLaunchTransition()
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
        ShipProgression.isUnlocked(ship, progress: profileStore.activeProgress)
    }

    private func shipWithProgressText(_ ship: SpaceShip) -> SpaceShip {
        SpaceShip(
            name: ship.name,
            modelName: ship.modelName,
            unlockRequirement: ShipProgression.requirementText(for: ship),
            unlockLevel: ship.unlockLevel
        )
    }
    
    private func returnToTopLevelMenu() {
        showingGame = false
        isLaunching = true
        launchFadeOpacity = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            onReturnToMenu()
        }
    }
    
    private func beginLaunchTransition() {
        guard !isLaunching else { return }
        isLaunching = true
        AudioManager.shared.stopMenuMusic()
        
        withAnimation(.easeInOut(duration: 0.4)) {
            launchFadeOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            showingGame = true
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

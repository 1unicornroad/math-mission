//
//  MenuView.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import SwiftUI

struct MenuView: View {
    @State private var selectedTables: Set<Int> = []
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var showingShipSelection = false
    @State private var showingCustomPractice = false
    @State private var isSetupRevealed = false
    @State private var startPromptPulse = false
    @State private var titlePulse = false
    @State private var signalBlink = false
    @State private var readyPulse = false
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ArcadeBackground(variant: isSetupRevealed ? .quiet : .standard)
                
                VStack(spacing: 0) {
                    attractScreen(containerHeight: geometry.size.height)
                    setupRevealScreen(containerHeight: geometry.size.height)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .offset(y: isSetupRevealed ? -geometry.size.height : 0)
                .clipped()
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.42), value: isSetupRevealed)
        .onAppear {
            AudioManager.shared.startMenuMusic()
            restartAnimations()
        }
        .onDisappear {
            AudioManager.shared.stopMenuMusic()
            resetAnimations()
        }
        .onChange(of: showingShipSelection) { _, isPresented in
            if isPresented {
                resetAnimations()
            } else {
                AudioManager.shared.startMenuMusic()
                restartAnimations()
            }
        }
        .onChange(of: showingCustomPractice) { _, isPresented in
            if isPresented {
                resetAnimations()
            } else {
                AudioManager.shared.startMenuMusic()
                restartAnimations()
            }
        }
        .onChange(of: isSetupRevealed) { _, _ in
            restartAnimations()
        }
        .fullScreenCover(isPresented: $showingShipSelection) {
            ShipSelectionView(
                selectedTables: selectedTables.sorted(),
                selectedDifficulty: $selectedDifficulty,
                isCustomMode: false,
                onReturnToMenu: {
                    showingShipSelection = false
                    revealSetup()
                }
            )
        }
        .fullScreenCover(isPresented: $showingCustomPractice) {
            CustomPracticeView(selectedDifficulty: $selectedDifficulty)
        }
        .statusBar(hidden: true)
    }
    
    private func attractScreen(containerHeight: CGFloat) -> some View {
        VStack(spacing: 18) {
            Spacer()
            
            ArcadeSignalLights(isActive: signalBlink, accent: ArcadePalette.signalBright)
            
            Text("MATH BLAST")
                .font(.custom("Orbitron-Bold", size: 44))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .scaleEffect(titlePulse ? 1.02 : 0.985)
                .shadow(
                    color: ArcadePalette.signal.opacity(titlePulse ? 0.42 : 0.18),
                    radius: titlePulse ? 22 : 10
                )
            
            Text("1 PLAYER")
                .font(.custom("Exo 2 SemiBold", size: 13))
                .foregroundColor(ArcadePalette.signalBright)
                .tracking(2.0)
            
            Button {
                AudioManager.shared.playButtonTap()
                revealSetup()
            } label: {
                Text("PRESS START")
                    .font(.custom("Orbitron-Bold", size: 24))
                    .foregroundColor(.white)
                    .frame(minWidth: 220)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(ArcadePalette.signal.opacity(0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(ArcadePalette.signalBright, lineWidth: 1.6)
                    )
                    .opacity(startPromptPulse ? 1.0 : 0.55)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: containerHeight)
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .onTapGesture {
            AudioManager.shared.playButtonTap()
            revealSetup()
        }
    }
    
    private func setupRevealScreen(containerHeight: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SELECT TABLES")
                        .font(.custom("Orbitron-Bold", size: 34))
                        .foregroundColor(ArcadePalette.textPrimary)
                    
                    Text("OR HIT PRACTICE BAY")
                        .font(.custom("Exo 2 SemiBold", size: 13))
                        .foregroundColor(ArcadePalette.signalBright)
                        .tracking(1.6)
                }
                .padding(.horizontal, 4)
                
                ArcadePanel(accent: selectedTables.isEmpty ? ArcadePalette.coolLine : ArcadePalette.signal) {
                    VStack(alignment: .leading, spacing: 18) {
                        MenuSubsectionHeader(
                            title: "Tables",
                            detail: selectedTables.isEmpty ? "Pick Some" : "\(selectedTables.count) Ready"
                        )
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(1...12, id: \.self) { number in
                                Button {
                                    AudioManager.shared.playButtonTap()
                                    if selectedTables.contains(number) {
                                        selectedTables.remove(number)
                                    } else {
                                        selectedTables.insert(number)
                                    }
                                } label: {
                                    MenuTableTile(
                                        number: number,
                                        isSelected: selectedTables.contains(number)
                                    )
                                }
                            }
                        }
                    }
                }
                
                Button {
                    AudioManager.shared.playButtonTap()
                    showPracticeBay()
                } label: {
                    MenuModeButton(
                        title: "Practice Bay",
                        accent: ArcadePalette.coolLine
                    )
                }
                
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        Button {
                            AudioManager.shared.playButtonTap()
                            showAttract()
                        } label: {
                            ArcadeSecondaryActionLabel(title: "Back")
                        }
                        .frame(width: 132)
                        
                        startButton
                    }
                    
                    VStack(spacing: 12) {
                        Button {
                            AudioManager.shared.playButtonTap()
                            showAttract()
                        } label: {
                            ArcadeSecondaryActionLabel(title: "Back")
                        }
                        
                        startButton
                    }
                }
                
                Text(selectedTables.isEmpty ? "PICK TABLES OR HIT PRACTICE" : "HANGAR READY")
                    .font(.custom("Exo 2 SemiBold", size: 12))
                    .foregroundColor(selectedTables.isEmpty ? ArcadePalette.warning : ArcadePalette.success)
                    .tracking(1.8)
                    .opacity(signalBlink ? 1.0 : 0.45)
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 34)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
            .frame(minHeight: containerHeight, alignment: .top)
        }
        .frame(height: containerHeight)
    }
    
    private var startButton: some View {
        Button {
            AudioManager.shared.playButtonTap()
            showingShipSelection = true
        } label: {
            ArcadePrimaryActionLabel(
                title: "Open Hangar",
                enabled: !selectedTables.isEmpty
            )
            .scaleEffect(selectedTables.isEmpty ? 1.0 : (readyPulse ? 1.018 : 0.992))
            .shadow(
                color: selectedTables.isEmpty
                    ? .clear
                    : ArcadePalette.signal.opacity(readyPulse ? 0.34 : 0.16),
                radius: 18,
                y: 10
            )
        }
        .disabled(selectedTables.isEmpty)
    }
    
    private func revealSetup() {
        isSetupRevealed = true
    }
    
    private func showAttract() {
        isSetupRevealed = false
    }
    
    private func showPracticeBay() {
        showingCustomPractice = true
    }
    
    private func restartAnimations() {
        guard !showingShipSelection && !showingCustomPractice else { return }
        resetAnimations()
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                startPromptPulse = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                titlePulse = true
            }
            withAnimation(.easeInOut(duration: 0.48).repeatForever(autoreverses: true)) {
                signalBlink = true
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                readyPulse = true
            }
        }
    }
    
    private func resetAnimations() {
        startPromptPulse = false
        titlePulse = false
        signalBlink = false
        readyPulse = false
    }
}

private struct MenuModeButton: View {
    let title: String
    var subtitle: String? = nil
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 6) {
            Text(title.uppercased())
                .font(.custom("Orbitron-Bold", size: 20))
                .foregroundColor(.white)
            if let subtitle {
                Text(subtitle.uppercased())
                    .font(.custom("Exo 2 SemiBold", size: 11))
                    .foregroundColor(ArcadePalette.textSecondary)
                    .tracking(0.9)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .frame(height: subtitle == nil ? 74 : 82)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accent.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.85), lineWidth: 1.2)
        )
    }
}

private struct MenuSubsectionHeader: View {
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title.uppercased())
                .font(.custom("Exo 2 SemiBold", size: 12))
                .foregroundColor(ArcadePalette.textPrimary)
                .tracking(1.2)
            
            Spacer(minLength: 8)
            
            Text(detail.uppercased())
                .font(.custom("Exo 2 SemiBold", size: 11))
                .foregroundColor(ArcadePalette.textSecondary)
                .tracking(0.8)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct ArcadeSignalLights: View {
    let isActive: Bool
    var accent: Color = ArcadePalette.signalBright
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(accent)
                    .frame(width: index.isMultiple(of: 2) ? 18 : 10, height: 4)
                    .opacity(isActive ? activeOpacity(for: index) : restingOpacity(for: index))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(accent.opacity(0.08))
        )
        .overlay(
            Capsule()
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
    }
    
    private func activeOpacity(for index: Int) -> Double {
        index.isMultiple(of: 2) ? 1.0 : 0.24
    }
    
    private func restingOpacity(for index: Int) -> Double {
        index.isMultiple(of: 2) ? 0.28 : 1.0
    }
}

private struct ArcadeMarqueeLabel: View {
    let text: String
    var accent: Color = ArcadePalette.signalBright
    var isBlinking: Bool
    
    var body: some View {
        Text(text.uppercased())
            .font(.custom("Exo 2 SemiBold", size: 11))
            .foregroundColor(.white)
            .tracking(1.8)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                BeveledPanelShape(cut: 10)
                    .fill(accent.opacity(0.12))
            )
            .overlay(
                BeveledPanelShape(cut: 10)
                    .stroke(accent.opacity(0.32), lineWidth: 1.1)
            )
            .opacity(isBlinking ? 1.0 : 0.5)
    }
}
extension Difficulty {
    var title: String {
        switch self {
        case .easy: return "EASY"
        case .medium: return "MEDIUM"
        case .hard: return "HARD"
        }
    }
}

private struct MenuTableTile: View {
    let number: Int
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(number)×")
                .font(.custom("Orbitron-Bold", size: 22))
                .foregroundColor(.white)
            Text("TABLE")
                .font(.custom("Exo 2 SemiBold", size: 10))
                .foregroundColor(isSelected ? Color.white.opacity(0.76) : ArcadePalette.textMuted)
                .tracking(1.2)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isSelected
                        ? ArcadePalette.signal.opacity(0.20)
                        : ArcadePalette.panelBottom.opacity(0.82)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isSelected ? ArcadePalette.signalBright : ArcadePalette.panelLine.opacity(0.85),
                    lineWidth: isSelected ? 1.5 : 1.0
                )
        )
    }
}

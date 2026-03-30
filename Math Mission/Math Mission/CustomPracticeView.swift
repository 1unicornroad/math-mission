//
//  CustomPracticeView.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import SwiftUI

struct CustomPracticeView: View {
    let arithmeticMode: ArithmeticMode
    @Binding var selectedDifficulty: Difficulty
    let onClose: (() -> Void)?
    
    @State private var selectedProblems: Set<String> = []
    @State private var showingShipSelection = false
    @Environment(\.dismiss) private var dismiss
    
    init(
        arithmeticMode: ArithmeticMode,
        selectedDifficulty: Binding<Difficulty>,
        onClose: (() -> Void)? = nil
    ) {
        self.arithmeticMode = arithmeticMode
        self._selectedDifficulty = selectedDifficulty
        self.onClose = onClose
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ArcadeBackground(variant: .quiet)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CUSTOM PRACTICE")
                                .font(.custom("Orbitron-Bold", size: 34))
                                .foregroundColor(ArcadePalette.textPrimary)
                            
                            Text(practiceStatus)
                                .font(.custom("Exo 2 SemiBold", size: 13))
                                .foregroundColor(selectedProblems.isEmpty ? ArcadePalette.textSecondary : ArcadePalette.signalBright)
                                .tracking(1.2)
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 34)
                        
                        ArcadePanel(accent: selectedProblems.isEmpty ? ArcadePalette.coolLine : ArcadePalette.signal) {
                            VStack(spacing: 18) {
                                ForEach(1...12, id: \.self) { table in
                                    PracticeGridSection(
                                        table: table,
                                        arithmeticMode: arithmeticMode,
                                        columns: gridColumns(for: geometry.size.width),
                                        selectedProblems: $selectedProblems
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 820, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 118)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            customPracticeActionBar
        }
        .fullScreenCover(isPresented: $showingShipSelection) {
            ShipSelectionView(
                selectedTables: [],
                arithmeticMode: arithmeticMode,
                selectedDifficulty: $selectedDifficulty,
                isCustomMode: true,
                selectedProblems: Array(selectedProblems),
                onReturnToMenu: {
                    showingShipSelection = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        closeView()
                    }
                }
            )
        }
        .statusBar(hidden: true)
    }
    
    private var practiceStatus: String {
        if selectedProblems.isEmpty {
            switch arithmeticMode {
            case .multiplication:
                return "PICK TARGETS"
            case .division:
                return "PICK DIVISION FACTS"
            }
        }
        
        return "\(selectedProblems.count) TARGETS"
    }
    
    private var openHangarButton: some View {
        Button {
            AudioManager.shared.playButtonTap()
            showingShipSelection = true
        } label: {
            ArcadePrimaryActionLabel(
                title: "Open Hangar",
                enabled: !selectedProblems.isEmpty
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedProblems.isEmpty)
    }
    
    private var backButton: some View {
        Button {
            AudioManager.shared.playButtonTap()
            closeView()
        } label: {
            ArcadeSecondaryActionLabel(title: "Back")
        }
        .buttonStyle(.plain)
    }
    
    private var customPracticeActionBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.clear, ArcadePalette.spaceBottom.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
            .allowsHitTesting(false)
            
            VStack(spacing: 0) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        backButton
                            .frame(width: 132)
                        openHangarButton
                    }
                    
                    VStack(spacing: 12) {
                        backButton
                        openHangarButton
                    }
                }
                .frame(maxWidth: 820, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
            }
            .background(ArcadePalette.spaceBottom.opacity(0.94))
        }
    }
    
    private func gridColumns(for width: CGFloat) -> [GridItem] {
        let isWide = width >= 900
        let columnCount = isWide ? 6 : 4
        let spacing: CGFloat = isWide ? 10 : 8
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }
    
    private func closeView() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

}

private struct PracticeGridSection: View {
    let table: Int
    let arithmeticMode: ArithmeticMode
    let columns: [GridItem]
    @Binding var selectedProblems: Set<String>
    
    var body: some View {
        VStack(spacing: 10) {
            Text(sectionTitle)
                .font(.custom("Orbitron-Medium", size: 19))
                .foregroundColor(ArcadePalette.signalBright)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...12, id: \.self) { multiplier in
                    let problemKey = arithmeticMode.practiceKey(lhs: multiplier, rhs: table)
                    Button {
                        AudioManager.shared.playButtonTap()
                        if selectedProblems.contains(problemKey) {
                            selectedProblems.remove(problemKey)
                        } else {
                            selectedProblems.insert(problemKey)
                        }
                    } label: {
                        FutureTableCard(
                            heroText: arithmeticMode == .multiplication ? "\(multiplier)×" : "\(multiplier)",
                            title: arithmeticMode == .multiplication ? "Step" : "Solve",
                            footer: "",
                            accent: arithmeticMode == .multiplication ? ArcadePalette.signalBright : ArcadePalette.coolLine,
                            isSelected: selectedProblems.contains(problemKey)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sectionTitle: String {
        switch arithmeticMode {
        case .multiplication:
            return "TABLE \(table)"
        case .division:
            return "DIVISOR \(table)"
        }
    }
    
}

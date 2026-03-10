//
//  CustomPracticeView.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import SwiftUI

struct CustomPracticeView: View {
    @Binding var selectedDifficulty: Difficulty
    let onClose: (() -> Void)?
    
    @State private var selectedProblems: Set<String> = []
    @State private var showingShipSelection = false
    @Environment(\.dismiss) private var dismiss
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    
    init(
        selectedDifficulty: Binding<Difficulty>,
        onClose: (() -> Void)? = nil
    ) {
        self._selectedDifficulty = selectedDifficulty
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            ArcadeBackground(variant: .quiet)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("CUSTOM PRACTICE")
                    .font(.custom("Orbitron-Bold", size: 32))
                    .foregroundColor(ArcadePalette.textPrimary)
                    .padding(.top, 36)
                
                Text(practiceStatus)
                    .font(.custom("Exo 2 SemiBold", size: 15))
                    .foregroundColor(selectedProblems.isEmpty ? ArcadePalette.textSecondary : ArcadePalette.signalBright)
                    .tracking(1.2)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        ForEach(1...12, id: \.self) { table in
                            PracticeGridSection(
                                table: table,
                                columns: columns,
                                selectedProblems: $selectedProblems
                            )
                        }
                    }
                    .padding(.vertical, 20)
                }
                
                HStack(spacing: 20) {
                    Button {
                        AudioManager.shared.playButtonTap()
                        closeView()
                    } label: {
                        Text("BACK")
                            .font(.custom("Exo 2 SemiBold", size: 18))
                            .foregroundColor(.white)
                            .frame(width: 110, height: 52)
                            .background(ArcadePalette.panelTop.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(ArcadePalette.panelLine, lineWidth: 1.2)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        AudioManager.shared.playButtonTap()
                        showingShipSelection = true
                    } label: {
                        Text("OPEN HANGAR")
                            .font(.custom("Orbitron-Bold", size: 22))
                            .foregroundColor(.white)
                            .frame(width: 220, height: 52)
                            .background(
                                selectedProblems.isEmpty
                                    ? ArcadePalette.panelTop
                                    : ArcadePalette.signal
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedProblems.isEmpty)
                    .opacity(selectedProblems.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .fullScreenCover(isPresented: $showingShipSelection) {
            ShipSelectionView(
                selectedTables: [],
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
            return "PICK TARGETS"
        }
        
        return "\(selectedProblems.count) TARGETS"
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
    let columns: [GridItem]
    @Binding var selectedProblems: Set<String>
    
    var body: some View {
        VStack(spacing: 10) {
            Text("\(table)× TABLE")
                .font(.custom("Orbitron-Medium", size: 19))
                .foregroundColor(ArcadePalette.signalBright)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(1...12, id: \.self) { multiplier in
                    let problemKey = "\(multiplier)×\(table)"
                    Button {
                        AudioManager.shared.playButtonTap()
                        if selectedProblems.contains(problemKey) {
                            selectedProblems.remove(problemKey)
                        } else {
                            selectedProblems.insert(problemKey)
                        }
                    } label: {
                        Text(problemKey)
                            .font(.custom("Exo 2 SemiBold", size: 14))
                            .foregroundColor(.white)
                            .frame(width: 65, height: 65)
                            .background(
                                selectedProblems.contains(problemKey)
                                    ? ArcadePalette.signal.opacity(0.85)
                                    : ArcadePalette.panelBottom.opacity(0.92)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(
                                        selectedProblems.contains(problemKey)
                                            ? ArcadePalette.signalBright
                                            : ArcadePalette.panelLine,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

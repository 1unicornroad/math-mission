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
    @State private var isPulsing = false
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 4)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("MATH MISSION")
                    .font(.custom("Orbitron-Bold", size: 38))
                    .foregroundColor(.cyan)
                    .padding(.top, 40)
                
                // Subtitle
                Text("Select Multiplication Tables")
                    .font(.custom("Exo 2 Medium", size: 20))
                    .foregroundColor(.white)
                
                // Times tables grid
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(1...12, id: \.self) { number in
                        Button(action: {
                            if selectedTables.contains(number) {
                                selectedTables.remove(number)
                            } else {
                                selectedTables.insert(number)
                            }
                        }) {
                            Text("\(number)×")
                                .font(.custom("Exo 2 Bold", size: 26))
                                .foregroundColor(.white)
                                .frame(width: 70, height: 70)
                                .background(selectedTables.contains(number) ?
                                    Color(red: 0.2, green: 0.4, blue: 0.8) :
                                    Color(white: 0.2))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedTables.contains(number) ? Color.cyan : Color.gray, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Custom practice button
                Button(action: {
                    showingCustomPractice = true
                }) {
                    Text("⚙️ CUSTOM PRACTICE")
                        .font(.custom("Orbitron-Medium", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(Color(red: 0.5, green: 0.3, blue: 0.7))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                // Difficulty selection
                VStack(spacing: 10) {
                    Text("Select Difficulty")
                        .font(.custom("Exo 2 Medium", size: 20))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 15) {
                        ForEach([Difficulty.easy, .medium, .hard], id: \.self) { difficulty in
                            Button(action: {
                                selectedDifficulty = difficulty
                            }) {
                                Text(difficulty.title)
                                    .font(.custom("Exo 2 SemiBold", size: 19))
                                    .foregroundColor(.white)
                                    .frame(width: 110, height: 50)
                                    .background(selectedDifficulty == difficulty ?
                                        Color(red: 0.3, green: 0.5, blue: 0.8) :
                                        Color(white: 0.2))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedDifficulty == difficulty ? Color.cyan : Color.gray, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Launch button with pulsing animation
                Button(action: {
                    showingShipSelection = true
                }) {
                    Text("🚀 LAUNCH")
                        .font(.custom("Orbitron-Bold", size: 28))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(
                            selectedTables.isEmpty ?
                                Color.gray.opacity(0.5) :
                                Color(red: 0.8, green: 0.2, blue: 0.2)
                        )
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(selectedTables.isEmpty ? Color.clear : Color.orange, lineWidth: 3)
                        )
                        .shadow(color: selectedTables.isEmpty ? .clear : (isPulsing ? .orange.opacity(1.0) : .orange.opacity(0.3)), radius: isPulsing ? 15 : 5)
                        .scaleEffect(selectedTables.isEmpty ? 1.0 : (isPulsing ? 1.05 : 1.0))
                }
                .disabled(selectedTables.isEmpty)
                .onChange(of: selectedTables) { _, newValue in
                    if !newValue.isEmpty {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            isPulsing = true
                        }
                    } else {
                        isPulsing = false
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showingShipSelection) {
            ShipSelectionView(
                selectedTables: Array(selectedTables),
                selectedDifficulty: selectedDifficulty,
                isCustomMode: false
            )
        }
        .fullScreenCover(isPresented: $showingCustomPractice) {
            CustomPracticeView(selectedDifficulty: selectedDifficulty)
        }
        .statusBar(hidden: true)
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

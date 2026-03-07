//
//  CustomPracticeView.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import SwiftUI

struct CustomPracticeView: View {
    let selectedDifficulty: Difficulty
    
    @State private var selectedProblems: Set<String> = []
    @State private var showingShipSelection = false
    @Environment(\.dismiss) private var dismiss
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("CUSTOM PRACTICE")
                    .font(.custom("Orbitron-Bold", size: 32))
                    .foregroundColor(.cyan)
                    .padding(.top, 40)
                
                // Subtitle
                Text("Select Specific Problems")
                    .font(.custom("Exo 2", size: 17))
                    .foregroundColor(.white)
                
                // Scrollable problem grid
                ScrollView {
                    VStack(spacing: 25) {
                        ForEach(1...12, id: \.self) { table in
                            VStack(spacing: 10) {
                                // Section header
                                Text("\(table)× Table")
                                    .font(.custom("Orbitron-Medium", size: 19))
                                    .foregroundColor(.cyan)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 20)
                                
                                // Problem buttons
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(1...12, id: \.self) { multiplier in
                                        let problemKey = "\(multiplier)×\(table)"
                                        Button(action: {
                                            if selectedProblems.contains(problemKey) {
                                                selectedProblems.remove(problemKey)
                                            } else {
                                                selectedProblems.insert(problemKey)
                                            }
                                        }) {
                                            Text(problemKey)
                                                .font(.custom("Exo 2 SemiBold", size: 14))
                                                .foregroundColor(.white)
                                                .frame(width: 65, height: 65)
                                                .background(selectedProblems.contains(problemKey) ?
                                                    Color(red: 0.2, green: 0.4, blue: 0.8) :
                                                    Color(white: 0.2))
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(selectedProblems.contains(problemKey) ? Color.cyan : Color.gray, lineWidth: 2)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                
                // Buttons at bottom
                HStack(spacing: 20) {
                    // Back button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("← Back")
                            .font(.custom("Exo 2 SemiBold", size: 18))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 50)
                            .background(Color(white: 0.3))
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    // Launch button
                    Button(action: {
                        showingShipSelection = true
                    }) {
                        Text("🚀 LAUNCH")
                            .font(.custom("Orbitron-Bold", size: 24))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color(red: 0.8, green: 0.3, blue: 0.2))
                            .cornerRadius(10)
                    }
                    .disabled(selectedProblems.isEmpty)
                    .opacity(selectedProblems.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .fullScreenCover(isPresented: $showingShipSelection) {
            ShipSelectionView(
                selectedTables: [],
                selectedDifficulty: selectedDifficulty,
                isCustomMode: true,
                selectedProblems: Array(selectedProblems)
            )
        }
        .statusBar(hidden: true)
    }
}

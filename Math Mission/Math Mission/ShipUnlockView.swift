//
//  ShipUnlockView.swift
//  Math Mission
//
//  Created by John Ostler on 3/7/26.
//

import SwiftUI
import SceneKit

struct ShipUnlockView: View {
    let unlockedShips: [SpaceShip]
    let onContinue: () -> Void
    
    @State private var currentIndex = 0
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Title with animation
                Text("🎉 SHIP UNLOCKED! 🎉")
                    .font(.custom("Orbitron-Bold", size: 32))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow, radius: isPulsing ? 20 : 10)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .padding(.top, 60)
                
                // Ship display
                if !unlockedShips.isEmpty {
                    VStack(spacing: 20) {
                        // 3D Ship preview
                        SceneKitShipView(modelName: unlockedShips[currentIndex].modelName, isUnlocked: true)
                            .frame(height: 280)
                            .cornerRadius(20)
                        
                        // Ship name
                        Text(unlockedShips[currentIndex].name)
                            .font(.custom("Orbitron-Bold", size: 28))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan, radius: 10)
                        
                        // Unlock requirement met
                        Text("✓ \(unlockedShips[currentIndex].unlockRequirement)")
                            .font(.custom("Exo 2 Medium", size: 16))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color(white: 0.15), Color(white: 0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: .yellow.opacity(0.6), radius: 20)
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Pagination dots if multiple ships
                if unlockedShips.count > 1 {
                    HStack(spacing: 12) {
                        ForEach(0..<unlockedShips.count, id: \.self) { index in
                            Circle()
                                .fill(currentIndex == index ? Color.cyan : Color.gray.opacity(0.5))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.bottom, 10)
                }
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if unlockedShips.count > 1 && currentIndex > 0 {
                        Button(action: {
                            currentIndex -= 1
                        }) {
                            Text("← Previous")
                                .font(.custom("Exo 2 SemiBold", size: 16))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 50)
                                .background(Color(white: 0.3))
                                .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                    
                    if unlockedShips.count > 1 && currentIndex < unlockedShips.count - 1 {
                        Button(action: {
                            currentIndex += 1
                        }) {
                            Text("Next →")
                                .font(.custom("Exo 2 SemiBold", size: 16))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 50)
                                .background(Color(white: 0.3))
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: onContinue) {
                            Text("CONTINUE")
                                .font(.custom("Orbitron-Bold", size: 20))
                                .foregroundColor(.white)
                                .frame(width: 180, height: 50)
                                .background(Color(red: 0.8, green: 0.3, blue: 0.2))
                                .cornerRadius(10)
                                .shadow(color: .orange, radius: 10)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .statusBar(hidden: true)
    }
}

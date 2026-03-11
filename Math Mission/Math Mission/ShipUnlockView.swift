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
            ArcadeBackground()
            
            VStack(spacing: 20) {
                Spacer(minLength: 28)
                
                VStack(spacing: 8) {
                    Text("NEW SHIP")
                        .font(.custom("Orbitron-Bold", size: 32))
                        .foregroundColor(.white)
                        .shadow(color: ArcadePalette.signal.opacity(isPulsing ? 0.65 : 0.35), radius: isPulsing ? 20 : 10)
                        .scaleEffect(isPulsing ? 1.06 : 1.0)
                    
                    Text("SHIP UNLOCKED")
                        .font(.custom("Exo 2 SemiBold", size: 13))
                        .foregroundColor(ArcadePalette.signalBright)
                        .tracking(1.6)
                    
                    Text("THIS CRAFT JUST JOINED YOUR HANGAR")
                        .font(.custom("Exo 2 SemiBold", size: 11))
                        .foregroundColor(ArcadePalette.textSecondary)
                        .tracking(1.1)
                    
                    if unlockedShips.count > 1 {
                        Text("\(currentIndex + 1) / \(unlockedShips.count)")
                            .font(.custom("Exo 2 SemiBold", size: 12))
                            .foregroundColor(ArcadePalette.textSecondary)
                            .tracking(1.2)
                    }
                }
                
                if !unlockedShips.isEmpty {
                    ArcadePanel(accent: ArcadePalette.signal) {
                        VStack(spacing: 16) {
                            ZStack {
                                BeveledPanelShape(cut: 18)
                                    .fill(
                                        LinearGradient(
                                            colors: [ArcadePalette.panelBottom.opacity(0.96), Color.black.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                BeveledPanelShape(cut: 18)
                                    .stroke(ArcadePalette.panelLine, lineWidth: 1.2)
                                
                                ArcadeAssetPreviewView(
                                    modelName: unlockedShips[currentIndex].modelName,
                                    cameraZ: 3.4,
                                    scale: 1.05,
                                    yRotation: Float.pi / 4,
                                    rotationDuration: 6
                                )
                                .padding(10)
                            }
                            .frame(height: 280)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text(unlockedShips[currentIndex].name.uppercased())
                                    .font(.custom("Orbitron-Bold", size: 27))
                                    .foregroundColor(.white)
                                
                                Text(ShipProgression.requirementText(for: unlockedShips[currentIndex]))
                                    .font(.custom("Exo 2 Medium", size: 15))
                                    .foregroundColor(ArcadePalette.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                
                if unlockedShips.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<unlockedShips.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentIndex ? ArcadePalette.signalBright : Color.white.opacity(0.14))
                                .frame(width: index == currentIndex ? 28 : 10, height: 8)
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                ArcadePanel(accent: ArcadePalette.signal) {
                    HStack(spacing: 12) {
                        if unlockedShips.count > 1 {
                            Button {
                                currentIndex = max(0, currentIndex - 1)
                            } label: {
                                ArcadeSecondaryActionLabel(title: "Previous")
                            }
                            .buttonStyle(.plain)
                            .frame(width: 126)
                            .opacity(currentIndex > 0 ? 1.0 : 0.35)
                            .disabled(currentIndex == 0)
                        }
                        
                        Button {
                            if unlockedShips.count > 1 && currentIndex < unlockedShips.count - 1 {
                                currentIndex += 1
                            } else {
                                onContinue()
                            }
                        } label: {
                            ArcadePrimaryActionLabel(
                                title: unlockedShips.count > 1 && currentIndex < unlockedShips.count - 1 ? "Next" : "Continue"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .onAppear(perform: restartPulse)
        .onDisappear {
            isPulsing = false
        }
        .statusBar(hidden: true)
    }
    
    private func restartPulse() {
        currentIndex = min(currentIndex, max(unlockedShips.count - 1, 0))
        isPulsing = false
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

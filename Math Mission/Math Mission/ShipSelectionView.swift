//
//  ShipSelectionView.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import SwiftUI
import SceneKit

struct ShipSelectionView: View {
    let selectedTables: [Int]
    let selectedDifficulty: Difficulty
    let isCustomMode: Bool
    var selectedProblems: [String] = []
    
    @State private var selectedShip: SpaceShip
    @State private var showingGame = false
    @Environment(\.dismiss) private var dismiss
    
    let ships: [SpaceShip] = [
        SpaceShip(name: "Nova Striker", modelName: "craft_speederA.dae", unlockRequirement: "Default", unlockLevel: 0),
        SpaceShip(name: "Photon Blade", modelName: "craft_racer.dae", unlockRequirement: "Complete 2× table", unlockLevel: 1),
        SpaceShip(name: "Starfire Interceptor", modelName: "craft_speederB.dae", unlockRequirement: "Complete 3× or 4× table", unlockLevel: 2),
        SpaceShip(name: "Nebula Runner", modelName: "craft_speederC.dae", unlockRequirement: "Complete 5× or 6× table", unlockLevel: 3),
        SpaceShip(name: "Asteroid Crusher", modelName: "craft_miner.dae", unlockRequirement: "Complete 7× or 8× table", unlockLevel: 4),
        SpaceShip(name: "Quantum Falcon", modelName: "craft_speederD.dae", unlockRequirement: "Complete 9× or 10× table", unlockLevel: 5),
        SpaceShip(name: "Titan Hauler", modelName: "craft_cargoA.dae", unlockRequirement: "Complete 11× or 12× table", unlockLevel: 6),
        SpaceShip(name: "Voidbreaker Prime", modelName: "craft_cargoB.dae", unlockRequirement: "Beat Medium or Hard mode", unlockLevel: 7)
    ]
    
    init(selectedTables: [Int], selectedDifficulty: Difficulty, isCustomMode: Bool, selectedProblems: [String] = []) {
        self.selectedTables = selectedTables
        self.selectedDifficulty = selectedDifficulty
        self.isCustomMode = isCustomMode
        self.selectedProblems = selectedProblems
        self._selectedShip = State(initialValue: ships[0])
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("SELECT SHIP")
                    .font(.custom("Orbitron-Bold", size: 28))
                    .foregroundColor(.cyan)
                    .padding(.top, 40)
                
                // Ship carousel
                TabView(selection: $selectedShip) {
                    ForEach(ships, id: \.modelName) { ship in
                        ShipCardView(ship: ship, isUnlocked: checkIfUnlocked(ship), isSelected: selectedShip.modelName == ship.modelName)
                            .tag(ship)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 380)
                .padding(.bottom, 30)
                
                Spacer()
                
                // Buttons at bottom - matching CustomPracticeView layout
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
                        if checkIfUnlocked(selectedShip) {
                            showingGame = true
                        }
                    }) {
                        Text("🚀 LAUNCH")
                            .font(.custom("Orbitron-Bold", size: 24))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(
                                checkIfUnlocked(selectedShip) ?
                                    Color(red: 0.8, green: 0.3, blue: 0.2) :
                                    Color.gray.opacity(0.5)
                            )
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(checkIfUnlocked(selectedShip) ? Color.orange : Color.clear, lineWidth: 2)
                            )
                            .shadow(color: checkIfUnlocked(selectedShip) ? .orange.opacity(0.6) : .clear, radius: 8)
                    }
                    .disabled(!checkIfUnlocked(selectedShip))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .fullScreenCover(isPresented: $showingGame) {
            GameFlowView(
                selectedShipModel: selectedShip.modelName,
                selectedTables: selectedTables,
                customProblems: selectedProblems,
                difficulty: selectedDifficulty
            )
        }
        .statusBar(hidden: true)
    }
    
    func checkIfUnlocked(_ ship: SpaceShip) -> Bool {
        if ship.unlockLevel == 0 { return true }
        
        let defaults = UserDefaults.standard
        let completedTables = defaults.array(forKey: "completedTables") as? [Int] ?? []
        let completedDifficulties = defaults.array(forKey: "completedDifficulties") as? [String] ?? []
        
        switch ship.unlockLevel {
        case 1: return completedTables.contains(2)  // Just 2× table now
        case 2: return completedTables.contains(3) || completedTables.contains(4)
        case 3: return completedTables.contains(5) || completedTables.contains(6)
        case 4: return completedTables.contains(7) || completedTables.contains(8)
        case 5: return completedTables.contains(9) || completedTables.contains(10)
        case 6: return completedTables.contains(11) || completedTables.contains(12)
        case 7: return completedDifficulties.contains("medium") || completedDifficulties.contains("hard")
        default: return false
        }
    }
}

struct ShipCardView: View {
    let ship: SpaceShip
    let isUnlocked: Bool
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 3D Ship preview
            SceneKitShipView(modelName: ship.modelName, isUnlocked: isUnlocked)
                .frame(height: 200)
                .cornerRadius(15)
            
            // Ship name
            Text(ship.name)
                .font(.custom("Orbitron-Bold", size: 18))
                .foregroundColor(isUnlocked ? .cyan : Color(white: 0.4))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .shadow(color: isUnlocked ? .cyan : .clear, radius: 5)
            
            // Unlock status
            Text(isUnlocked ? "✓ Unlocked" : "🔒 \(ship.unlockRequirement)")
                .font(.custom("Exo 2", size: 12))
                .foregroundColor(isUnlocked ? .green : .orange)
                .multilineTextAlignment(.center)
                .frame(height: 28)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(white: 0.15), Color(white: 0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: isSelected ? [.green, .cyan] : (isUnlocked ? [.cyan, .blue] : [Color(white: 0.3), Color(white: 0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 5 : 3
                )
        )
        .shadow(color: isSelected ? .green.opacity(0.6) : (isUnlocked ? .cyan.opacity(0.4) : .clear), radius: 12)
        .padding(.horizontal, 20)
    }
}

struct SceneKitShipView: UIViewRepresentable {
    let modelName: String
    let isUnlocked: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        if let shipScene = SCNScene(named: "art.scnassets/\(modelName)") {
            let shipNode = SCNNode()
            for child in shipScene.rootNode.childNodes {
                shipNode.addChildNode(child)
            }
            shipNode.scale = SCNVector3(x: 1.0, y: 1.0, z: 1.0)
            shipNode.eulerAngles = SCNVector3(x: 0, y: Float.pi / 4, z: 0)
            scene.rootNode.addChildNode(shipNode)
            
            if !isUnlocked {
                shipNode.enumerateChildNodes { node, _ in
                    node.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.15, alpha: 1.0)
                    node.geometry?.firstMaterial?.emission.contents = UIColor.black
                    node.geometry?.firstMaterial?.specular.contents = UIColor.black
                    node.geometry?.firstMaterial?.lightingModel = .constant
                }
            }
            
            let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1.5, z: 0, duration: 3.0))
            shipNode.runAction(rotateAction)
        }
        
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        scene.rootNode.addChildNode(cameraNode)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}

// UIViewControllerRepresentable to wrap GameViewController
struct GameViewControllerRepresentable: UIViewControllerRepresentable {
    let selectedShipModel: String
    let selectedTables: [Int]
    let customProblems: [String]
    let difficulty: Difficulty
    
    func makeUIViewController(context: Context) -> GameViewController {
        let gameVC = GameViewController()
        gameVC.selectedShipModel = selectedShipModel
        gameVC.selectedTables = selectedTables
        gameVC.customProblems = customProblems
        gameVC.difficulty = difficulty
        return gameVC
    }
    
    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}

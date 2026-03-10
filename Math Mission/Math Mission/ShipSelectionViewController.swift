//
//  ShipSelectionViewController.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import UIKit
import SceneKit

struct SpaceShip: Hashable {
    let name: String
    let modelName: String
    let unlockRequirement: String
    let unlockLevel: Int  // Based on progression
}

class ShipSelectionViewController: UIViewController {
    
    var selectedTables: [Int] = []
    var selectedProblems: [String] = []
    var selectedDifficulty: Difficulty = .easy
    var isCustomMode: Bool = false
    var selectedShip: String = "craft_speederA.dae"
    
    let ships: [SpaceShip] = [
        SpaceShip(name: "Nova Striker", modelName: "craft_speederA.dae", unlockRequirement: "Default", unlockLevel: 0),
        SpaceShip(name: "Photon Blade", modelName: "craft_racer.dae", unlockRequirement: "Complete 2× table", unlockLevel: 1),
        SpaceShip(name: "Starfire Interceptor", modelName: "craft_speederB.dae", unlockRequirement: "Complete 3× and 4× tables", unlockLevel: 2),
        SpaceShip(name: "Nebula Runner", modelName: "craft_speederC.dae", unlockRequirement: "Complete 5× and 6× tables", unlockLevel: 3),
        SpaceShip(name: "Asteroid Crusher", modelName: "craft_miner.dae", unlockRequirement: "Complete 7× and 8× tables", unlockLevel: 4),
        SpaceShip(name: "Quantum Falcon", modelName: "craft_speederD.dae", unlockRequirement: "Complete 8× and 9× tables", unlockLevel: 5),
        SpaceShip(name: "Titan Hauler", modelName: "craft_cargoA.dae", unlockRequirement: "Complete 11× and 12× tables", unlockLevel: 6),
        SpaceShip(name: "Voidbreaker Prime", modelName: "craft_cargoB.dae", unlockRequirement: "Beat Medium and Hard modes", unlockLevel: 7)
    ]
    
    var shipViews: [(view: UIView, ship: SpaceShip)] = []
    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setupUI()
    }
    
    func setupUI() {
        // Title
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 60, width: view.bounds.width, height: 50))
        titleLabel.text = "SELECT SHIP"
        titleLabel.font = UIFont.orbitronBold(size: 28)
        titleLabel.textColor = .cyan
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Horizontal carousel for ships
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 150, width: view.bounds.width, height: 450))
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        // Use full screen width for consistent paging
        let shipCardWidth: CGFloat = view.bounds.width - 40
        let shipCardHeight: CGFloat = 400
        let cardSpacing: CGFloat = 20
        
        for (index, ship) in ships.enumerated() {
            // Each card takes full screen width for proper paging
            let xPos = CGFloat(index) * view.bounds.width + cardSpacing
            let isUnlocked = checkIfUnlocked(ship)
            
            // Ship card container
            let cardView = UIView(frame: CGRect(x: xPos, y: 20, width: shipCardWidth, height: shipCardHeight))
            cardView.backgroundColor = UIColor(white: 0.1, alpha: 0.95)
            cardView.layer.cornerRadius = 20
            cardView.layer.borderWidth = 4
            cardView.layer.borderColor = isUnlocked ? UIColor.cyan.cgColor : UIColor(white: 0.3, alpha: 1.0).cgColor
            
            if isUnlocked {
                cardView.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(shipCardTapped(_:)))
                cardView.addGestureRecognizer(tapGesture)
                cardView.tag = index
            }
            
            scrollView.addSubview(cardView)
            shipViews.append((cardView, ship))
            
            // 3D ship preview - larger for carousel
            let sceneView = SCNView(frame: CGRect(x: 20, y: 20, width: shipCardWidth - 40, height: 250))
            sceneView.backgroundColor = .clear
            sceneView.autoenablesDefaultLighting = true
            sceneView.allowsCameraControl = false
            sceneView.isUserInteractionEnabled = false
            
            let scene = SCNScene()
            sceneView.scene = scene
            
            if let shipScene = SCNScene(named: "art.scnassets/\(ship.modelName)") {
                let shipNode = SCNNode()
                for child in shipScene.rootNode.childNodes {
                    shipNode.addChildNode(child)
                }
                shipNode.scale = SCNVector3(x: 1.0, y: 1.0, z: 1.0)
                shipNode.eulerAngles = SCNVector3(x: 0, y: Float.pi / 4, z: 0)
                scene.rootNode.addChildNode(shipNode)
                
                // Apply strong darkening to locked ships
                if !isUnlocked {
                    shipNode.enumerateChildNodes { node, _ in
                        // Make it much darker - almost black
                        node.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.15, alpha: 1.0)
                        node.geometry?.firstMaterial?.emission.contents = UIColor.black
                        node.geometry?.firstMaterial?.specular.contents = UIColor.black
                        node.geometry?.firstMaterial?.lightingModel = .constant
                    }
                }
                
                // Rotate animation
                let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1.5, z: 0, duration: 3.0))
                shipNode.runAction(rotateAction)
            }
            
            let camera = SCNCamera()
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
            scene.rootNode.addChildNode(cameraNode)
            
            cardView.addSubview(sceneView)
            
            // Ship name - centered below 3D model
            let nameLabel = UILabel(frame: CGRect(x: 20, y: 280, width: shipCardWidth - 40, height: 40))
            nameLabel.text = ship.name
            nameLabel.font = UIFont.orbitronBold(size: 24)
            nameLabel.textColor = isUnlocked ? .cyan : UIColor(white: 0.4, alpha: 1.0)
            nameLabel.textAlignment = .center
            nameLabel.adjustsFontSizeToFitWidth = true
            nameLabel.minimumScaleFactor = 0.7
            cardView.addSubview(nameLabel)
            
            // Unlock requirement - below name
            let reqLabel = UILabel(frame: CGRect(x: 20, y: 325, width: shipCardWidth - 40, height: 50))
            reqLabel.text = isUnlocked ? "✓ Unlocked" : "🔒 \(ship.unlockRequirement)"
            reqLabel.font = UIFont.exo2Regular(size: 16)
            reqLabel.textColor = isUnlocked ? .green : .orange
            reqLabel.numberOfLines = 2
            reqLabel.textAlignment = .center
            cardView.addSubview(reqLabel)
            
            // Selected indicator
            if selectedShip == ship.modelName {
                cardView.layer.borderWidth = 6
                cardView.layer.borderColor = UIColor.green.cgColor
            }
        }
        
        // Set horizontal scroll content size - each page is full width
        scrollView.contentSize = CGSize(width: CGFloat(ships.count) * view.bounds.width, height: shipCardHeight + 40)
        
        // Page control dots
        pageControl = UIPageControl(frame: CGRect(x: 0, y: 600, width: view.bounds.width, height: 40))
        pageControl.numberOfPages = ships.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor(white: 0.4, alpha: 1.0)
        pageControl.currentPageIndicatorTintColor = .cyan
        pageControl.addTarget(self, action: #selector(pageControlChanged(_:)), for: .valueChanged)
        view.addSubview(pageControl)
        
        // Launch button - positioned below page control
        let launchButton = UIButton(frame: CGRect(x: view.bounds.width/2 - 120, y: 650, width: 240, height: 70))
        launchButton.setTitle("🚀 LAUNCH", for: .normal)
        launchButton.titleLabel?.font = UIFont.orbitronBold(size: 28)
        launchButton.backgroundColor = UIColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)
        launchButton.setTitleColor(.white, for: .normal)
        launchButton.layer.cornerRadius = 18
        launchButton.layer.borderWidth = 3
        launchButton.layer.borderColor = UIColor.orange.cgColor
        launchButton.addTarget(self, action: #selector(startMissionTapped), for: .touchUpInside)
        view.addSubview(launchButton)
        
        // Back button - below launch button
        let backButton = UIButton(frame: CGRect(x: view.bounds.width/2 - 60, y: 730, width: 120, height: 44))
        backButton.setTitle("← BACK", for: .normal)
        backButton.titleLabel?.font = UIFont.exo2SemiBold(size: 18)
        backButton.setTitleColor(.cyan, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
    }
    
    func checkIfUnlocked(_ ship: SpaceShip) -> Bool {
        // Always unlock default ship
        if ship.unlockLevel == 0 {
            return true
        }
        
        // Check UserDefaults for unlocked ships based on completed tables
        let defaults = UserDefaults.standard
        let completedTables = defaults.array(forKey: "completedTables") as? [Int] ?? []
        let completedDifficulties = defaults.array(forKey: "completedDifficulties") as? [String] ?? []
        
        // Unlock logic based on level
        switch ship.unlockLevel {
        case 1:
            return completedTables.contains(2)
        case 2:
            return completedTables.contains(3) && completedTables.contains(4)
        case 3:
            return completedTables.contains(5) && completedTables.contains(6)
        case 4:
            return completedTables.contains(7) && completedTables.contains(8)
        case 5:
            return completedTables.contains(8) && completedTables.contains(9)
        case 6:
            return completedTables.contains(11) && completedTables.contains(12)
        case 7:
            return completedDifficulties.contains("medium") && completedDifficulties.contains("hard")
        default:
            return false
        }
    }
    
    @objc func shipCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag else { return }
        let ship = ships[index]
        
        if checkIfUnlocked(ship) {
            AudioManager.shared.playButtonTap()
            selectedShip = ship.modelName
            
            // Update visual selection
            for (cardView, _) in shipViews {
                let shipForCard = ships[cardView.tag]
                cardView.layer.borderWidth = 4
                cardView.layer.borderColor = checkIfUnlocked(shipForCard) ? UIColor.cyan.cgColor : UIColor(white: 0.3, alpha: 1.0).cgColor
            }
            
            gesture.view?.layer.borderWidth = 6
            gesture.view?.layer.borderColor = UIColor.green.cgColor
        }
    }
    
    @objc func pageControlChanged(_ sender: UIPageControl) {
        AudioManager.shared.playButtonTap()
        let page = sender.currentPage
        let offsetX = CGFloat(page) * view.bounds.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
    
    @objc func backButtonTapped() {
        AudioManager.shared.playButtonTap()
        dismiss(animated: true)
    }
    
    @objc func startMissionTapped() {
        AudioManager.shared.playButtonTap()
        let gameVC = GameViewController()
        gameVC.selectedShipModel = selectedShip
        
        if isCustomMode {
            gameVC.customProblems = selectedProblems
        } else {
            gameVC.selectedTables = selectedTables
        }
        
        gameVC.difficulty = selectedDifficulty
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - UIScrollViewDelegate
extension ShipSelectionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / view.bounds.width))
        pageControl.currentPage = page
    }
}

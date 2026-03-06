//
//  GameViewController.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    var sceneView: SCNView!
    var gameScene: SCNScene!
    var cameraNode: SCNNode!
    var spaceship: SCNNode!
    var stars: [SCNNode] = []
    
    // Gameplay state
    var lives = 3
    var attemptsLeft = 2
    var currentAnswer = 0
    var currentStreak = 0
    var topScore = 0
    var questionNumber = 0
    var starSpeed: Float = 0.3
    var lastQuestion: String = ""
    var currentPosition: Float = 0
    var currentQuestionText: String = ""
    
    // Question statistics
    var totalMeteorsDestroyed = 0
    var firstAttemptCorrect = 0
    var secondAttemptCorrect = 0
    var missedQuestions: [String] = []
    
    // Game settings from menu
    var selectedTables: [Int] = [2, 3, 4, 5]  // Default
    var difficulty: Difficulty = .easy
    var maxAttempts: Int = 2
    var meteor: SCNNode?
    var questionLabel: UILabel!
    var streakLabel: UILabel!
    var livesContainer: UIView!
    var liveCraftNodes: [SCNView] = []
    
    // Control panel buttons
    var answerButtons: [UIButton] = []
    var controlPanel: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set max attempts based on difficulty
        switch difficulty {
        case .easy:
            maxAttempts = 2
        case .medium, .hard:
            maxAttempts = 1
        }
        attemptsLeft = maxAttempts
        
        setupScene()
        setupCamera()
        setupSpaceship()
        setupStars()
        setupLighting()
        setupUI()
        
        // Start animation
        startAnimation()
        
        // Start first question
        spawnMeteorWithQuestion()
    }
    
    func setupScene() {
        // Create SCNView programmatically if needed
        if let existingView = self.view as? SCNView {
            sceneView = existingView
        } else {
            let newSceneView = SCNView(frame: view.bounds)
            newSceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(newSceneView)
            sceneView = newSceneView
        }
        
        sceneView.showsStatistics = true
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.backgroundColor = .black
        
        gameScene = SCNScene()
        sceneView.scene = gameScene
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 2, z: 10)
        cameraNode.eulerAngles = SCNVector3(x: -0.1, y: 0, z: 0)
        gameScene.rootNode.addChildNode(cameraNode)
    }
    
    func setupSpaceship() {
        guard let spaceshipScene = SCNScene(named: "art.scnassets/craft_speederA.dae") else {
            return
        }
        
        spaceship = SCNNode()
        for child in spaceshipScene.rootNode.childNodes {
            spaceship.addChildNode(child)
        }
        
        // Position spaceship higher to make room for control panel
        spaceship.position = SCNVector3(x: 0, y: -1, z: 0)
        spaceship.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        spaceship.eulerAngles = SCNVector3(x: 0, y: Float.pi, z: 0)
        
        gameScene.rootNode.addChildNode(spaceship)
        
        // Add engine flame particles
        addEngineFlames()
    }
    
    func addEngineFlames() {
        // Left engine flame (back of ship in world coords after rotation)
        let leftFlame = createFlameParticles()
        let leftEngineNode = SCNNode()
        leftEngineNode.position = SCNVector3(x: -0.25, y: 0, z: 0.8)  // Further out from ship
        leftEngineNode.addParticleSystem(leftFlame)
        spaceship.addChildNode(leftEngineNode)
        
        // Right engine flame
        let rightFlame = createFlameParticles()
        let rightEngineNode = SCNNode()
        rightEngineNode.position = SCNVector3(x: 0.25, y: 0, z: 0.8)  // Further out from ship
        rightEngineNode.addParticleSystem(rightFlame)
        spaceship.addChildNode(rightEngineNode)
    }
    
    func createFlameParticles() -> SCNParticleSystem {
        let particles = SCNParticleSystem()
        particles.birthRate = 80
        particles.particleLifeSpan = 0.3
        particles.particleSize = 0.04  // Smaller
        particles.emitterShape = SCNSphere(radius: 0.02)
        particles.particleColor = UIColor.cyan
        particles.particleColorVariation = SCNVector4(x: 0, y: 0.3, z: 0.5, w: 0)
        particles.blendMode = .additive
        particles.particleVelocity = 4.0
        particles.particleVelocityVariation = 0.5
        particles.emittingDirection = SCNVector3(x: 0, y: 0, z: -1)  // Backward away from ship
        particles.spreadingAngle = 10
        
        return particles
    }
    
    func setupStars() {
        // Create 100 stars
        for _ in 0..<100 {
            let star = SCNNode(geometry: SCNSphere(radius: 0.05))
            star.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            star.geometry?.firstMaterial?.emission.contents = UIColor.white
            
            // Random position
            let x = Float.random(in: -20...20)
            let y = Float.random(in: -20...20)
            let z = Float.random(in: -50...0)
            
            star.position = SCNVector3(x: x, y: y, z: z)
            gameScene.rootNode.addChildNode(star)
            stars.append(star)
        }
    }
    
    func setupLighting() {
        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.3, alpha: 1.0)
        gameScene.rootNode.addChildNode(ambientLight)
        
        // Directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
        directionalLight.position = SCNVector3(x: 5, y: 10, z: 10)
        directionalLight.look(at: SCNVector3(x: 0, y: 0, z: 0))
        gameScene.rootNode.addChildNode(directionalLight)
    }
    
    func setupUI() {
        // Control panel at bottom
        let panelHeight: CGFloat = 150
        controlPanel = UIView(frame: CGRect(x: 0, y: view.bounds.height - panelHeight, width: view.bounds.width, height: panelHeight))
        controlPanel.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
        view.addSubview(controlPanel)
        
        // Question label - positioned in middle of screen for visibility
        questionLabel = UILabel(frame: CGRect(x: 20, y: view.bounds.height / 2 - 100, width: view.bounds.width - 40, height: 60))
        questionLabel.textAlignment = .center
        questionLabel.font = UIFont.boldSystemFont(ofSize: 48)
        questionLabel.textColor = .white
        questionLabel.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
        questionLabel.layer.cornerRadius = 10
        questionLabel.layer.masksToBounds = true
        view.addSubview(questionLabel)
        
        // Lives container with 3D craft icons at top left
        livesContainer = UIView(frame: CGRect(x: 10, y: 50, width: 220, height: 60))
        view.addSubview(livesContainer)
        
        setupLivesDisplay()
        
        // Streak/Score label at top right
        streakLabel = UILabel(frame: CGRect(x: view.bounds.width - 200, y: 50, width: 190, height: 60))
        streakLabel.textAlignment = .right
        streakLabel.font = UIFont.boldSystemFont(ofSize: 18)
        streakLabel.textColor = .cyan
        streakLabel.numberOfLines = 2
        updateStreakDisplay()
        view.addSubview(streakLabel)
        
        // Answer buttons (3 for easy/medium, 4 for hard)
        // Store buttons in array, will position them dynamically based on count
        let buttonWidth: CGFloat = 85
        let spacing: CGFloat = 15
        let maxButtons = 4
        
        for i in 0..<maxButtons {
            // Position will be updated in spawnMeteorWithQuestion
            let button = UIButton(frame: CGRect(x: 0, y: 40, width: buttonWidth, height: 80))
            button.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
            button.layer.cornerRadius = 10
            button.tag = i
            button.addTarget(self, action: #selector(answerTapped(_:)), for: .touchUpInside)
            controlPanel.addSubview(button)
            answerButtons.append(button)
        }
    }
    
    func setupLivesDisplay() {
        // Clear existing lives
        liveCraftNodes.forEach { $0.removeFromSuperview() }
        liveCraftNodes.removeAll()
        
        let craftSize: CGFloat = 60
        let spacing: CGFloat = 10
        
        // Use simple text labels as fallback that definitely work
        for i in 0..<3 {
            let lifeView = UIView(frame: CGRect(x: CGFloat(i) * (craftSize + spacing), y: 0, width: craftSize, height: craftSize))
            lifeView.backgroundColor = UIColor(red: 0.1, green: 0.3, blue: 0.5, alpha: 0.8)
            lifeView.layer.cornerRadius = 8
            lifeView.layer.borderWidth = 3
            lifeView.layer.borderColor = UIColor.cyan.cgColor
            
            // Add a label showing ship icon
            let label = UILabel(frame: lifeView.bounds)
            label.text = "🚀"
            label.font = UIFont.systemFont(ofSize: 40)
            label.textAlignment = .center
            lifeView.addSubview(label)
            
            livesContainer.addSubview(lifeView)
            
            // Store as SCNView for compatibility (even though it's not)
            let dummyView = SCNView(frame: .zero)
            dummyView.tag = i
            liveCraftNodes.append(dummyView)
            
            // Store reference to actual view for fading
            lifeView.tag = 1000 + i
        }
    }
    
    func generateMathQuestion() -> (question: String, answer: Int, options: [Int]) {
        var question: String
        var answer: Int
        var num1: Int
        var num2: Int
        
        // Keep generating until we get a different question
        repeat {
            // Pick a random table from selected tables (this goes second)
            num2 = selectedTables.randomElement() ?? 2
            // Multiply by random number 1-12 (this goes first)
            num1 = Int.random(in: 1...12)
            answer = num1 * num2
            // Format: random × selected_table (e.g., "10 × 3" for 3x table)
            question = "\(num1) × \(num2) = ?"
        } while question == lastQuestion
        
        lastQuestion = question
        
        // Generate wrong answers based on difficulty
        let optionsCount = difficulty == .hard ? 4 : 3
        var options = [answer]
        
        while options.count < optionsCount {
            let wrong = answer + Int.random(in: -15...15)
            if wrong > 0 && wrong != answer && !options.contains(wrong) {
                options.append(wrong)
            }
        }
        options.shuffle()
        
        return (question, answer, options)
    }
    
    func spawnMeteorWithQuestion() {
        // Remove old meteor if exists
        meteor?.removeFromParentNode()
        
        questionNumber += 1
        
        // Generate question
        let (question, answer, options) = generateMathQuestion()
        currentAnswer = answer
        currentQuestionText = question
        attemptsLeft = maxAttempts
        
        // Update UI
        questionLabel.text = question
        
        // Show/hide and position buttons based on count
        let buttonWidth: CGFloat = 85
        let spacing: CGFloat = 15
        let visibleButtons = options.count
        let totalWidth = buttonWidth * CGFloat(visibleButtons) + spacing * CGFloat(visibleButtons - 1)
        let startX = (view.bounds.width - totalWidth) / 2
        
        for (i, button) in answerButtons.enumerated() {
            if i < options.count {
                button.frame.origin.x = startX + CGFloat(i) * (buttonWidth + spacing)
                button.setTitle("\(options[i])", for: .normal)
                button.isEnabled = true
                button.alpha = 1.0
                button.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
                button.isHidden = false
            } else {
                button.isHidden = true
            }
        }
        
        // Load detailed meteor asset
        guard let meteorScene = SCNScene(named: "art.scnassets/meteor_detailed.dae") else {
            print("Could not load meteor_detailed.dae")
            return
        }
        
        meteor = SCNNode()
        for child in meteorScene.rootNode.childNodes {
            meteor?.addChildNode(child)
        }
        
        // Random position for this question
        currentPosition = Float.random(in: -2.0...2.0)
        
        meteor?.scale = SCNVector3(x: 0.8, y: 0.8, z: 0.8)
        meteor?.position = SCNVector3(x: currentPosition, y: 1, z: -30)
        gameScene.rootNode.addChildNode(meteor!)
        
        // Move ship to match meteor position with roll animation
        moveShipToPosition(currentPosition)
        
        // Progressive difficulty within each level - meteor approaches faster
        // But resets with each new level since math is harder
        let baseDuration = 8.0
        let speedIncrease = Double(questionNumber) * 0.3
        let meteorDuration = max(4.0, baseDuration - speedIncrease)  // Min 4 seconds (was 3)
        
        // Meteor always moves toward ship at current position
        let moveAction = SCNAction.move(to: SCNVector3(x: currentPosition, y: -1, z: 0), duration: meteorDuration)
        let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 2, z: 0.5, duration: 1.0))
        meteor?.runAction(rotateAction)
        meteor?.runAction(moveAction) {
            // If meteor reaches ship (wasn't answered in time)
            if self.meteor?.parent != nil {
                print("⏰ Meteor timeout - hitting ship")
                self.handleMeteorTimeout()
            }
        }
        
        // Increase star speed gradually
        starSpeed = min(0.8, 0.3 + Float(questionNumber) * 0.02)
    }
    
    @objc func answerTapped(_ sender: UIButton) {
        guard let answerText = sender.title(for: .normal), let selectedAnswer = Int(answerText) else { return }
        
        if selectedAnswer == currentAnswer {
            // Correct answer - shoot laser
            currentStreak += 1
            if currentStreak > topScore {
                topScore = currentStreak
            }
            
            // Track statistics
            totalMeteorsDestroyed += 1
            if attemptsLeft == maxAttempts {
                firstAttemptCorrect += 1
            } else {
                secondAttemptCorrect += 1
            }
            
            updateStreakDisplay()
            
            shootLaser()
            sender.backgroundColor = .green
            
            // Disable all buttons briefly
            answerButtons.forEach { $0.isEnabled = false }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.spawnMeteorWithQuestion()
                self.answerButtons.forEach {
                    $0.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
                }
            }
        } else {
            // Wrong answer
            sender.backgroundColor = .red
            sender.isEnabled = false
            attemptsLeft -= 1
            
            if attemptsLeft <= 0 {
                // Track missed question
                missedQuestions.append(currentQuestionText)
                // Hit by meteor
                meteorHitsShip()
            }
        }
    }
    
    func shootLaser() {
        // Create short laser burst that travels from ship to meteor
        let laser = SCNNode(geometry: SCNCylinder(radius: 0.12, height: 3.0))
        laser.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
        laser.geometry?.firstMaterial?.emission.contents = UIColor.cyan
        laser.geometry?.firstMaterial?.transparency = 0.9
        
        // Start at ship position, offset forward slightly
        laser.position = SCNVector3(x: currentPosition, y: -1, z: -1.5)
        laser.eulerAngles = SCNVector3(x: Float.pi / 2, y: 0, z: 0)
        gameScene.rootNode.addChildNode(laser)
        
        // Calculate meteor position - aim for center of meteor
        let meteorZ = meteor?.position.z ?? -30
        let targetZ = meteorZ  // Aim for center of meteor
        
        // Fast travel to meteor
        let travelDuration = 0.18
        let moveAction = SCNAction.move(to: SCNVector3(x: currentPosition, y: -1, z: targetZ), duration: travelDuration)
        moveAction.timingMode = .linear
        let fadeOut = SCNAction.fadeOut(duration: travelDuration * 0.6)
        
        let group = SCNAction.group([moveAction, fadeOut])
        laser.runAction(group) {
            laser.removeFromParentNode()
            self.explodeMeteor()
        }
    }
    
    func explodeMeteor() {
        guard let meteor = meteor else { return }
        let meteorPosition = meteor.position
        
        // Remove original meteor
        meteor.removeFromParentNode()
        
        // Create 6 meteor_half fragments
        for _ in 0..<6 {
            if let meteorHalfScene = SCNScene(named: "art.scnassets/meteor_half.dae") {
                let fragment = SCNNode()
                for child in meteorHalfScene.rootNode.childNodes {
                    fragment.addChildNode(child)
                }
                
                fragment.scale = SCNVector3(x: 0.4, y: 0.4, z: 0.4)
                fragment.position = meteorPosition
                gameScene.rootNode.addChildNode(fragment)
                
                // Random explosion direction
                let randomX = Float.random(in: -4...4)
                let randomY = Float.random(in: -3...3)
                let randomZ = Float.random(in: 2...6)
                
                let moveAction = SCNAction.move(by: SCNVector3(x: randomX, y: randomY, z: randomZ), duration: 1.5)
                let rotateAction = SCNAction.rotateBy(x: CGFloat.random(in: 0...10), y: CGFloat.random(in: 0...10), z: CGFloat.random(in: 0...10), duration: 1.5)
                let fadeAction = SCNAction.fadeOut(duration: 1.2)
                let group = SCNAction.group([moveAction, rotateAction, fadeAction])
                let remove = SCNAction.removeFromParentNode()
                
                fragment.runAction(SCNAction.sequence([group, remove]))
            }
        }
    }
    
    func handleMeteorTimeout() {
        // Meteor reached ship because player didn't answer in time
        guard let meteor = meteor, meteor.parent != nil else {
            print("⛔ Meteor already gone")
            return
        }
        
        // Track missed question
        missedQuestions.append(currentQuestionText)
        
        // Lose a life
        lives -= 1
        print("⚠️ TIMEOUT HIT! Lives remaining: \(lives)")
        updateLivesDisplay()
        
        // Reset streak on hit
        currentStreak = 0
        updateStreakDisplay()
        
        // Meteor is already at ship position, just explode it
        breakMeteorIntoPieces()
        
        if lives > 0 {
            // Ship survives - flash red and shake
            shakeShip()
        } else {
            // Final life - ship explodes too
            explodeShip()
        }
        
        // Disable buttons
        DispatchQueue.main.async {
            self.answerButtons.forEach { $0.isEnabled = false }
        }
        
        if lives > 0 {
            // Still have lives - continue game
            print("✅ Continuing with \(lives) lives")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.spawnMeteorWithQuestion()
                self.answerButtons.forEach {
                    $0.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
                }
            }
        } else {
            // No lives left - show game over after explosion
            print("💀 GAME OVER - No lives remaining")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showGameOver()
            }
        }
    }
    
    func meteorHitsShip() {
        // Player selected wrong answer twice
        guard let meteor = meteor else {
            print("⛔ meteorHitsShip called but meteor is nil")
            return
        }
        
        // Prevent duplicate calls
        if meteor.parent == nil {
            print("⛔ Meteor already removed, skipping")
            return
        }
        
        // Lose a life first
        lives -= 1
        print("⚠️ HIT! Lives remaining: \(lives)")
        updateLivesDisplay()
        
        // Reset streak on hit
        currentStreak = 0
        updateStreakDisplay()
        
        // Stop meteor's approach animation and make it collide with ship
        meteor.removeAllActions()
        
        let collisionAction = SCNAction.move(to: SCNVector3(x: currentPosition, y: -1, z: 0), duration: 0.5)
        meteor.runAction(collisionAction) {
            // Explode meteor into pieces
            self.breakMeteorIntoPieces()
            
            if self.lives > 0 {
                // Ship survives - flash red and shake
                self.shakeShip()
            } else {
                // Final life - ship explodes too
                self.explodeShip()
            }
        }
        
        // Disable buttons
        DispatchQueue.main.async {
            self.answerButtons.forEach { $0.isEnabled = false }
        }
        
        if lives > 0 {
            // Still have lives - continue game
            print("✅ Continuing with \(lives) lives")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.spawnMeteorWithQuestion()
                self.answerButtons.forEach {
                    $0.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
                }
            }
        } else {
            // No lives left - show game over after explosion
            print("💀 GAME OVER - No lives remaining")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showGameOver()
            }
        }
    }
    
    func breakMeteorIntoPieces() {
        guard let meteor = meteor else { return }
        let meteorPosition = meteor.position
        
        // Remove original meteor
        meteor.removeFromParentNode()
        
        // Create 8 meteor_half fragments for dramatic collision
        for _ in 0..<8 {
            if let meteorHalfScene = SCNScene(named: "art.scnassets/meteor_half.dae") {
                let fragment = SCNNode()
                for child in meteorHalfScene.rootNode.childNodes {
                    fragment.addChildNode(child)
                }
                
                fragment.scale = SCNVector3(x: 0.3, y: 0.3, z: 0.3)
                fragment.position = meteorPosition
                gameScene.rootNode.addChildNode(fragment)
                
                // Random explosion direction
                let randomX = Float.random(in: -5...5)
                let randomY = Float.random(in: -4...4)
                let randomZ = Float.random(in: -3...8)
                
                let moveAction = SCNAction.move(by: SCNVector3(x: randomX, y: randomY, z: randomZ), duration: 2.0)
                let rotateAction = SCNAction.rotateBy(x: CGFloat.random(in: 0...12), y: CGFloat.random(in: 0...12), z: CGFloat.random(in: 0...12), duration: 2.0)
                let fadeAction = SCNAction.fadeOut(duration: 1.5)
                let group = SCNAction.group([moveAction, rotateAction, fadeAction])
                let remove = SCNAction.removeFromParentNode()
                
                fragment.runAction(SCNAction.sequence([group, remove]))
            }
        }
    }
    
    func shakeShip() {
        // Turn ship red
        spaceship.enumerateChildNodes { node, _ in
            node.geometry?.firstMaterial?.emission.contents = UIColor.red
        }
        
        // Shake animation
        let originalPosition = spaceship.position
        let shakeDistance: Float = 0.3
        
        let shake1 = SCNAction.move(to: SCNVector3(x: originalPosition.x - shakeDistance, y: originalPosition.y, z: originalPosition.z), duration: 0.05)
        let shake2 = SCNAction.move(to: SCNVector3(x: originalPosition.x + shakeDistance, y: originalPosition.y, z: originalPosition.z), duration: 0.05)
        let shake3 = SCNAction.move(to: SCNVector3(x: originalPosition.x, y: originalPosition.y - shakeDistance, z: originalPosition.z), duration: 0.05)
        let shake4 = SCNAction.move(to: SCNVector3(x: originalPosition.x, y: originalPosition.y + shakeDistance, z: originalPosition.z), duration: 0.05)
        let reset = SCNAction.move(to: originalPosition, duration: 0.05)
        
        let shakeSequence = SCNAction.sequence([shake1, shake2, shake3, shake4, shake1, shake2, reset])
        spaceship.runAction(shakeSequence)
        
        // Reset color after shake
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.spaceship.enumerateChildNodes { node, _ in
                node.geometry?.firstMaterial?.emission.contents = UIColor.black
            }
        }
    }
    
    func explodeShip() {
        let shipPosition = spaceship.position
        
        // Hide ship immediately
        spaceship.isHidden = true
        
        // Create explosion fragments from ship
        for _ in 0..<10 {
            let fragment = SCNNode(geometry: SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0.05))
            fragment.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
            fragment.geometry?.firstMaterial?.emission.contents = UIColor.red
            fragment.position = shipPosition
            gameScene.rootNode.addChildNode(fragment)
            
            // Random explosion direction
            let randomX = Float.random(in: -6...6)
            let randomY = Float.random(in: -5...5)
            let randomZ = Float.random(in: -4...4)
            
            let moveAction = SCNAction.move(by: SCNVector3(x: randomX, y: randomY, z: randomZ), duration: 1.5)
            let rotateAction = SCNAction.rotateBy(x: CGFloat.random(in: 0...10), y: CGFloat.random(in: 0...10), z: CGFloat.random(in: 0...10), duration: 1.5)
            let fadeAction = SCNAction.fadeOut(duration: 1.2)
            let group = SCNAction.group([moveAction, rotateAction, fadeAction])
            let remove = SCNAction.removeFromParentNode()
            
            fragment.runAction(SCNAction.sequence([group, remove]))
        }
    }
    
    func updateLivesDisplay() {
        // Ensure on main thread for UI updates
        DispatchQueue.main.async {
            // Remove lives from right to left
            // Index 0 = leftmost, Index 2 = rightmost
            for index in 0..<3 {
                if let lifeView = self.livesContainer.viewWithTag(1000 + index) {
                    let isVisible = index < self.lives
                    lifeView.alpha = isVisible ? 1.0 : 0.3
                    print("Life icon \(index): \(isVisible ? "visible" : "faded")")
                }
            }
        }
    }
    
    
        func updateStreakDisplay() {
            DispatchQueue.main.async {
                self.streakLabel.text = "Streak: \(self.currentStreak)\nTop: \(self.topScore)"
        }
    }
    
    func showGameOver() {
        // Ensure we're on main thread for UI updates
        DispatchQueue.main.async {
            print("🎮 Showing game over screen")
            self.questionLabel.text = "GAME OVER"
            self.questionLabel.textColor = .red
            self.answerButtons.forEach { $0.isHidden = true }
            
            // Hide spaceship
            self.spaceship.isHidden = true
            
            // Add spinning meteor decoration
            self.addSpinningMeteorDecoration()
            
            // Stats panel
            let statsPanel = UIView(frame: CGRect(x: 20, y: self.view.bounds.height / 2 - 50, width: self.view.bounds.width - 40, height: 220))
            statsPanel.backgroundColor = UIColor(white: 0.1, alpha: 0.9)
            statsPanel.layer.cornerRadius = 15
            statsPanel.layer.borderWidth = 2
            statsPanel.layer.borderColor = UIColor.cyan.cgColor
            self.view.addSubview(statsPanel)
            
            // Meteors Destroyed
            let destroyedLabel = UILabel(frame: CGRect(x: 20, y: 20, width: statsPanel.bounds.width - 40, height: 30))
            destroyedLabel.text = "💥 Meteors Destroyed: \(self.totalMeteorsDestroyed)"
            destroyedLabel.font = UIFont.boldSystemFont(ofSize: 20)
            destroyedLabel.textColor = .cyan
            destroyedLabel.textAlignment = .center
            statsPanel.addSubview(destroyedLabel)
            
            // First attempt correct
            let firstAttemptLabel = UILabel(frame: CGRect(x: 20, y: 60, width: statsPanel.bounds.width - 40, height: 25))
            firstAttemptLabel.text = "✅ First Try: \(self.firstAttemptCorrect)"
            firstAttemptLabel.font = UIFont.systemFont(ofSize: 18)
            firstAttemptLabel.textColor = .green
            statsPanel.addSubview(firstAttemptLabel)
            
            // Second attempt correct
            if self.secondAttemptCorrect > 0 {
                let secondAttemptLabel = UILabel(frame: CGRect(x: 20, y: 90, width: statsPanel.bounds.width - 40, height: 25))
                secondAttemptLabel.text = "⚠️ Second Try: \(self.secondAttemptCorrect)"
                secondAttemptLabel.font = UIFont.systemFont(ofSize: 18)
                secondAttemptLabel.textColor = .yellow
                statsPanel.addSubview(secondAttemptLabel)
            }
            
            // Questions to work on
            if !self.missedQuestions.isEmpty {
                let workOnLabel = UILabel(frame: CGRect(x: 20, y: 120, width: statsPanel.bounds.width - 40, height: 25))
                workOnLabel.text = "📝 Questions to Work On:"
                workOnLabel.font = UIFont.boldSystemFont(ofSize: 16)
                workOnLabel.textColor = .orange
                statsPanel.addSubview(workOnLabel)
                
                // Show up to 3 missed questions
                let maxDisplay = min(3, self.missedQuestions.count)
                for i in 0..<maxDisplay {
                    let questionLabel = UILabel(frame: CGRect(x: 30, y: 150 + CGFloat(i * 22), width: statsPanel.bounds.width - 60, height: 20))
                    questionLabel.text = "• \(self.missedQuestions[i])"
                    questionLabel.font = UIFont.systemFont(ofSize: 14)
                    questionLabel.textColor = .white
                    statsPanel.addSubview(questionLabel)
                }
            }
            
            // Menu button
            let menuButton = UIButton(frame: CGRect(x: self.view.bounds.width/2 - 100, y: self.controlPanel.frame.minY + 30, width: 200, height: 60))
            menuButton.setTitle("Back to Menu", for: .normal)
            menuButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
            menuButton.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0)
            menuButton.setTitleColor(.white, for: .normal)
            menuButton.layer.cornerRadius = 10
            menuButton.addTarget(self, action: #selector(self.backToMenu), for: .touchUpInside)
            self.view.addSubview(menuButton)
            print("✅ Game over UI created")
        }
    }
    
    func addSpinningMeteorDecoration() {
        // Add a spinning meteor as decoration on game over screen
        guard let meteorScene = SCNScene(named: "art.scnassets/meteor_detailed.dae") else { return }
        
        let decorMeteor = SCNNode()
        for child in meteorScene.rootNode.childNodes {
            decorMeteor.addChildNode(child)
        }
        
        decorMeteor.scale = SCNVector3(x: 1.2, y: 1.2, z: 1.2)
        decorMeteor.position = SCNVector3(x: 0, y: 0, z: -15)
        gameScene.rootNode.addChildNode(decorMeteor)
        
        // Spin continuously
        let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0.5, y: 1.5, z: 0.3, duration: 2.0))
        decorMeteor.runAction(rotateAction)
    }
    
    @objc func backToMenu() {
        print("🔙 Returning to menu")
        dismiss(animated: true)
    }
    
    func moveShipToPosition(_ x: Float) {
        let targetPosition = SCNVector3(x: x, y: -1, z: 0)
        
        // Calculate roll based on direction and distance
        let rollAngle = -x * 0.3  // Negative because banking left = positive roll
        
        // Move ship with smooth animation
        let moveAction = SCNAction.move(to: targetPosition, duration: 0.8)
        moveAction.timingMode = .easeInEaseOut
        
        // Roll ship during movement
        let rollAction = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(rollAngle), duration: 0.4)
        let levelAction = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-rollAngle), duration: 0.4)
        let rollSequence = SCNAction.sequence([rollAction, levelAction])
        
        spaceship.runAction(moveAction)
        spaceship.runAction(rollSequence)
    }
    
    func startAnimation() {
        // Animate stars moving towards camera with progressive speed
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            for star in self.stars {
                // Move star towards camera at current speed
                star.position.z += self.starSpeed
                
                // Reset star position when it passes the camera
                if star.position.z > 10 {
                    star.position.z = -50
                    star.position.x = Float.random(in: -20...20)
                    star.position.y = Float.random(in: -20...20)
                }
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

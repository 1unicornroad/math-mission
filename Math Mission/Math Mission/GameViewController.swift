//
//  GameViewController.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import UIKit
import SceneKit
import AudioToolbox

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
    
    // Track which specific problems were answered correctly on first attempt
    var perfectProblems: [String: Int] = [:]  // e.g. "3×4": 2 means answered perfectly twice
    
    // Game settings from menu
    var selectedTables: [Int] = [2, 3, 4, 5]  // Default
    var customProblems: [String] = []  // For custom mode like ["3×4", "5×7"]
    var difficulty: Difficulty = .easy
    var maxAttempts: Int = 2
    var selectedShipModel: String = "craft_speederA.dae"
    var meteor: SCNNode?
    var questionLabel: UILabel!
    var streakLabel: UILabel!
    var livesContainer: UIView!
    var liveCraftNodes: [SCNView] = []
    
    // Control panel buttons
    var answerButtons: [UIButton] = []
    var controlPanel: UIView!
    
    // Callback for game over
    var gameOverCallback: ((Int, Int, [String: Int]) -> Void)?
    var playAgainCallback: (([String]) -> Void)?

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
        
        // Start audio
        AudioManager.shared.startThruster()
        
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
        guard let spaceshipScene = SCNScene(named: "art.scnassets/\(selectedShipModel)") else {
            print("Could not load ship model: \(selectedShipModel)")
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
        questionLabel.font = UIFont.exo2Bold(size: 50)
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
        streakLabel.font = UIFont.exo2SemiBold(size: 18)
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
            button.titleLabel?.font = UIFont.exo2Bold(size: 34)
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
        
        // Check if using custom problems
        if !customProblems.isEmpty {
            // Select a random custom problem
            let problemString = customProblems.randomElement() ?? "2×3"
            let parts = problemString.split(separator: "×")
            if parts.count == 2, let n1 = Int(parts[0]), let n2 = Int(parts[1]) {
                num1 = n1
                num2 = n2
                answer = num1 * num2
                question = "\(num1) × \(num2) = ?"
            } else {
                // Fallback if parsing fails
                num1 = 2
                num2 = 3
                answer = 6
                question = "2 × 3 = ?"
            }
        } else {
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
        }
        
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
        
        // Fade out question and buttons
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, animations: {
                self.questionLabel.alpha = 0
                self.answerButtons.forEach { $0.alpha = 0 }
            }, completion: { _ in
                // Update question text
                self.questionLabel.text = question
                
                // Show/hide and position buttons based on count
                let buttonWidth: CGFloat = 85
                let spacing: CGFloat = 15
                let visibleButtons = options.count
                let totalWidth = buttonWidth * CGFloat(visibleButtons) + spacing * CGFloat(visibleButtons - 1)
                let startX = (self.view.bounds.width - totalWidth) / 2
                
                for (i, button) in self.answerButtons.enumerated() {
                    if i < options.count {
                        button.frame.origin.x = startX + CGFloat(i) * (buttonWidth + spacing)
                        button.setTitle("\(options[i])", for: .normal)
                        button.isEnabled = true
                        button.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
                        button.isHidden = false
                    } else {
                        button.isHidden = true
                    }
                }
                
                // Fade in new question and buttons
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut, animations: {
                    self.questionLabel.alpha = 1.0
                    self.answerButtons.forEach { button in
                        if !button.isHidden {
                            button.alpha = 1.0
                        }
                    }
                })
            })
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
        
        // Progressive speed increase starts after 24 questions (2 full rounds of 12 tables)
        let baseDuration = 6.0  // 6 seconds - comfortable but encourages quick thinking
        let speedIncrease: Double
        
        if questionNumber <= 24 {
            // First 24 questions: consistent comfortable speed
            speedIncrease = 0
        } else {
            // After 24: progressively faster, 0.15 seconds faster per question
            speedIncrease = Double(questionNumber - 24) * 0.15
        }
        
        let meteorDuration = max(1.5, baseDuration - speedIncrease)  // Min 1.5 seconds - intense!
        
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
        
        // Increase star speed gradually after round 24
        if questionNumber > 24 {
            starSpeed = min(0.8, 0.3 + Float(questionNumber - 24) * 0.015)
        }
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
                // Track this specific problem as perfect (format: "3×4")
                let problemKey = currentQuestionText.replacingOccurrences(of: " = ?", with: "").replacingOccurrences(of: " ", with: "")
                perfectProblems[problemKey, default: 0] += 1
            } else {
                secondAttemptCorrect += 1
            }
            
            updateStreakDisplay()
            
            shootLaser()
            sender.backgroundColor = .green
            
            // Disable all buttons briefly and fade them
            answerButtons.forEach { $0.isEnabled = false }
            
            // Flash green then fade out before next question
            UIView.animate(withDuration: 0.3, delay: 0.5, animations: {
                sender.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
            })
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.spawnMeteorWithQuestion()
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
        // Play laser sound
        AudioManager.shared.playLaserFire()
        
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
        
        // Play explosion sound
        AudioManager.shared.playMeteorExplosion()
        
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
        
        // Play ship hit sound
        AudioManager.shared.playShipHit()
        
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
        // Vibrate device
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
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
        
        // Play ship explosion sound and stop thruster
        AudioManager.shared.playShipExplosion()
        AudioManager.shared.stopThruster()
        
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
            self.questionLabel.isHidden = true
            self.answerButtons.forEach { $0.isHidden = true }
            self.spaceship.isHidden = true
            self.streakLabel.isHidden = true
            
            // Add spinning meteor decoration
            self.addSpinningMeteorDecoration()
            
            // GAME OVER title
            let gameOverLabel = UILabel(frame: CGRect(x: 0, y: 80, width: self.view.bounds.width, height: 60))
            gameOverLabel.text = "GAME OVER"
            gameOverLabel.font = UIFont(name: "Orbitron-Bold", size: 42) ?? UIFont.boldSystemFont(ofSize: 42)
            gameOverLabel.textColor = .red
            gameOverLabel.textAlignment = .center
            gameOverLabel.layer.shadowColor = UIColor.red.cgColor
            gameOverLabel.layer.shadowRadius = 15
            gameOverLabel.layer.shadowOpacity = 1.0
            gameOverLabel.layer.shadowOffset = .zero
            self.view.addSubview(gameOverLabel)
            
            // Pulsing animation
            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 1.0
            pulse.toValue = 1.08
            pulse.duration = 0.8
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            gameOverLabel.layer.add(pulse, forKey: "pulse")
            
            // Stats container
            let statsPanel = UIView(frame: CGRect(x: 20, y: 160, width: self.view.bounds.width - 40, height: 360))
            statsPanel.backgroundColor = UIColor.black.withAlphaComponent(0.85)
            statsPanel.layer.cornerRadius = 20
            statsPanel.layer.borderWidth = 4
            statsPanel.layer.borderColor = UIColor.cyan.cgColor
            statsPanel.layer.shadowColor = UIColor.cyan.cgColor
            statsPanel.layer.shadowRadius = 15
            statsPanel.layer.shadowOpacity = 0.8
            statsPanel.layer.shadowOffset = .zero
            self.view.addSubview(statsPanel)
            
            var yPos: CGFloat = 20
            
            // Score header
            let scoreHeader = UILabel(frame: CGRect(x: 20, y: yPos, width: statsPanel.bounds.width - 40, height: 30))
            scoreHeader.text = "== MISSION STATS =="
            scoreHeader.font = UIFont(name: "Orbitron-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20)
            scoreHeader.textColor = .cyan
            scoreHeader.textAlignment = .center
            statsPanel.addSubview(scoreHeader)
            yPos += 40
            
            // Meteors Destroyed - BIG NUMBER
            let destroyedValue = UILabel(frame: CGRect(x: 20, y: yPos, width: statsPanel.bounds.width - 40, height: 45))
            destroyedValue.text = "\(self.totalMeteorsDestroyed)"
            destroyedValue.font = UIFont(name: "Orbitron-Bold", size: 54) ?? UIFont.boldSystemFont(ofSize: 54)
            destroyedValue.textColor = .yellow
            destroyedValue.textAlignment = .center
            destroyedValue.layer.shadowColor = UIColor.yellow.cgColor
            destroyedValue.layer.shadowRadius = 10
            destroyedValue.layer.shadowOpacity = 0.8
            destroyedValue.layer.shadowOffset = .zero
            statsPanel.addSubview(destroyedValue)
            yPos += 50
            
            let destroyedLabel = UILabel(frame: CGRect(x: 20, y: yPos, width: statsPanel.bounds.width - 40, height: 20))
            destroyedLabel.text = "METEORS DESTROYED"
            destroyedLabel.font = UIFont(name: "Exo 2 Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14)
            destroyedLabel.textColor = .white
            destroyedLabel.textAlignment = .center
            statsPanel.addSubview(destroyedLabel)
            yPos += 30
            
            // Accuracy stats
            let accuracyStack = UIStackView(frame: CGRect(x: 25, y: yPos, width: statsPanel.bounds.width - 50, height: 60))
            accuracyStack.axis = .horizontal
            accuracyStack.distribution = .fillEqually
            accuracyStack.spacing = 10
            
            let perfectContainer = self.createStatBox(value: "\(self.firstAttemptCorrect)", label: "PERFECT", color: .green)
            accuracyStack.addArrangedSubview(perfectContainer)
            
            if self.secondAttemptCorrect > 0 {
                let okContainer = self.createStatBox(value: "\(self.secondAttemptCorrect)", label: "RETRY", color: .yellow)
                accuracyStack.addArrangedSubview(okContainer)
            }
            
            let missedCount = self.missedQuestions.count
            let missedContainer = self.createStatBox(value: "\(missedCount)", label: "MISSED", color: .red)
            accuracyStack.addArrangedSubview(missedContainer)
            
            statsPanel.addSubview(accuracyStack)
            yPos += 70
            
            // Missed questions list
            if !self.missedQuestions.isEmpty {
                let missedHeader = UILabel(frame: CGRect(x: 20, y: yPos, width: statsPanel.bounds.width - 40, height: 25))
                missedHeader.text = "📝 PRACTICE THESE:"
                missedHeader.font = UIFont(name: "Exo 2 Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14)
                missedHeader.textColor = .orange
                missedHeader.textAlignment = .center
                statsPanel.addSubview(missedHeader)
                yPos += 28
                
                // Show up to 4 missed questions in columns
                let maxDisplay = min(4, self.missedQuestions.count)
                let columns = 2
                for i in 0..<maxDisplay {
                    let col = i % columns
                    let row = i / columns
                    let questionLabel = UILabel(frame: CGRect(
                        x: 30 + CGFloat(col) * (statsPanel.bounds.width - 60) / 2,
                        y: yPos + CGFloat(row) * 20,
                        width: (statsPanel.bounds.width - 60) / 2 - 10,
                        height: 18
                    ))
                    questionLabel.text = self.missedQuestions[i]
                    questionLabel.font = UIFont(name: "Exo 2 SemiBold", size: 13) ?? UIFont.systemFont(ofSize: 13)
                    questionLabel.textColor = .white
                    questionLabel.textAlignment = .center
                    questionLabel.backgroundColor = UIColor.red.withAlphaComponent(0.2)
                    questionLabel.layer.cornerRadius = 4
                    questionLabel.layer.masksToBounds = true
                    statsPanel.addSubview(questionLabel)
                }
            }
            
            // Buttons container
            let buttonY = statsPanel.frame.maxY + 20
            
            // Play Again button (if there are missed questions)
            if !self.missedQuestions.isEmpty {
                let playAgainButton = UIButton(frame: CGRect(x: 30, y: buttonY, width: self.view.bounds.width - 60, height: 55))
                playAgainButton.setTitle("🔁 PRACTICE MISSED", for: .normal)
                playAgainButton.titleLabel?.font = UIFont(name: "Orbitron-Bold", size: 22) ?? UIFont.boldSystemFont(ofSize: 22)
                playAgainButton.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0)
                playAgainButton.setTitleColor(.white, for: .normal)
                playAgainButton.layer.cornerRadius = 12
                playAgainButton.layer.borderWidth = 3
                playAgainButton.layer.borderColor = UIColor.green.cgColor
                playAgainButton.layer.shadowColor = UIColor.green.cgColor
                playAgainButton.layer.shadowRadius = 10
                playAgainButton.layer.shadowOpacity = 0.8
                playAgainButton.layer.shadowOffset = .zero
                playAgainButton.addTarget(self, action: #selector(self.playAgainWithMissed), for: .touchUpInside)
                self.view.addSubview(playAgainButton)
                
                // Menu button below
                let menuButton = UIButton(frame: CGRect(x: self.view.bounds.width/2 - 110, y: buttonY + 65, width: 220, height: 50))
                menuButton.setTitle("← MAIN MENU", for: .normal)
                menuButton.titleLabel?.font = UIFont(name: "Orbitron-Bold", size: 20) ?? UIFont.boldSystemFont(ofSize: 20)
                menuButton.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
                menuButton.setTitleColor(.white, for: .normal)
                menuButton.layer.cornerRadius = 10
                menuButton.addTarget(self, action: #selector(self.backToMenu), for: .touchUpInside)
                self.view.addSubview(menuButton)
            } else {
                // Just menu button if no missed questions
                let menuButton = UIButton(frame: CGRect(x: self.view.bounds.width/2 - 110, y: buttonY, width: 220, height: 55))
                menuButton.setTitle("← MAIN MENU", for: .normal)
                menuButton.titleLabel?.font = UIFont(name: "Orbitron-Bold", size: 24) ?? UIFont.boldSystemFont(ofSize: 24)
                menuButton.backgroundColor = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
                menuButton.setTitleColor(.white, for: .normal)
                menuButton.layer.cornerRadius = 12
                menuButton.layer.borderWidth = 3
                menuButton.layer.borderColor = UIColor.orange.cgColor
                menuButton.layer.shadowColor = UIColor.orange.cgColor
                menuButton.layer.shadowRadius = 10
                menuButton.layer.shadowOpacity = 0.8
                menuButton.layer.shadowOffset = .zero
                menuButton.addTarget(self, action: #selector(self.backToMenu), for: .touchUpInside)
                self.view.addSubview(menuButton)
            }
            
            print("✅ Game over UI created")
        }
    }
    
    func createStatBox(value: String, label: String, color: UIColor) -> UIView {
        let container = UIView()
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont(name:"Orbitron-Bold", size: 32)
        valueLabel.textColor = color
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        
        let textLabel = UILabel()
        textLabel.text = label
        textLabel.font = UIFont(name:"Exo 2 SemiBold", size: 11)
        textLabel.textColor = .white
        textLabel.textAlignment = .center
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor),
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            textLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            textLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        return container
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
    
    @objc func playAgainWithMissed() {
        print("🔁 Playing again with missed questions")
        // Extract just the problem part (e.g., "3×4" from "3 × 4 = ?")
        let missedProblems = missedQuestions.map { question in
            question.replacingOccurrences(of: " = ?", with: "").replacingOccurrences(of: " ", with: "")
        }
        playAgainCallback?(missedProblems)
    }
    
    @objc func backToMenu() {
        print("🔙 Returning to main menu")
        
        // Trigger unlock check callback before dismissing
        // Pass the dictionary of perfect problems with counts
        gameOverCallback?(totalMeteorsDestroyed, firstAttemptCorrect, perfectProblems)
        
        // Dismiss all the way back to root (main menu)
        // GameVC was presented by ShipSelectionVC, which was presented by MenuVC
        // So we need to dismiss to the root
        var rootVC = self.presentingViewController
        while let presenter = rootVC?.presentingViewController {
            rootVC = presenter
        }
        rootVC?.dismiss(animated: true, completion: nil)
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

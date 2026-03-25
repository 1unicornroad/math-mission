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
    struct StarRewardLine {
        let title: String
        let stars: Int
        let accent: UIColor
    }
    struct MeteorChoice {
        let node: SCNNode
        let answerValue: Int
        let laneX: Float
        let isCorrect: Bool
    }
    
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
    var retryCandidateQuestions: [String] = []
    var lastMissionReward: MissionStarReward?
    var didPersistSessionStats = false
    var tableAttempts: [Int: Int] = [:]
    var tableFirstAttemptCorrect: [Int: Int] = [:]
    var tableCorrectAnswers: [Int: Int] = [:]
    var tableMisses: [Int: Int] = [:]
    var activeStarRewardTimers: [Timer] = []
    let malfunctionTriggerWaves: Set<Int> = [10, 20, 25]
    let repairStarAward = 3
    var triggeredMalfunctionWaves: Set<Int> = []
    var isInMalfunctionMode = false
    var repairPromptQuestion = ""
    var repairAnswer = 0
    var repairInput = ""
    var repairStarsEarned = 0
    var repairsCompleted = 0
    var repairAttemptCountForCurrentPrompt = 0
    var repairReviewProblems: [String] = []
    
    // Track which specific problems were answered correctly on first attempt
    var perfectProblems: [String: Int] = [:]  // e.g. "3×4": 2 means answered perfectly twice
    
    // Game settings from menu
    var selectedTables: [Int] = [2, 3, 4, 5]  // Default
    var customProblems: [String] = []  // For custom mode like ["3×4", "5×7"]
    var replayFocusProblems: [String] = []
    var isReplaySession = false
    var arithmeticMode: ArithmeticMode = .multiplication
    var difficulty: Difficulty = .easy
    var maxAttempts: Int = 2
    var selectedShipModel: String = "craft_speederA.dae"
    var didCompleteReplaySession = false
    var didCompleteMission = false
    var meteor: SCNNode?
    var activeMeteorChoices: [MeteorChoice] = []
    var hasResolvedCurrentEncounter = false
    var isResolvingTap = false
    var meteorTimeoutWork: DispatchWorkItem?
    var questionLabel: UILabel!
    var questionPanel: UIView!
    var streakLabel: UILabel!
    var streakTitleLabel: UILabel!
    var answersRightLabel: UILabel!
    var answersRightTitleLabel: UILabel!
    var livesContainer: UIView!
    var hullStatusLabel: UILabel!
    var liveCraftNodes: [SCNView] = []
    var exitButton: UIButton!
    var starfieldTimer: Timer?
    var isEndingSession = false
    var hasStartedGameplay = false
    
    // Control panel buttons
    var answerButtons: [UIButton] = []
    var statusPanel: UIView!
    var gameOverOverlay: UIView?
    var malfunctionOverlay: UIView!
    var malfunctionTitleLabel: UILabel!
    var malfunctionStatusLabel: UILabel!
    var repairPromptLabel: UILabel!
    var repairInputLabel: UILabel!
    var systemsRestoredLabel: UILabel!
    var repairKeypadButtons: [UIButton] = []
    var repairConfirmButton: UIButton!
    
    // Callback for game over
    var gameOverCallback: ((Int, Int, [String: Int]) -> Void)?
    var playAgainCallback: (([String]) -> Void)?
    var exitToMenuCallback: (() -> Void)?
    
    let arcadeSpaceTop = UIColor(red: 0.04, green: 0.08, blue: 0.16, alpha: 1.0)
    let arcadePanel = UIColor(red: 0.12, green: 0.14, blue: 0.19, alpha: 0.94)
    let arcadePanelSoft = UIColor(red: 0.18, green: 0.21, blue: 0.27, alpha: 0.96)
    let arcadeSignal = UIColor(red: 0.98, green: 0.46, blue: 0.18, alpha: 1.0)
    let arcadeSignalBright = UIColor(red: 1.00, green: 0.69, blue: 0.34, alpha: 1.0)
    let arcadeCool = UIColor(red: 0.64, green: 0.78, blue: 0.94, alpha: 1.0)
    let arcadeSuccess = UIColor(red: 0.48, green: 0.87, blue: 0.52, alpha: 1.0)
    let arcadeWarning = UIColor(red: 0.99, green: 0.74, blue: 0.24, alpha: 1.0)
    let arcadeDanger = UIColor(red: 0.93, green: 0.33, blue: 0.27, alpha: 1.0)
    let replayMasteryThreshold = 3
    let missionQuestionLimit = 30
    let lanePositionsByCount: [Int: [Float]] = [
        3: [-2.5, 0.0, 2.5],
        4: [-3.3, -1.1, 1.1, 3.3]
    ]
    let meteorHoverY: Float = -0.75
    let meteorHoverZ: Float = -8.8

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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard livesContainer != nil, statusPanel != nil, questionPanel != nil else {
            return
        }
        
        layoutGameplayHUD()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        starfieldTimer?.invalidate()
        starfieldTimer = nil
        activeStarRewardTimers.forEach { $0.invalidate() }
        activeStarRewardTimers.removeAll()
        AudioManager.shared.stopThruster()
    }
    
    func beginGameplayIfNeeded() {
        guard !hasStartedGameplay else { return }
        hasStartedGameplay = true
        AudioManager.shared.startThruster()
        AudioManager.shared.startGameplayMusic()
        startAnimation()
        spawnMeteorWithQuestion()
    }
    
    func applyArcadePanelStyle(
        to view: UIView,
        accent: UIColor,
        fillColors: [UIColor],
        cornerCut: CGFloat
    ) {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return }
        
        view.backgroundColor = .clear
        view.layer.masksToBounds = false
        view.layer.sublayers?
            .filter { $0.name?.hasPrefix("arcade.") == true }
            .forEach { $0.removeFromSuperlayer() }
        
        let fillPath = beveledPath(in: view.bounds.insetBy(dx: 0.5, dy: 0.5), cut: cornerCut)
        
        let gradient = CAGradientLayer()
        gradient.name = "arcade.gradient"
        gradient.frame = view.bounds
        gradient.colors = fillColors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        let gradientMask = CAShapeLayer()
        gradientMask.path = fillPath.cgPath
        gradient.mask = gradientMask
        view.layer.insertSublayer(gradient, at: 0)
        
        let gloss = CAGradientLayer()
        gloss.name = "arcade.gloss"
        gloss.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: max(22, view.bounds.height * 0.26))
        gloss.colors = [
            accent.withAlphaComponent(0.22).cgColor,
            UIColor.clear.cgColor
        ]
        gloss.startPoint = CGPoint(x: 0.5, y: 0.0)
        gloss.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        let glossMask = CAShapeLayer()
        glossMask.path = fillPath.cgPath
        gloss.mask = glossMask
        view.layer.insertSublayer(gloss, above: gradient)
        
        let border = CAShapeLayer()
        border.name = "arcade.border"
        border.path = fillPath.cgPath
        border.fillColor = UIColor.clear.cgColor
        border.strokeColor = UIColor.white.withAlphaComponent(0.16).cgColor
        border.lineWidth = 1.4
        view.layer.addSublayer(border)
        
        let innerRect = view.bounds.insetBy(dx: 7, dy: 7)
        if innerRect.width > 0, innerRect.height > 0 {
            let innerBorder = CAShapeLayer()
            innerBorder.name = "arcade.inner-border"
            innerBorder.path = beveledPath(in: innerRect, cut: max(8, cornerCut - 7)).cgPath
            innerBorder.fillColor = UIColor.clear.cgColor
            innerBorder.strokeColor = accent.withAlphaComponent(0.30).cgColor
            innerBorder.lineWidth = 1.5
            view.layer.addSublayer(innerBorder)
        }
        
        view.layer.shadowColor = accent.withAlphaComponent(0.30).cgColor
        view.layer.shadowOpacity = 1.0
        view.layer.shadowRadius = 14
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowPath = fillPath.cgPath
    }
    
    func beveledPath(in rect: CGRect, cut: CGFloat) -> UIBezierPath {
        let bevel = min(cut, min(rect.width, rect.height) * 0.3)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + bevel, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - bevel, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + bevel))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bevel))
        path.addLine(to: CGPoint(x: rect.maxX - bevel, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + bevel, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - bevel))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + bevel))
        path.close()
        return path
    }
    
    func styleAnswerButton(_ button: UIButton, accent: UIColor, fillColors: [UIColor]) {
        applyArcadePanelStyle(
            to: button,
            accent: accent,
            fillColors: fillColors,
            cornerCut: 14
        )
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.48), for: .disabled)
        button.titleLabel?.font = UIFont.orbitronBold(size: 30)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
    }
    
    func styleSmallPanelButton(_ button: UIButton, title: String, accent: UIColor) {
        applyArcadePanelStyle(
            to: button,
            accent: accent,
            fillColors: [arcadePanelSoft, arcadePanel],
            cornerCut: 12
        )
        button.setTitle(title.uppercased(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.48), for: .disabled)
        button.titleLabel?.font = UIFont.exo2SemiBold(size: 13)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
    }
    
    func configureAssetPreview(
        on sceneView: SCNView,
        modelName: String,
        scale: Float,
        cameraZ: Float,
        yRotation: Float,
        isDimmed: Bool = false,
        rotationDuration: Double? = nil
    ) {
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = false
        sceneView.isUserInteractionEnabled = false
        sceneView.scene = nil
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.44, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.color = UIColor(red: 1.0, green: 0.82, blue: 0.62, alpha: 1.0)
        keyLight.position = SCNVector3(x: 4, y: 6, z: 8)
        scene.rootNode.addChildNode(keyLight)
        
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .omni
        fillLight.light?.color = UIColor(red: 0.66, green: 0.80, blue: 0.97, alpha: 0.75)
        fillLight.position = SCNVector3(x: -5, y: 2, z: 5)
        scene.rootNode.addChildNode(fillLight)
        
        if let assetScene = SCNScene(named: "art.scnassets/\(modelName)") {
            let assetNode = SCNNode()
            for child in assetScene.rootNode.childNodes {
                assetNode.addChildNode(child)
            }
            
            assetNode.scale = SCNVector3(x: scale, y: scale, z: scale)
            assetNode.eulerAngles = SCNVector3(x: 0.12, y: yRotation, z: 0)
            scene.rootNode.addChildNode(assetNode)
            
            if isDimmed {
                assetNode.enumerateChildNodes { node, _ in
                    node.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.16, alpha: 1.0)
                    node.geometry?.firstMaterial?.emission.contents = UIColor.black
                    node.geometry?.firstMaterial?.specular.contents = UIColor.black
                    node.geometry?.firstMaterial?.lightingModel = .constant
                }
            }
            
            if let rotationDuration {
                let rotateAction = SCNAction.repeatForever(
                    SCNAction.rotateBy(x: 0, y: 0.8, z: 0, duration: rotationDuration)
                )
                assetNode.runAction(rotateAction)
            }
        }
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 38
        cameraNode.position = SCNVector3(x: 0, y: 0.2, z: cameraZ)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func updateMissionLabels() {
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
        
        sceneView.showsStatistics = false
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = false
        sceneView.backgroundColor = .black
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSceneTap(_:)))
        sceneView.addGestureRecognizer(tapRecognizer)
        
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
        
        spaceship.position = SCNVector3(x: 0, y: -2.25, z: 0)
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
        leftEngineNode.position = SCNVector3(x: -0.28, y: 0.08, z: -1.25)
        leftEngineNode.addParticleSystem(leftFlame)
        spaceship.addChildNode(leftEngineNode)
        
        // Right engine flame
        let rightFlame = createFlameParticles()
        let rightEngineNode = SCNNode()
        rightEngineNode.position = SCNVector3(x: 0.28, y: 0.08, z: -1.25)
        rightEngineNode.addParticleSystem(rightFlame)
        spaceship.addChildNode(rightEngineNode)
    }
    
    func createFlameParticles() -> SCNParticleSystem {
        let particles = SCNParticleSystem()
        particles.birthRate = 220
        particles.particleLifeSpan = 0.16
        particles.particleLifeSpanVariation = 0.03
        particles.particleSize = 0.016
        particles.particleSizeVariation = 0.006
        particles.emitterShape = SCNSphere(radius: 0.018)
        particles.particleColor = UIColor.cyan.withAlphaComponent(0.94)
        particles.particleColorVariation = SCNVector4(x: 0.06, y: 0.18, z: 0.30, w: 0)
        particles.blendMode = .additive
        particles.particleVelocity = 3.8
        particles.particleVelocityVariation = 0.35
        particles.acceleration = SCNVector3(x: 0, y: 0, z: 1.1)
        particles.emittingDirection = SCNVector3(x: 0, y: 0, z: -1)
        particles.spreadingAngle = 6
        
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


    func midpoint(from start: SCNVector3, to end: SCNVector3) -> SCNVector3 {
        SCNVector3(
            x: (start.x + end.x) / 2,
            y: (start.y + end.y) / 2,
            z: (start.z + end.z) / 2
        )
    }

    func distance(from start: SCNVector3, to end: SCNVector3) -> CGFloat {
        let dx = CGFloat(end.x - start.x)
        let dy = CGFloat(end.y - start.y)
        let dz = CGFloat(end.z - start.z)
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    func layoutStatusMetrics() {
        let horizontalPadding: CGFloat = 8
        let columnSpacing: CGFloat = 6
        let columnWidth = (statusPanel.bounds.width - horizontalPadding * 2 - columnSpacing) / 2
        let leftX = horizontalPadding
        let rightX = leftX + columnWidth + columnSpacing
        let titleHeight: CGFloat = 12
        let valueHeight: CGFloat = 36
        let metricGap: CGFloat = 4
        let contentHeight = titleHeight + metricGap + valueHeight
        let startY = floor((statusPanel.bounds.height - contentHeight) / 2)
        
        streakTitleLabel.frame = CGRect(x: leftX, y: startY, width: columnWidth, height: titleHeight)
        streakLabel.frame = CGRect(x: leftX, y: startY + titleHeight + metricGap, width: columnWidth, height: valueHeight)
        answersRightTitleLabel.frame = CGRect(x: rightX, y: startY, width: columnWidth, height: titleHeight)
        answersRightLabel.frame = CGRect(x: rightX, y: startY + titleHeight + metricGap, width: columnWidth, height: valueHeight)
    }
    
    func applyMetricValue(_ value: Int, to label: UILabel, accent: UIColor) {
        let text = "\(value)"
        let fontSize: CGFloat
        
        switch text.count {
        case 0...2:
            fontSize = 28
        case 3:
            fontSize = 22
        case 4:
            fontSize = 18
        default:
            fontSize = 16
        }
        
        label.font = UIFont.orbitronBold(size: fontSize)
        label.textColor = accent
        label.text = text
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
        let topInset = max(view.safeAreaInsets.top, 20)
        let panelHeight: CGFloat = 104
        let topPanelY = topInset + 18
        
        livesContainer = UIView(frame: CGRect(x: 16, y: topPanelY, width: 188, height: panelHeight))
        // No background panel styling
        view.addSubview(livesContainer)
        
        hullStatusLabel = UILabel(frame: CGRect(x: 16, y: 14, width: 84, height: 18))
        hullStatusLabel.font = UIFont.orbitronMedium(size: 14)
        hullStatusLabel.textColor = arcadeSignalBright
        hullStatusLabel.text = "SHIPS"
        hullStatusLabel.adjustsFontSizeToFitWidth = true
        hullStatusLabel.minimumScaleFactor = 0.8
        livesContainer.addSubview(hullStatusLabel)

        exitButton = UIButton(frame: CGRect(x: view.bounds.width - 40 - 16, y: topInset + 4, width: 40, height: 40))
        exitButton.setTitle("✕", for: .normal)
        exitButton.setTitleColor(.white, for: .normal)
        exitButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .light)
        exitButton.addTarget(self, action: #selector(exitGame), for: .touchUpInside)
        view.addSubview(exitButton)
        
        // Hidden debug button in top-left to trigger mission complete
        let debugButton = UIButton(frame: CGRect(x: 16, y: topInset + 4, width: 60, height: 60))
        debugButton.backgroundColor = .clear
        debugButton.addTarget(self, action: #selector(debugCompleteMission), for: .touchUpInside)
        view.addSubview(debugButton)
        
        statusPanel = UIView(frame: CGRect(x: view.bounds.width - 168, y: topPanelY, width: 152, height: panelHeight))
        // No background panel styling
        view.addSubview(statusPanel)
        
        streakTitleLabel = UILabel(frame: CGRect(x: 12, y: 10, width: statusPanel.bounds.width - 24, height: 12))
        streakTitleLabel.text = "STREAK"
        streakTitleLabel.font = UIFont.exo2SemiBold(size: 10)
        streakTitleLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        streakTitleLabel.textAlignment = .center
        statusPanel.addSubview(streakTitleLabel)
        
        streakLabel = UILabel(frame: CGRect(x: 12, y: 30, width: statusPanel.bounds.width - 24, height: 36))
        streakLabel.textAlignment = .center
        streakLabel.font = UIFont.orbitronBold(size: 28)
        streakLabel.textColor = arcadeSignalBright
        streakLabel.adjustsFontSizeToFitWidth = true
        streakLabel.minimumScaleFactor = 0.45
        statusPanel.addSubview(streakLabel)
        
        answersRightTitleLabel = UILabel(frame: CGRect(x: 12, y: 56, width: statusPanel.bounds.width - 24, height: 12))
        answersRightTitleLabel.text = "TOTAL"
        answersRightTitleLabel.font = UIFont.exo2SemiBold(size: 10)
        answersRightTitleLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        answersRightTitleLabel.textAlignment = .center
        statusPanel.addSubview(answersRightTitleLabel)
        
        answersRightLabel = UILabel(frame: CGRect(x: 12, y: 30, width: statusPanel.bounds.width - 24, height: 36))
        answersRightLabel.textAlignment = .center
        answersRightLabel.font = UIFont.orbitronBold(size: 28)
        answersRightLabel.textColor = arcadeCool
        answersRightLabel.adjustsFontSizeToFitWidth = true
        answersRightLabel.minimumScaleFactor = 0.45
        statusPanel.addSubview(answersRightLabel)
        layoutStatusMetrics()
        updateStreakDisplay()
        
        questionPanel = UIView(frame: CGRect(x: 16, y: livesContainer.frame.maxY + 22, width: view.bounds.width - 32, height: 112))
        applyArcadePanelStyle(
            to: questionPanel,
            accent: arcadeSignalBright,
            fillColors: [arcadePanelSoft, arcadePanel],
            cornerCut: 20
        )
        view.addSubview(questionPanel)
        
        questionLabel = UILabel(frame: CGRect(x: 18, y: 24, width: questionPanel.bounds.width - 36, height: 60))
        questionLabel.textAlignment = .center
        questionLabel.font = UIFont.orbitronBold(size: 44)
        questionLabel.textColor = .white
        questionLabel.adjustsFontSizeToFitWidth = true
        questionLabel.minimumScaleFactor = 0.7
        questionPanel.addSubview(questionLabel)
        
        // Legacy buttons are kept hidden so the old button flow stays inert while meteor tapping drives gameplay.
        let maxButtons = 4
        
        for i in 0..<maxButtons {
            let button = UIButton(frame: .zero)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.orbitronBold(size: 30)
            button.tag = i
            button.addTarget(self, action: #selector(answerTapped(_:)), for: .touchUpInside)
            styleAnswerButton(
                button,
                accent: arcadeCool,
                fillColors: [arcadeCool.withAlphaComponent(0.42), arcadePanelSoft]
            )
            button.isHidden = true
            view.addSubview(button)
            answerButtons.append(button)
        }
        answerButtons.forEach {
            $0.isEnabled = false
            $0.alpha = 0
        }
        
        layoutGameplayHUD()
        setupLivesDisplay()
        setupMalfunctionOverlay()
    }
    
    func layoutGameplayHUD() {
        let sideInset: CGFloat = 16
        let topInset = max(view.safeAreaInsets.top, 20)
        let topPanelY = topInset + 18
        let topPanelHeight: CGFloat = 104
        let questionPanelHeight: CGFloat = 112
        
        livesContainer.frame = CGRect(x: sideInset, y: topPanelY, width: 188, height: topPanelHeight)
        statusPanel.frame = CGRect(x: view.bounds.width - sideInset - 152, y: topPanelY, width: 152, height: topPanelHeight)
        questionPanel.frame = CGRect(
            x: sideInset,
            y: livesContainer.frame.maxY + 22,
            width: view.bounds.width - sideInset * 2,
            height: questionPanelHeight
        )
        
        // No background styling for lives and stats panels
        applyArcadePanelStyle(
            to: questionPanel,
            accent: arcadeSignalBright,
            fillColors: [arcadePanelSoft, arcadePanel],
            cornerCut: 20
        )
        
        hullStatusLabel.frame = CGRect(x: 16, y: 14, width: 84, height: 18)
        exitButton.frame = CGRect(x: view.bounds.width - 40 - 16, y: topInset + 4, width: 40, height: 40)
        layoutStatusMetrics()
        questionLabel.frame = CGRect(x: 18, y: 24, width: questionPanel.bounds.width - 36, height: 60)
        layoutMalfunctionOverlay()
    }
    
    func layoutAnswerButtons(for optionCount: Int) {
        return
    }

    func setupMalfunctionOverlay() {
        malfunctionOverlay = UIView(frame: .zero)
        malfunctionOverlay.alpha = 0
        malfunctionOverlay.isHidden = true
        applyArcadePanelStyle(
            to: malfunctionOverlay,
            accent: arcadeDanger,
            fillColors: [arcadePanelSoft, UIColor.black.withAlphaComponent(0.95)],
            cornerCut: 24
        )
        view.addSubview(malfunctionOverlay)

        malfunctionTitleLabel = UILabel(frame: .zero)
        malfunctionTitleLabel.text = "RED ALERT"
        malfunctionTitleLabel.font = UIFont.orbitronBold(size: 28)
        malfunctionTitleLabel.textColor = arcadeDanger
        malfunctionTitleLabel.textAlignment = .center
        malfunctionOverlay.addSubview(malfunctionTitleLabel)

        malfunctionStatusLabel = UILabel(frame: .zero)
        malfunctionStatusLabel.text = "SHIP MALFUNCTION"
        malfunctionStatusLabel.font = UIFont.exo2SemiBold(size: 13)
        malfunctionStatusLabel.textColor = .white
        malfunctionStatusLabel.textAlignment = .center
        malfunctionOverlay.addSubview(malfunctionStatusLabel)

        repairPromptLabel = UILabel(frame: .zero)
        repairPromptLabel.font = UIFont.orbitronBold(size: 30)
        repairPromptLabel.textColor = arcadeSignalBright
        repairPromptLabel.textAlignment = .center
        repairPromptLabel.adjustsFontSizeToFitWidth = true
        repairPromptLabel.minimumScaleFactor = 0.7
        malfunctionOverlay.addSubview(repairPromptLabel)

        repairInputLabel = UILabel(frame: .zero)
        repairInputLabel.font = UIFont.orbitronBold(size: 32)
        repairInputLabel.textColor = arcadeSignalBright
        repairInputLabel.textAlignment = .center
        repairInputLabel.text = "?"
        repairInputLabel.alpha = 0
        malfunctionOverlay.addSubview(repairInputLabel)

        systemsRestoredLabel = UILabel(frame: .zero)
        systemsRestoredLabel.font = UIFont.orbitronBold(size: 24)
        systemsRestoredLabel.textColor = arcadeSuccess
        systemsRestoredLabel.textAlignment = .center
        systemsRestoredLabel.text = "SYSTEMS RESTORED"
        systemsRestoredLabel.alpha = 0
        malfunctionOverlay.addSubview(systemsRestoredLabel)

        let keypadTitles = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "⌫"]
        for title in keypadTitles {
            let button = UIButton(type: .system)
            applyArcadePanelStyle(
                to: button,
                accent: title == "⌫" ? arcadeDanger : arcadeCool,
                fillColors: [arcadePanelSoft, arcadePanel],
                cornerCut: 16
            )
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.orbitronBold(size: 28)
            button.addTarget(self, action: #selector(repairKeyTapped(_:)), for: .touchUpInside)
            malfunctionOverlay.addSubview(button)
            repairKeypadButtons.append(button)
        }

        repairConfirmButton = UIButton(type: .system)
        applyArcadePanelStyle(
            to: repairConfirmButton,
            accent: arcadeDanger,
            fillColors: [arcadeDanger.withAlphaComponent(0.92), arcadeSignal.withAlphaComponent(0.78)],
            cornerCut: 18
        )
        repairConfirmButton.setTitle("FIX SHIP", for: .normal)
        repairConfirmButton.setTitleColor(.white, for: .normal)
        repairConfirmButton.titleLabel?.font = UIFont.orbitronBold(size: 24)
        repairConfirmButton.addTarget(self, action: #selector(confirmRepairAttempt), for: .touchUpInside)
        malfunctionOverlay.addSubview(repairConfirmButton)
    }

    func layoutMalfunctionOverlay() {
        guard malfunctionOverlay != nil else { return }

        let top = questionPanel?.frame.minY ?? 0
        let bottom = view.bounds.height - max(view.safeAreaInsets.bottom, 12) - 12
        malfunctionOverlay.frame = CGRect(x: 16, y: top, width: view.bounds.width - 32, height: bottom - top)
        applyArcadePanelStyle(
            to: malfunctionOverlay,
            accent: arcadeDanger,
            fillColors: [arcadePanelSoft, UIColor.black.withAlphaComponent(0.95)],
            cornerCut: 24
        )

        malfunctionTitleLabel.frame = CGRect(x: 18, y: 18, width: malfunctionOverlay.bounds.width - 36, height: 34)
        malfunctionStatusLabel.frame = CGRect(x: 18, y: 54, width: malfunctionOverlay.bounds.width - 36, height: 18)
        repairPromptLabel.frame = CGRect(x: 18, y: 86, width: malfunctionOverlay.bounds.width - 36, height: 42)
        repairInputLabel.frame = CGRect(x: 18, y: 132, width: malfunctionOverlay.bounds.width - 36, height: 40)
        systemsRestoredLabel.frame = CGRect(x: 18, y: 132, width: malfunctionOverlay.bounds.width - 36, height: 40)

        let keypadTop: CGFloat = 188
        let horizontalPadding: CGFloat = 28
        let keypadSpacing: CGFloat = 12
        let buttonWidth = (malfunctionOverlay.bounds.width - horizontalPadding * 2 - keypadSpacing * 2) / 3
        let buttonHeight: CGFloat = 54

        for (index, button) in repairKeypadButtons.enumerated() {
            if index < 9 {
                let row = index / 3
                let column = index % 3
                button.frame = CGRect(
                    x: horizontalPadding + CGFloat(column) * (buttonWidth + keypadSpacing),
                    y: keypadTop + CGFloat(row) * (buttonHeight + keypadSpacing),
                    width: buttonWidth,
                    height: buttonHeight
                )
            } else if index == 9 {
                button.frame = CGRect(
                    x: horizontalPadding + buttonWidth + keypadSpacing,
                    y: keypadTop + 3 * (buttonHeight + keypadSpacing),
                    width: buttonWidth,
                    height: buttonHeight
                )
            } else {
                button.frame = CGRect(
                    x: horizontalPadding + 2 * (buttonWidth + keypadSpacing),
                    y: keypadTop + 3 * (buttonHeight + keypadSpacing),
                    width: buttonWidth,
                    height: buttonHeight
                )
            }

            applyArcadePanelStyle(
                to: button,
                accent: button.title(for: .normal) == "⌫" ? arcadeDanger : arcadeCool,
                fillColors: [arcadePanelSoft, arcadePanel],
                cornerCut: 16
            )
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.orbitronBold(size: 28)
        }

        repairConfirmButton.frame = CGRect(
            x: horizontalPadding,
            y: keypadTop + 4 * (buttonHeight + keypadSpacing) + 4,
            width: malfunctionOverlay.bounds.width - horizontalPadding * 2,
            height: 62
        )
        applyArcadePanelStyle(
            to: repairConfirmButton,
            accent: arcadeDanger,
            fillColors: [arcadeDanger.withAlphaComponent(0.92), arcadeSignal.withAlphaComponent(0.78)],
            cornerCut: 18
        )
        repairConfirmButton.setTitleColor(.white, for: .normal)
        repairConfirmButton.titleLabel?.font = UIFont.orbitronBold(size: 24)
    }
    
    func setupLivesDisplay() {
        liveCraftNodes.forEach { $0.superview?.removeFromSuperview() }
        liveCraftNodes.removeAll()
        
        let craftSize: CGFloat = 42
        let spacing: CGFloat = 10
        let startX: CGFloat = 16
        let yPosition: CGFloat = 46
        
        for i in 0..<3 {
            let cardFrame = CGRect(
                x: startX + CGFloat(i) * (craftSize + spacing),
                y: yPosition,
                width: craftSize,
                height: craftSize
            )
            let lifeView = UIView(frame: cardFrame)
            applyArcadePanelStyle(
                to: lifeView,
                accent: arcadeSignal,
                fillColors: [arcadePanelSoft, arcadePanel],
                cornerCut: 12
            )
            
            let previewView = SCNView(frame: lifeView.bounds.insetBy(dx: 4, dy: 4))
            configureAssetPreview(
                on: previewView,
                modelName: selectedShipModel,
                scale: 0.44,
                cameraZ: 2.6,
                yRotation: Float.pi / 4,
                rotationDuration: 9
            )
            lifeView.addSubview(previewView)
            
            livesContainer.addSubview(lifeView)
            previewView.tag = i
            liveCraftNodes.append(previewView)
            lifeView.tag = 1000 + i
        }
        
        updateLivesDisplay()
    }
    
    func generateMathQuestion() -> (question: String, answer: Int, options: [Int]) {
        var question: String
        var answer: Int
        var num1: Int
        var num2: Int
        
        // Check if using custom problems
        if !customProblems.isEmpty {
            let problemString = customProblems.randomElement() ?? ArithmeticMode.multiplication.practiceKey(lhs: 2, rhs: 3)
            if let customProblem = parsedProblem(from: problemString) {
                num1 = customProblem.lhs
                num2 = customProblem.rhs
                switch customProblem.mode {
                case .multiplication:
                    answer = num1 * num2
                    question = "\(num1) × \(num2) = ?"
                case .division:
                    let dividend = num1 * num2
                    answer = num1
                    question = "\(dividend) ÷ \(num2) = ?"
                }
            } else {
                num1 = 2
                num2 = 3
                answer = 6
                question = "2 × 3 = ?"
            }
        } else {
            // Keep generating until we get a different question
            repeat {
                num2 = selectedTables.randomElement() ?? 2
                num1 = Int.random(in: 1...12)
                switch arithmeticMode {
                case .multiplication:
                    answer = num1 * num2
                    question = "\(num1) × \(num2) = ?"
                case .division:
                    let dividend = num1 * num2
                    answer = num1
                    question = "\(dividend) ÷ \(num2) = ?"
                }
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

    private func parsedProblem(from problemString: String) -> (mode: ArithmeticMode, lhs: Int, rhs: Int)? {
        let compactProblem = problemString.replacingOccurrences(of: " ", with: "")
        if compactProblem.contains("×") {
            let parts = compactProblem.split(separator: "×")
            if parts.count == 2, let lhs = Int(parts[0]), let rhs = Int(parts[1]) {
                return (.multiplication, lhs, rhs)
            }
        }

        if compactProblem.contains("÷") {
            let parts = compactProblem.split(separator: "÷")
            if parts.count == 2, let lhs = Int(parts[0]), let rhs = Int(parts[1]) {
                return (.division, lhs, rhs)
            }
        }

        return nil
    }

    func generateRepairQuestion() -> (question: String, answer: Int) {
        let prompt = generateMathQuestion()
        return (prompt.question, prompt.answer)
    }

    func clearActiveMeteorEncounter() {
        let lingeringChoices = activeMeteorChoices
        activeMeteorChoices.removeAll()
        meteor = nil
        lingeringChoices.forEach { choice in
            choice.node.removeAction(forKey: "meteor.flight")
            choice.node.removeAction(forKey: "meteor.escape")
            choice.node.removeAction(forKey: "meteor.nearMiss")
            choice.node.childNode(withName: "meteor.body", recursively: false)?.removeAction(forKey: "meteor.spin")
            choice.node.removeFromParentNode()
        }
        hasResolvedCurrentEncounter = false
    }

    func createMeteorNode(at laneX: Float, answerValue: Int, isCorrect: Bool) -> SCNNode? {
        guard let meteorScene = SCNScene(named: "art.scnassets/meteor_detailed.dae") else {
            print("Could not load meteor_detailed.dae")
            return nil
        }

        let rootNode = SCNNode()
        rootNode.name = isCorrect ? "meteor.correct" : "meteor.wrong"
        rootNode.position = SCNVector3(x: laneX, y: 1.2, z: -30)
        rootNode.scale = SCNVector3(x: 0.3, y: 0.3, z: 0.3)

        let meteorVisual = SCNNode()
        meteorVisual.name = "meteor.body"
        for child in meteorScene.rootNode.childNodes {
            meteorVisual.addChildNode(child.clone())
        }
        meteorVisual.scale = SCNVector3(x: 0.94, y: 0.94, z: 0.94)
        rootNode.addChildNode(meteorVisual)

        // Add invisible tap area box for easier tapping
        let tapAreaSize: CGFloat = 2.5  // Larger hitbox
        let tapArea = SCNBox(width: tapAreaSize, height: tapAreaSize, length: tapAreaSize, chamferRadius: 0)
        tapArea.firstMaterial?.diffuse.contents = UIColor.clear
        tapArea.firstMaterial?.isDoubleSided = true
        let tapAreaNode = SCNNode(geometry: tapArea)
        tapAreaNode.name = "meteor.tapArea"
        rootNode.addChildNode(tapAreaNode)
        
        let labelAnchor = SCNNode()
        labelAnchor.name = "meteor.labelAnchor"
        rootNode.addChildNode(labelAnchor)

        let shadowText = SCNText(string: "\(answerValue)", extrusionDepth: 0.1)
        shadowText.font = UIFont.orbitronBold(size: 1.9)
        shadowText.flatness = 0.2
        shadowText.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.85)
        shadowText.firstMaterial?.emission.contents = UIColor.black
        let shadowNode = SCNNode(geometry: shadowText)
        let shadowBounds = shadowText.boundingBox
        shadowNode.scale = SCNVector3(x: 0.3, y: 0.3, z: 0.3)
        shadowNode.position = SCNVector3(
            x: -((shadowBounds.max.x - shadowBounds.min.x) * 0.3) / 2 + 0.08,
            y: 0.02,
            z: 1.26
        )
        shadowNode.opacity = 0
        labelAnchor.addChildNode(shadowNode)

        let answerText = SCNText(string: "\(answerValue)", extrusionDepth: 0.08)
        answerText.font = UIFont.orbitronBold(size: 1.9)
        answerText.flatness = 0.2
        answerText.firstMaterial?.diffuse.contents = UIColor.white
        answerText.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.18)
        answerText.firstMaterial?.lightingModel = .constant  // Ignore lighting, always show full color
        let answerNode = SCNNode(geometry: answerText)
        let answerBounds = answerText.boundingBox
        answerNode.name = "meteor.label"
        answerNode.scale = SCNVector3(x: 0.3, y: 0.3, z: 0.3)
        answerNode.position = SCNVector3(
            x: -((answerBounds.max.x - answerBounds.min.x) * 0.3) / 2,
            y: 0.08,
            z: 1.32
        )
        answerNode.opacity = 0
        labelAnchor.addChildNode(answerNode)

        let pulseUp = SCNAction.scale(to: 1.0, duration: 0.26)
        pulseUp.timingMode = .easeOut
        rootNode.runAction(pulseUp) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.14
            shadowNode.opacity = 1
            answerNode.opacity = 1
            SCNTransaction.commit()
        }

        return rootNode
    }

    func sendUntappedMeteorsPastShip(excluding preservedNode: SCNNode? = nil, duration: TimeInterval = 0.38) {
        for choice in activeMeteorChoices where choice.node !== preservedNode {
            choice.node.removeAction(forKey: "meteor.flight")
            choice.node.removeAction(forKey: "meteor.nearMiss")
            let driftX: Float = choice.laneX >= 0 ? 1.8 : -1.8
            let escape = SCNAction.group([
                SCNAction.move(by: SCNVector3(x: driftX, y: 0.45, z: 16), duration: duration),
                SCNAction.fadeOut(duration: duration)
            ])
            choice.node.runAction(.sequence([escape, .removeFromParentNode()]), forKey: "meteor.escape")
        }
    }

    func animateWrongMeteorNearMiss(_ choice: MeteorChoice, completion: @escaping () -> Void) {
        choice.node.removeAction(forKey: "meteor.flight")
        choice.node.removeAction(forKey: "meteor.escape")
        let passX = choice.laneX * 0.55
        let dive = SCNAction.move(to: SCNVector3(x: passX, y: -2.4, z: 1.1), duration: 0.42)
        dive.timingMode = .easeIn
        let slideAway = SCNAction.group([
            SCNAction.move(by: SCNVector3(x: choice.laneX >= 0 ? 1.3 : -1.3, y: -0.1, z: 6.0), duration: 0.34),
            SCNAction.fadeOut(duration: 0.32)
        ])
        choice.node.runAction(.sequence([dive, slideAway, .removeFromParentNode()]), forKey: "meteor.nearMiss") {
            completion()
        }
    }

    func animateWrongMeteorFlyBy(_ choice: MeteorChoice, completion: (() -> Void)? = nil) {
        choice.node.removeAction(forKey: "meteor.flight")
        choice.node.removeAction(forKey: "meteor.escape")
        let passX = choice.laneX >= 0 ? choice.laneX + 1.0 : choice.laneX - 1.0
        let dive = SCNAction.move(to: SCNVector3(x: passX, y: -2.35, z: 0.9), duration: 0.3)
        dive.timingMode = .easeIn
        let streakAway = SCNAction.group([
            SCNAction.move(by: SCNVector3(x: choice.laneX >= 0 ? 1.7 : -1.7, y: -0.08, z: 7.2), duration: 0.24),
            SCNAction.fadeOut(duration: 0.2)
        ])
        choice.node.runAction(.sequence([dive, streakAway, .removeFromParentNode()]), forKey: "meteor.escape") {
            completion?()
        }
    }

    func performShipDodgeRun(to laneX: Float, completion: (() -> Void)? = nil) {
        let moveToLane = SCNAction.move(to: SCNVector3(x: laneX, y: -2.25, z: 0), duration: 0.28)
        moveToLane.timingMode = .easeInEaseOut
        let bank = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat(-laneX * 0.12), duration: 0.18)
        let level = SCNAction.rotateTo(x: 0, y: CGFloat(Float.pi), z: 0, duration: 0.18, usesShortestUnitArc: true)
        let surgeForward = SCNAction.move(to: SCNVector3(x: laneX, y: -2.05, z: -1.35), duration: 0.22)
        surgeForward.timingMode = .easeOut
        let settleBack = SCNAction.move(to: SCNVector3(x: laneX, y: -2.25, z: 0), duration: 0.24)
        settleBack.timingMode = .easeInEaseOut
        spaceship.runAction(.sequence([
            .group([moveToLane, bank]),
            .group([surgeForward, level]),
            settleBack
        ])) {
            completion?()
        }
    }

    func explodeMeteorNode(_ node: SCNNode, fragmentCount: Int = 6, dramatic: Bool = false) {
        let meteorPosition = node.presentation.position
        AudioManager.shared.playMeteorExplosion()
        node.removeAction(forKey: "meteor.flight")
        node.removeAction(forKey: "meteor.escape")
        node.removeAction(forKey: "meteor.nearMiss")
        node.childNode(withName: "meteor.body", recursively: false)?.removeAction(forKey: "meteor.spin")
        node.removeFromParentNode()

        for _ in 0..<fragmentCount {
            if let meteorHalfScene = SCNScene(named: "art.scnassets/meteor_half.dae") {
                let fragment = SCNNode()
                for child in meteorHalfScene.rootNode.childNodes {
                    fragment.addChildNode(child.clone())
                }

                let scale: Float = dramatic ? 0.34 : 0.28
                fragment.scale = SCNVector3(x: scale, y: scale, z: scale)
                fragment.position = meteorPosition
                gameScene.rootNode.addChildNode(fragment)

                let randomX = Float.random(in: dramatic ? -5...5 : -4...4)
                let randomY = Float.random(in: dramatic ? -4...4 : -3...3)
                let randomZ = Float.random(in: dramatic ? -2...8 : 2...6)
                let moveAction = SCNAction.move(by: SCNVector3(x: randomX, y: randomY, z: randomZ), duration: dramatic ? 1.9 : 1.4)
                let rotateAction = SCNAction.rotateBy(
                    x: CGFloat.random(in: 0...10),
                    y: CGFloat.random(in: 0...10),
                    z: CGFloat.random(in: 0...10),
                    duration: dramatic ? 1.9 : 1.4
                )
                let fadeAction = SCNAction.fadeOut(duration: dramatic ? 1.5 : 1.1)
                fragment.runAction(.sequence([.group([moveAction, rotateAction, fadeAction]), .removeFromParentNode()]))
            }
        }
    }

    func resolveShipDamage(at impactPosition: SCNVector3) {
        guard !isEndingSession else { return }

        lives -= 1
        updateLivesDisplay()
        currentStreak = 0
        updateStreakDisplay()

        if let impactMeteor = activeMeteorChoices.first(where: { $0.node.parent != nil })?.node {
            explodeMeteorNode(impactMeteor, fragmentCount: 8, dramatic: true)
        } else {
            let impactNode = SCNNode()
            impactNode.position = impactPosition
            gameScene.rootNode.addChildNode(impactNode)
            explodeMeteorNode(impactNode, fragmentCount: 8, dramatic: true)
        }

        clearActiveMeteorEncounter()

        if lives > 0 {
            shakeShip()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.isResolvingTap = false
                self.spawnMeteorWithQuestion()
            }
        } else {
            explodeShip()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isResolvingTap = false
                self.showGameOver()
            }
        }
    }

    func node(_ candidate: SCNNode, belongsTo root: SCNNode) -> Bool {
        var current: SCNNode? = candidate
        while let node = current {
            if node == root {
                return true
            }
            current = node.parent
        }
        return false
    }

    @objc func handleSceneTap(_ recognizer: UITapGestureRecognizer) {
        guard !isEndingSession, !isInMalfunctionMode, !hasResolvedCurrentEncounter, !isResolvingTap else { return }
        guard !activeMeteorChoices.isEmpty else { return }

        let location = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
        ])
        guard let hitNode = hitResults.first?.node else { return }
        guard let selectedChoice = activeMeteorChoices.first(where: { choice in
            node(hitNode, belongsTo: choice.node)
        }) else { return }


        if selectedChoice.isCorrect {
            isResolvingTap = true
            hasResolvedCurrentEncounter = true
            totalMeteorsDestroyed += 1
            currentStreak += 1
            topScore = max(topScore, currentStreak)
            recordCorrectAnswer(for: currentQuestionText, firstTry: true)
            firstAttemptCorrect += 1
            let problemKey = normalizedProblemKey(from: currentQuestionText)
            perfectProblems[problemKey, default: 0] += 1
            updateStreakDisplay()

            // Move ship to meteor position first
            currentPosition = selectedChoice.laneX
            let quickMove = SCNAction.move(to: SCNVector3(x: selectedChoice.laneX, y: -2.25, z: 0), duration: 0.2)
            quickMove.timingMode = .easeInEaseOut
            spaceship.runAction(quickMove) {
                // Then shoot laser after ship is in position
                self.shootLaser(at: selectedChoice.node) {
                    self.explodeMeteorNode(selectedChoice.node)
                    self.sendUntappedMeteorsPastShip(excluding: selectedChoice.node, duration: 0.42)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        self.isResolvingTap = false
                        self.clearActiveMeteorEncounter()
                        if self.hasMasteredReplayProblemSet() {
                            self.completeReplaySession()
                        } else if self.shouldTriggerMalfunctionAfterCurrentWave() {
                            self.beginMalfunctionSequence()
                        } else if !self.isReplaySession && self.questionNumber >= self.missionQuestionLimit {
                            self.completeMission()
                        } else {
                            self.spawnMeteorWithQuestion()
                        }
                    }
                }
            }
        } else {
            if difficulty == .easy {
                markQuestionForRetryIfNeeded(currentQuestionText)
            }
            if difficulty == .easy && attemptsLeft > 1 {
                isResolvingTap = true
                attemptsLeft -= 1
                activeMeteorChoices.removeAll { $0.node == selectedChoice.node }
                meteor = activeMeteorChoices.first(where: { $0.isCorrect })?.node
                
                // Reset timeout - give more time for second attempt
                meteorTimeoutWork?.cancel()
                let newWork = DispatchWorkItem { [weak self] in
                    self?.handleMeteorTimeout()
                }
                meteorTimeoutWork = newWork
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.25, execute: newWork)
                
                animateWrongMeteorNearMiss(selectedChoice) {
                    self.isResolvingTap = false
                }
                
                // Perform barrel roll to dodge, delayed to sync with near-miss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    let barrelRoll = SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 2, duration: 0.4)
                    barrelRoll.timingMode = .easeInEaseOut
                    self.spaceship.runAction(barrelRoll)
                }
                
                return
            }

            isResolvingTap = true
            hasResolvedCurrentEncounter = true
            missedQuestions.append(currentQuestionText)
            recordMiss(for: currentQuestionText)

            activeMeteorChoices.removeAll { $0.node == selectedChoice.node }

            let fallbackImpactNode = activeMeteorChoices
                .first(where: { $0.isCorrect && $0.node.parent != nil })?.node
                ?? activeMeteorChoices.first(where: { !$0.isCorrect && $0.node !== selectedChoice.node && $0.node.parent != nil })?.node

            let shipImpactPosition = self.spaceship.presentation.position
            self.currentPosition = shipImpactPosition.x
            self.animateWrongMeteorFlyBy(selectedChoice)
            self.sendUntappedMeteorsPastShip(excluding: fallbackImpactNode, duration: 0.24)

            if let fallbackImpactNode {
                activeMeteorChoices = activeMeteorChoices.filter { $0.node == fallbackImpactNode }
                meteor = fallbackImpactNode
                fallbackImpactNode.removeAction(forKey: "meteor.flight")
                fallbackImpactNode.removeAction(forKey: "meteor.escape")
                fallbackImpactNode.removeAction(forKey: "meteor.nearMiss")
                let impactMove = SCNAction.move(to: SCNVector3(x: shipImpactPosition.x, y: shipImpactPosition.y, z: shipImpactPosition.z), duration: 0.55)
                impactMove.timingMode = .easeIn
                fallbackImpactNode.runAction(impactMove, forKey: "meteor.impact") {
                    self.isResolvingTap = false
                    self.resolveShipDamage(at: fallbackImpactNode.presentation.position)
                }
            } else {
                activeMeteorChoices.removeAll()
                meteor = nil
                self.isResolvingTap = false
                self.resolveShipDamage(at: shipImpactPosition)
            }
        }
    }

    func shouldTriggerMalfunctionAfterCurrentWave() -> Bool {
        guard !isReplaySession else { return false }
        guard malfunctionTriggerWaves.contains(totalMeteorsDestroyed) else { return false }
        return !triggeredMalfunctionWaves.contains(totalMeteorsDestroyed)
    }

    func beginMalfunctionSequence() {
        guard !isInMalfunctionMode else { return }

        isInMalfunctionMode = true
        triggeredMalfunctionWaves.insert(totalMeteorsDestroyed)
        clearActiveMeteorEncounter()
        answerButtons.forEach {
            $0.isEnabled = false
            $0.alpha = 0
        }
        updateRepairPrompt()
        malfunctionOverlay.isHidden = false
        malfunctionOverlay.alpha = 0
        addArcadeBlinkAnimation(to: malfunctionTitleLabel, minimumOpacity: 0.2, duration: 0.4)
        addArcadeBlinkAnimation(to: repairConfirmButton, minimumOpacity: 0.45, duration: 0.45)
        startMalfunctionShipWeave()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard self.isInMalfunctionMode else { return }
            self.questionPanel.alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.malfunctionOverlay.alpha = 1.0
            }
        }
    }

    func endMalfunctionSequence() {
        isInMalfunctionMode = false
        malfunctionTitleLabel.layer.removeAnimation(forKey: "arcade.blink")
        repairConfirmButton.layer.removeAnimation(forKey: "arcade.blink")
        stopMalfunctionShipWeave()
        malfunctionOverlay.backgroundColor = .clear
        repairPromptLabel.alpha = 1.0
        spaceship.enumerateChildNodes { node, _ in
            node.geometry?.firstMaterial?.emission.contents = UIColor.black
        }
        UIView.animate(withDuration: 0.25, animations: {
            self.malfunctionOverlay.alpha = 0
        }) { _ in
            self.malfunctionOverlay.isHidden = true
            self.questionPanel.alpha = 1.0
            self.spawnMeteorWithQuestion()
        }
    }

    func updateRepairPrompt() {
        let prompt = generateRepairQuestion()
        repairPromptQuestion = prompt.question
        repairAnswer = prompt.answer
        repairInput = ""
        repairAttemptCountForCurrentPrompt = 0
        systemsRestoredLabel.alpha = 0
        updateRepairEquationDisplay()
        repairInputLabel.text = "?"
    }

    func awardRepairStars() {
        repairStarsEarned += repairStarAward
        _ = PlayerProfileStore.shared.awardStars(repairStarAward)
    }

    @objc func repairKeyTapped(_ sender: UIButton) {
        guard isInMalfunctionMode else { return }
        guard let title = sender.title(for: .normal) else { return }

        switch title {
        case "⌫":
            if !repairInput.isEmpty {
                repairInput.removeLast()
            }
        default:
            guard repairInput.count < 3 else { break }
            repairInput.append(title)
        }

        updateRepairEquationDisplay()
    }

    @objc func confirmRepairAttempt() {
        guard isInMalfunctionMode else { return }
        guard let enteredValue = Int(repairInput) else {
            updateRepairEquationDisplay()
            return
        }

        if enteredValue == repairAnswer {
            awardRepairStars()
            repairsCompleted += 1
            repairPromptLabel.alpha = 0
            systemsRestoredLabel.alpha = 0
            UIView.animate(withDuration: 0.18, animations: {
                self.systemsRestoredLabel.alpha = 1.0
                self.systemsRestoredLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.malfunctionOverlay.backgroundColor = self.arcadeSuccess.withAlphaComponent(0.12)
            }) { _ in
                UIView.animate(withDuration: 0.18) {
                    self.systemsRestoredLabel.transform = .identity
                }
            }
            spaceship.enumerateChildNodes { node, _ in
                node.geometry?.firstMaterial?.emission.contents = self.arcadeSuccess
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                self.endMalfunctionSequence()
            }
        } else {
            if repairAttemptCountForCurrentPrompt == 0 {
                repairReviewProblems.append(normalizedProblemKey(from: repairPromptQuestion))
            }
            repairAttemptCountForCurrentPrompt += 1
            repairPromptLabel.text = "WRONG"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.updateRepairPrompt()
            }
        }
    }

    func updateRepairEquationDisplay() {
        let basePrompt = repairPromptQuestion.replacingOccurrences(of: " = ?", with: " =")
        let answerDisplay = repairInput.isEmpty ? "?" : repairInput
        repairPromptLabel.text = "\(basePrompt) \(answerDisplay)"
        repairPromptLabel.alpha = 1.0
    }

    func startMalfunctionShipWeave() {
        spaceship.removeAction(forKey: "malfunction.weave")
        let positions: [SCNVector3] = [
            SCNVector3(x: -1.0, y: -1.95, z: 0),
            SCNVector3(x: 0.9, y: -2.7, z: 0),
            SCNVector3(x: -0.5, y: -2.95, z: 0),
            SCNVector3(x: 1.1, y: -2.15, z: 0),
            SCNVector3(x: 0.0, y: -2.25, z: 0)
        ]
        let rolls: [CGFloat] = [0.22, -0.26, 0.18, -0.2, 0.0]
        var actions: [SCNAction] = []
        for (index, position) in positions.enumerated() {
            let move = SCNAction.move(to: position, duration: 0.34)
            move.timingMode = .easeInEaseOut
            let rotate = SCNAction.rotateTo(x: 0, y: CGFloat(Float.pi), z: rolls[index], duration: 0.34, usesShortestUnitArc: true)
            rotate.timingMode = .easeInEaseOut
            actions.append(.group([move, rotate]))
        }
        spaceship.runAction(.repeatForever(.sequence(actions)), forKey: "malfunction.weave")
    }

    func stopMalfunctionShipWeave() {
        spaceship.removeAction(forKey: "malfunction.weave")
        let settleMove = SCNAction.move(to: SCNVector3(x: 0, y: -2.25, z: 0), duration: 0.22)
        settleMove.timingMode = .easeInEaseOut
        let settleRotate = SCNAction.rotateTo(x: 0, y: CGFloat(Float.pi), z: 0, duration: 0.22, usesShortestUnitArc: true)
        settleRotate.timingMode = .easeInEaseOut
        spaceship.runAction(.group([settleMove, settleRotate]))
    }
    
    func spawnMeteorWithQuestion() {
        guard !isEndingSession else { return }
        guard !isInMalfunctionMode else { return }
        guard isReplaySession || questionNumber < missionQuestionLimit else {
            completeMission()
            return
        }

        clearActiveMeteorEncounter()
        
        questionNumber += 1
        
        // Generate question
        let (question, answer, options) = generateMathQuestion()
        currentAnswer = answer
        currentQuestionText = question
        attemptsLeft = maxAttempts
        recordPresentedQuestion(question)
        DispatchQueue.main.async {
            guard !self.isEndingSession else { return }
            self.questionLabel.text = question
            self.questionPanel.alpha = 1.0
            self.answerButtons.forEach {
                $0.isEnabled = false
                $0.alpha = 0
                $0.isHidden = true
            }
        }
        let baseDuration = 6.0  // 6 seconds - comfortable but encourages quick thinking
        let speedIncrease: Double
        
        if questionNumber <= 24 {
            // First 24 questions: consistent comfortable speed
            speedIncrease = 0
        } else {
            // After 24: progressively faster, 0.15 seconds faster per question
            speedIncrease = Double(questionNumber - 24) * 0.15
        }
        
        let meteorDuration = max(1.4, (baseDuration - speedIncrease) * 0.55)
        let lanePositions = lanePositionsByCount[options.count] ?? lanePositionsByCount[3] ?? [-2.5, 0, 2.5]
        currentPosition = 0
        moveShipToPosition(0)

        activeMeteorChoices = options.enumerated().compactMap { index, option in
            guard index < lanePositions.count, let meteorNode = createMeteorNode(at: lanePositions[index], answerValue: option, isCorrect: option == answer) else {
                return nil
            }
            gameScene.rootNode.addChildNode(meteorNode)
            let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 2, z: 0.5, duration: 1.0))
            let moveAction = SCNAction.move(to: SCNVector3(x: lanePositions[index], y: self.meteorHoverY, z: self.meteorHoverZ), duration: meteorDuration)
            moveAction.timingMode = .easeOut
            meteorNode.childNode(withName: "meteor.body", recursively: false)?.runAction(rotateAction, forKey: "meteor.spin")
            meteorNode.runAction(moveAction, forKey: "meteor.flight")
            return MeteorChoice(node: meteorNode, answerValue: option, laneX: lanePositions[index], isCorrect: option == answer)
        }
        meteor = activeMeteorChoices.first(where: { $0.isCorrect })?.node
        if questionNumber > 24 {
            starSpeed = min(0.8, 0.3 + Float(questionNumber - 24) * 0.015)
        }
        
        // Add timeout - meteor strikes ship after hovering time if not answered
        meteorTimeoutWork?.cancel()
        let hoverDelay = meteorDuration + 3.25
        let work = DispatchWorkItem { [weak self] in
            self?.handleMeteorTimeout()
        }
        meteorTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + hoverDelay, execute: work)
    }
    
    @objc func answerTapped(_ sender: UIButton) {
        return
    }
    
    func shootLaser(at targetNode: SCNNode, completion: @escaping () -> Void) {
        // Play laser sound
        AudioManager.shared.playLaserFire()

        let shipPosition = spaceship.presentation.position
        let startPosition = SCNVector3(x: shipPosition.x, y: shipPosition.y + 0.08, z: shipPosition.z - 1.6)
        let targetPosition = targetNode.presentation.position
        let beamLength = max(distance(from: startPosition, to: targetPosition), 0.6)

        // Create a beam that spans from the ship to the meteor's live position
        let laser = SCNNode(geometry: SCNBox(width: 0.14, height: 0.14, length: beamLength, chamferRadius: 0.05))
        laser.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan
        laser.geometry?.firstMaterial?.emission.contents = UIColor.cyan
        laser.geometry?.firstMaterial?.transparency = 0.9
        laser.geometry?.firstMaterial?.lightingModel = .constant

        laser.position = midpoint(from: startPosition, to: targetPosition)
        laser.look(at: targetPosition)
        laser.opacity = 0.0
        gameScene.rootNode.addChildNode(laser)

        let flashIn = SCNAction.fadeIn(duration: 0.03)
        let flashOut = SCNAction.fadeOut(duration: 0.12)
        let pulse = SCNAction.scale(to: 1.08, duration: 0.06)
        pulse.timingMode = .easeOut
        let settle = SCNAction.scale(to: 1.0, duration: 0.06)
        settle.timingMode = .easeIn

        let group = SCNAction.group([
            SCNAction.sequence([flashIn, flashOut]),
            SCNAction.sequence([pulse, settle])
        ])
        laser.runAction(group) {
            laser.removeFromParentNode()
            completion()
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
        guard !isEndingSession else { return }
        guard !isResolvingTap else { return }
        guard !hasResolvedCurrentEncounter else { return }
        
        hasResolvedCurrentEncounter = true
        isResolvingTap = true
        missedQuestions.append(currentQuestionText)
        recordMiss(for: currentQuestionText)
        if difficulty == .easy {
            markQuestionForRetryIfNeeded(currentQuestionText)
        }
        
        let lingeringChoices = activeMeteorChoices
        activeMeteorChoices.removeAll()
        meteor = nil
        
        // Pick one meteor to strike the ship (prefer correct answer meteor)
        guard let strikingChoice = lingeringChoices.first(where: { $0.isCorrect }) ?? lingeringChoices.first else {
            resolveShipDamage(at: SCNVector3(x: 0, y: -2.25, z: 0))
            return
        }
        
        let shipPosition = SCNVector3(x: currentPosition, y: -2.25, z: 0)
        
        // Make the striking meteor fly toward the ship
        let strikeAction = SCNAction.move(to: shipPosition, duration: 0.5)
        strikeAction.timingMode = SCNActionTimingMode.easeIn
        strikingChoice.node.runAction(strikeAction) {
            self.breakMeteorIntoPieces(meteorNode: strikingChoice.node)
            self.resolveShipDamage(at: shipPosition)
        }
        
        // Make all other meteors fly away toward camera and slightly to the side
        for choice in lingeringChoices where choice.node !== strikingChoice.node {
            let sideOffset: Float = choice.laneX < 0 ? -3.0 : 3.0
            let awayPosition = SCNVector3(
                x: choice.laneX + sideOffset,
                y: Float.random(in: -2...3),
                z: Float.random(in: 5...12)
            )
            let flyAway = SCNAction.move(to: awayPosition, duration: 1.0)
            flyAway.timingMode = SCNActionTimingMode.easeIn
            choice.node.runAction(flyAway) {
                choice.node.removeFromParentNode()
            }
        }
    }
    
    func meteorHitsShip() {
        resolveShipDamage(at: SCNVector3(x: currentPosition, y: -2.25, z: 0))
    }
    
    func breakMeteorIntoPieces() {
        guard let meteor = meteor else { return }
        breakMeteorIntoPieces(meteorNode: meteor)
    }
    
    func breakMeteorIntoPieces(meteorNode: SCNNode) {
        let meteorPosition = meteorNode.position
        
        // Play ship hit sound
        AudioManager.shared.playShipHit()
        
        // Remove original meteor
        meteorNode.removeFromParentNode()
        
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
        DispatchQueue.main.async {
            let clampedLives = max(0, self.lives)
            self.hullStatusLabel.text = "SHIPS"
            self.hullStatusLabel.textColor = clampedLives > 1
                ? self.arcadeSignalBright
                : (clampedLives == 1 ? self.arcadeWarning : self.arcadeDanger)
            
            for index in 0..<3 {
                guard let lifeView = self.livesContainer.viewWithTag(1000 + index) else { continue }
                let isActive = index < clampedLives
                self.applyArcadePanelStyle(
                    to: lifeView,
                    accent: isActive ? self.arcadeSignal : self.arcadeDanger,
                    fillColors: isActive
                        ? [self.arcadePanelSoft, self.arcadePanel]
                        : [self.arcadePanel, UIColor.black.withAlphaComponent(0.88)],
                    cornerCut: 12
                )
                UIView.animate(withDuration: 0.25) {
                    lifeView.alpha = isActive ? 1.0 : 0.24
                    lifeView.transform = isActive ? .identity : CGAffineTransform(scaleX: 0.92, y: 0.92)
                }
            }
        }
    }
    
    func updateStreakDisplay() {
        DispatchQueue.main.async {
            self.applyMetricValue(self.currentStreak, to: self.streakLabel, accent: self.arcadeSignalBright)
            self.applyMetricValue(self.totalMeteorsDestroyed, to: self.answersRightLabel, accent: self.arcadeCool)
        }
    }
    
    func showGameOver() {
        showEndScreen(success: false)
    }

    func completeMission() {
        guard !didCompleteMission else { return }
        didCompleteMission = true
        isEndingSession = true

        clearActiveMeteorEncounter()
        lastMissionReward = PlayerProfileStore.shared.awardStars(calculateMissionStars())
        questionLabel.text = "\(missionQuestionLimit) / \(missionQuestionLimit)"
        answerButtons.forEach { $0.isEnabled = false }

        UIView.animate(withDuration: 0.25) {
            self.answerButtons.forEach { $0.alpha = 0.0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            self.showEndScreen(success: true)
        }
    }

    func showEndScreen(success: Bool) {
        
        DispatchQueue.main.async {
            guard self.gameOverOverlay == nil else { return }
            self.persistSessionStatsIfNeeded()
            self.isEndingSession = false
            self.questionPanel.isHidden = true
            self.livesContainer.isHidden = true
            self.streakLabel.superview?.isHidden = true
            self.answerButtons.forEach { $0.isHidden = true }
            self.spaceship.isHidden = true
            self.clearActiveMeteorEncounter()
            AudioManager.shared.stopThruster()
            self.addSpinningMeteorDecoration()
            
            self.gameOverOverlay?.removeFromSuperview()
            let overlay = UIView(frame: self.view.bounds)
            overlay.backgroundColor = UIColor(red: 0.01, green: 0.02, blue: 0.06, alpha: 0.88)
            self.view.addSubview(overlay)
            self.gameOverOverlay = overlay
            
            let backdrop = CAGradientLayer()
            backdrop.name = "arcade.backdrop"
            backdrop.frame = overlay.bounds
            backdrop.colors = [
                UIColor.black.withAlphaComponent(0.16).cgColor,
                self.arcadeSpaceTop.withAlphaComponent(0.94).cgColor,
                UIColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 0.98).cgColor
            ]
            backdrop.startPoint = CGPoint(x: 0.5, y: 0.0)
            backdrop.endPoint = CGPoint(x: 0.5, y: 1.0)
            overlay.layer.insertSublayer(backdrop, at: 0)
            
            let topInset = max(self.view.safeAreaInsets.top, 20)
            let bottomInset = max(self.view.safeAreaInsets.bottom, 20)
            let missedTargets = Array(self.prioritizedMissedProblems().prefix(6))
            let hasReplay = !missedTargets.isEmpty
            let panelWidth = min(overlay.bounds.width - 36, 420)
            let rewardLines = success ? self.starRewardBreakdown() : []
            let rewardSectionHeight: CGFloat = rewardLines.isEmpty ? 0 : CGFloat(142 + rewardLines.count * 42)
            let summaryHeight: CGFloat = success ? 214 + rewardSectionHeight : 214
            let missedRowCount = Int(ceil(Double(missedTargets.count) / 2.0))
            let missedPanelHeight: CGFloat = hasReplay ? CGFloat(60 + missedRowCount * 44) : 0
            let buttonStackHeight: CGFloat = hasReplay ? 124 : 60
            let contentHeight = summaryHeight + (hasReplay ? missedPanelHeight + 14 : 0) + 18 + buttonStackHeight
            let panelX = (overlay.bounds.width - panelWidth) / 2
            let availableHeight = overlay.bounds.height - topInset - bottomInset
            let contentOffsetY = max(18, (availableHeight - min(contentHeight, availableHeight - 24)) / 2)
            let summaryAccent = success ? self.arcadeSuccess : self.arcadeDanger
            let debriefText = success ? "BOARD CLEARED" : "MISSION DEBRIEF"
            let debriefColor = success ? self.arcadeSuccess : self.arcadeSignalBright
            let heroTitleText = success ? "MISSION COMPLETE" : "GAME OVER"
            let headlineValueText = success ? "\(self.missionQuestionLimit)" : "\(self.totalMeteorsDestroyed)"
            let headlineLabelText = success ? "WAVES CLEARED" : "TOTAL CLEARED"

            let scrollView = UIScrollView(frame: CGRect(
                x: 0,
                y: topInset,
                width: overlay.bounds.width,
                height: availableHeight
            ))
            scrollView.showsVerticalScrollIndicator = false
            scrollView.alwaysBounceVertical = contentHeight > availableHeight - 24
            overlay.addSubview(scrollView)

            let contentView = UIView(frame: CGRect(
                x: 0,
                y: 0,
                width: overlay.bounds.width,
                height: max(contentHeight + contentOffsetY + 18, availableHeight)
            ))
            scrollView.addSubview(contentView)
            scrollView.contentSize = contentView.bounds.size
            
            let summaryPanel = UIView(frame: CGRect(x: panelX, y: contentOffsetY, width: panelWidth, height: summaryHeight))
            self.applyArcadePanelStyle(
                to: summaryPanel,
                accent: summaryAccent,
                fillColors: [self.arcadePanelSoft, self.arcadePanel],
                cornerCut: 20
            )
            contentView.addSubview(summaryPanel)
            
            let debriefLabel = UILabel(frame: CGRect(x: 18, y: 18, width: summaryPanel.bounds.width - 36, height: 14))
            debriefLabel.text = debriefText
            debriefLabel.font = UIFont.exo2SemiBold(size: 11)
            debriefLabel.textColor = debriefColor
            debriefLabel.textAlignment = .center
            summaryPanel.addSubview(debriefLabel)
            self.addArcadeBlinkAnimation(to: debriefLabel, minimumOpacity: 0.46, duration: 0.9)
            
            let heroTitle = UILabel(frame: CGRect(x: 18, y: 38, width: summaryPanel.bounds.width - 36, height: 34))
            heroTitle.text = heroTitleText
            heroTitle.font = UIFont.orbitronBold(size: 34)
            heroTitle.textColor = .white
            heroTitle.textAlignment = .center
            heroTitle.adjustsFontSizeToFitWidth = true
            summaryPanel.addSubview(heroTitle)
            
            let destroyedValue = UILabel(frame: CGRect(x: 18, y: 78, width: summaryPanel.bounds.width - 36, height: 52))
            destroyedValue.text = headlineValueText
            destroyedValue.font = UIFont.orbitronBold(size: 52)
            destroyedValue.textColor = success ? self.arcadeSuccess : self.arcadeSignalBright
            destroyedValue.textAlignment = .center
            destroyedValue.adjustsFontSizeToFitWidth = true
            destroyedValue.minimumScaleFactor = 0.7
            summaryPanel.addSubview(destroyedValue)
            
            let destroyedLabel = UILabel(frame: CGRect(x: 18, y: 132, width: summaryPanel.bounds.width - 36, height: 18))
            destroyedLabel.text = headlineLabelText
            destroyedLabel.font = UIFont.exo2SemiBold(size: 13)
            destroyedLabel.textColor = UIColor.white.withAlphaComponent(0.82)
            destroyedLabel.textAlignment = .center
            summaryPanel.addSubview(destroyedLabel)
            
            let statCardWidth = (summaryPanel.bounds.width - 56) / 3
            if success, let reward = self.lastMissionReward {
                let rewardBanner = self.createStarRewardBanner(
                    frame: CGRect(x: 18, y: 156, width: summaryPanel.bounds.width - 36, height: rewardSectionHeight),
                    reward: reward,
                    breakdown: rewardLines
                )
                summaryPanel.addSubview(rewardBanner)
            }
            let statsY: CGFloat = success ? 156 + rewardSectionHeight + 18 : 162
            let perfectCard = self.createSummaryStatCard(
                frame: CGRect(x: 18, y: statsY, width: statCardWidth, height: 34),
                title: "PERFECT",
                value: "\(self.firstAttemptCorrect)",
                accent: self.arcadeSuccess
            )
            summaryPanel.addSubview(perfectCard)
            
            let missedCard = self.createSummaryStatCard(
                frame: CGRect(x: perfectCard.frame.maxX + 10, y: statsY, width: statCardWidth, height: 34),
                title: "MISSED",
                value: "\(self.missedQuestions.count)",
                accent: self.arcadeDanger
            )
            summaryPanel.addSubview(missedCard)

            let repairsCard = self.createSummaryStatCard(
                frame: CGRect(x: missedCard.frame.maxX + 10, y: statsY, width: statCardWidth, height: 34),
                title: "REPAIRS",
                value: "\(self.repairsCompleted)",
                accent: self.arcadeSignalBright
            )
            summaryPanel.addSubview(repairsCard)
            
            var lastPanelMaxY = summaryPanel.frame.maxY
            if hasReplay {
                let missedPanel = UIView(
                    frame: CGRect(
                        x: panelX,
                        y: summaryPanel.frame.maxY + 14,
                        width: panelWidth,
                        height: missedPanelHeight
                    )
                )
                self.applyArcadePanelStyle(
                    to: missedPanel,
                    accent: self.arcadeWarning,
                    fillColors: [self.arcadePanelSoft, self.arcadePanel],
                    cornerCut: 18
                )
                contentView.addSubview(missedPanel)
                
                let missedHeader = UILabel(frame: CGRect(x: 18, y: 16, width: missedPanel.bounds.width - 36, height: 18))
                missedHeader.text = "TRY THESE"
                missedHeader.font = UIFont.exo2SemiBold(size: 12)
                missedHeader.textColor = self.arcadeWarning
                missedHeader.textAlignment = .center
                missedPanel.addSubview(missedHeader)
                self.addArcadeBlinkAnimation(to: missedHeader, minimumOpacity: 0.32, duration: 0.62)
                
                let chipWidth = (missedPanel.bounds.width - 48 - 10) / 2
                let chipHeight: CGFloat = 34
                for (index, item) in missedTargets.enumerated() {
                    let row = index / 2
                    let column = index % 2
                    let chip = self.createMissedTargetChip(
                        frame: CGRect(
                            x: 18 + CGFloat(column) * (chipWidth + 10),
                            y: 44 + CGFloat(row) * (chipHeight + 10),
                            width: chipWidth,
                            height: chipHeight
                        ),
                        problem: item.problem,
                        count: item.count
                    )
                    missedPanel.addSubview(chip)
                }
                
                lastPanelMaxY = missedPanel.frame.maxY
            }
            
            let primaryButtonY = lastPanelMaxY + 18
            if hasReplay {
                let replayButton = self.createActionButton(
                    frame: CGRect(x: panelX, y: primaryButtonY, width: panelWidth, height: 60),
                    title: success ? "Replay Missed" : "Try Missed",
                    subtitle: nil,
                    accent: self.arcadeSignal,
                    fillColors: [self.arcadeSignalBright, self.arcadeSignal, self.arcadeSignal.withAlphaComponent(0.84)],
                    action: #selector(self.playAgainWithMissed)
                )
                contentView.addSubview(replayButton)
                self.addArcadePulseAnimation(to: replayButton, scale: 1.025, duration: 0.78)
                
                let menuButton = self.createActionButton(
                    frame: CGRect(x: panelX, y: replayButton.frame.maxY + 12, width: panelWidth, height: 52),
                    title: "Menu",
                    subtitle: nil,
                    accent: self.arcadeCool,
                    fillColors: [self.arcadePanelSoft, self.arcadePanel],
                    action: #selector(self.backToMenu)
                )
                contentView.addSubview(menuButton)
            } else {
                let menuButton = self.createActionButton(
                    frame: CGRect(x: panelX, y: primaryButtonY, width: panelWidth, height: 60),
                    title: success ? "Continue" : "Menu",
                    subtitle: nil,
                    accent: self.arcadeSignal,
                    fillColors: success
                        ? [self.arcadeSignalBright, self.arcadeSignal, self.arcadeSignal.withAlphaComponent(0.84)]
                        : [self.arcadeSignalBright, self.arcadeSignal, self.arcadeSignal.withAlphaComponent(0.82)],
                    action: #selector(self.backToMenu)
                )
                contentView.addSubview(menuButton)
                self.addArcadePulseAnimation(to: menuButton, scale: 1.02, duration: 0.88)
            }
        }
    }
    
    func createMissedTargetChip(frame: CGRect, problem: String, count: Int) -> UIView {
        let chip = UIView(frame: frame)
        let accent = count > 1 ? arcadeDanger : arcadeWarning
        applyArcadePanelStyle(
            to: chip,
            accent: accent,
            fillColors: [arcadePanelSoft, arcadePanel],
            cornerCut: 12
        )
        
        let titleLabel = UILabel(frame: CGRect(x: 12, y: 7, width: chip.bounds.width - 60, height: 20))
        titleLabel.text = problem
        titleLabel.font = UIFont.orbitronBold(size: 17)
        titleLabel.textColor = .white
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        chip.addSubview(titleLabel)
        
        let countLabel = UILabel(frame: CGRect(x: chip.bounds.width - 50, y: 8, width: 38, height: 18))
        countLabel.text = "×\(count)"
        countLabel.font = UIFont.exo2SemiBold(size: 10)
        countLabel.textColor = accent
        countLabel.textAlignment = .center
        countLabel.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        countLabel.layer.cornerRadius = 9
        countLabel.layer.masksToBounds = true
        chip.addSubview(countLabel)
        
        return chip
    }
    
    func createSummaryStatCard(frame: CGRect, title: String, value: String, accent: UIColor) -> UIView {
        let card = UIView(frame: frame)
        applyArcadePanelStyle(
            to: card,
            accent: accent,
            fillColors: [arcadePanelSoft, arcadePanel],
            cornerCut: 12
        )
        
        let titleLabel = UILabel(frame: CGRect(x: 10, y: 8, width: card.bounds.width - 54, height: 16))
        titleLabel.text = title
        titleLabel.font = UIFont.exo2SemiBold(size: 10)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        card.addSubview(titleLabel)
        
        let valueLabel = UILabel(frame: CGRect(x: card.bounds.width - 48, y: 4, width: 38, height: 24))
        valueLabel.text = value
        valueLabel.font = UIFont.orbitronBold(size: 18)
        valueLabel.textColor = accent
        valueLabel.textAlignment = .right
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        card.addSubview(valueLabel)
        
        return card
    }

    func createStarRewardBanner(frame: CGRect, reward: MissionStarReward, breakdown: [StarRewardLine]) -> UIView {
        let banner = UIView(frame: frame)
        let displayedTotal = breakdown.reduce(0) { $0 + $1.stars }
        applyArcadePanelStyle(
            to: banner,
            accent: arcadeWarning,
            fillColors: [arcadePanelSoft, arcadePanel],
            cornerCut: 14
        )

        let titleLabel = UILabel(frame: CGRect(x: 14, y: 10, width: banner.bounds.width - 28, height: 20))
        titleLabel.text = "STAR REWARD"
        titleLabel.font = UIFont.exo2SemiBold(size: 13)
        titleLabel.textColor = arcadeWarning
        titleLabel.textAlignment = .center
        banner.addSubview(titleLabel)

        let medalSize: CGFloat = 96
        let medalView = UIView(frame: CGRect(x: (banner.bounds.width - medalSize) / 2, y: 34, width: medalSize, height: medalSize))
        medalView.layer.cornerRadius = medalSize / 2
        medalView.layer.masksToBounds = true
        medalView.backgroundColor = arcadeWarning.withAlphaComponent(0.12)
        medalView.layer.borderColor = arcadeWarning.withAlphaComponent(0.9).cgColor
        medalView.layer.borderWidth = 2
        banner.addSubview(medalView)

        let starBackdrop = UILabel(frame: medalView.bounds)
        starBackdrop.text = "★"
        starBackdrop.font = UIFont.orbitronBold(size: 64)
        starBackdrop.textColor = arcadeWarning.withAlphaComponent(0.3)
        starBackdrop.textAlignment = .center
        medalView.addSubview(starBackdrop)

        let totalTitleLabel = UILabel(frame: CGRect(x: 0, y: 17, width: medalView.bounds.width, height: 14))
        totalTitleLabel.text = "TOTAL"
        totalTitleLabel.font = UIFont.exo2SemiBold(size: 11)
        totalTitleLabel.textColor = UIColor.white.withAlphaComponent(0.86)
        totalTitleLabel.textAlignment = .center
        medalView.addSubview(totalTitleLabel)

        let totalLabel = UILabel(frame: CGRect(x: 8, y: 31, width: medalView.bounds.width - 16, height: 38))
        totalLabel.text = "+0"
        totalLabel.font = UIFont.orbitronBold(size: 28)
        totalLabel.textColor = .white
        totalLabel.textAlignment = .center
        totalLabel.alpha = 0
        medalView.addSubview(totalLabel)

        var rowViews: [UIView] = []
        var valueLabels: [UILabel] = []
        let lineHeight: CGFloat = 42
        for (index, line) in breakdown.enumerated() {
            let y = 138 + CGFloat(index) * lineHeight
            let rowView = UIView(frame: CGRect(x: 14, y: y - 3, width: banner.bounds.width - 28, height: 34))
            rowView.alpha = 0
            banner.addSubview(rowView)

            let label = UILabel(frame: CGRect(x: 2, y: 2, width: rowView.bounds.width - 108, height: 28))
            label.text = line.title
            label.font = UIFont.orbitronBold(size: 16)
            label.textColor = .white
            rowView.addSubview(label)

            let valueLabel = UILabel(frame: CGRect(x: rowView.bounds.width - 98, y: 0, width: 92, height: 30))
            valueLabel.text = "+0"
            valueLabel.font = UIFont.orbitronBold(size: 22)
            valueLabel.textColor = line.accent
            valueLabel.textAlignment = .right
            rowView.addSubview(valueLabel)

            rowViews.append(rowView)
            valueLabels.append(valueLabel)
        }

        addArcadePulseAnimation(to: banner, scale: 1.03, duration: 0.72)
        animateRewardBreakdown(rows: rowViews, valueLabels: valueLabels, totalLabel: totalLabel, breakdown: breakdown, finalTotal: displayedTotal)
        return banner
    }
    
    func hasMasteredReplayProblemSet() -> Bool {
        guard isReplaySession else { return false }
        
        let replayTargets = replayFocusProblems.isEmpty ? customProblems : replayFocusProblems
        let targetProblems = Set(replayTargets.map { normalizedProblemKey(from: $0) })
        guard !targetProblems.isEmpty else { return false }
        
        return targetProblems.allSatisfy { target in
            (perfectProblems[target] ?? 0) >= replayMasteryThreshold
        }
    }
    
    func completeReplaySession() {
        guard !didCompleteReplaySession else { return }
        didCompleteReplaySession = true
        isEndingSession = true
        persistSessionStatsIfNeeded()
        
        clearActiveMeteorEncounter()
        questionLabel.text = "CLEAR!"
        answerButtons.forEach { $0.isEnabled = false }
        
        UIView.animate(withDuration: 0.25) {
            self.answerButtons.forEach { $0.alpha = 0.0 }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.gameOverCallback?(self.totalMeteorsDestroyed, self.firstAttemptCorrect, self.perfectProblems)
        }
    }
    
    func addArcadeBlinkAnimation(to view: UIView, minimumOpacity: Float = 0.4, duration: CFTimeInterval = 0.7) {
        view.layer.removeAnimation(forKey: "arcade.blink")
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = minimumOpacity
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(animation, forKey: "arcade.blink")
    }
    
    func addArcadePulseAnimation(to view: UIView, scale: CGFloat = 1.03, duration: CFTimeInterval = 0.85) {
        view.layer.removeAnimation(forKey: "arcade.pulse")
        
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = scale
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(animation, forKey: "arcade.pulse")
    }
    
    func createActionButton(
        frame: CGRect,
        title: String,
        subtitle: String?,
        accent: UIColor,
        fillColors: [UIColor],
        action: Selector
    ) -> UIButton {
        let button = UIButton(frame: frame)
        applyArcadePanelStyle(
            to: button,
            accent: accent,
            fillColors: fillColors,
            cornerCut: 16
        )
        button.addTarget(self, action: action, for: .touchUpInside)
        
        let titleY: CGFloat = subtitle == nil ? 16 : 10
        let titleLabel = UILabel(frame: CGRect(x: 16, y: titleY, width: button.bounds.width - 32, height: 24))
        titleLabel.text = title.uppercased()
        titleLabel.font = UIFont.orbitronBold(size: subtitle == nil ? 18 : 20)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.isUserInteractionEnabled = false
        button.addSubview(titleLabel)
        
        if let subtitle {
            let subtitleLabel = UILabel(frame: CGRect(x: 16, y: frame.height - 28, width: button.bounds.width - 32, height: 14))
            subtitleLabel.text = subtitle
            subtitleLabel.font = UIFont.exo2SemiBold(size: 11)
            subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
            subtitleLabel.textAlignment = .center
            subtitleLabel.adjustsFontSizeToFitWidth = true
            subtitleLabel.minimumScaleFactor = 0.7
            subtitleLabel.isUserInteractionEnabled = false
            button.addSubview(subtitleLabel)
        }
        
        return button
    }
    
    func prioritizedMissedProblems() -> [(problem: String, count: Int)] {
        var counts: [String: Int] = [:]
        let replaySource = difficulty == .easy ? retryCandidateQuestions : missedQuestions
        for question in replaySource {
            let normalized = normalizedProblemKey(from: question)
            counts[normalized, default: 0] += 1
        }
        for repairProblem in repairReviewProblems {
            counts[repairProblem, default: 0] += 1
        }
        
        return counts
            .map { (problem: $0.key, count: $0.value) }
            .sorted {
                if $0.count == $1.count {
                    return $0.problem < $1.problem
                }
                return $0.count > $1.count
            }
    }
    
    func normalizedProblemKey(from question: String) -> String {
        question
            .replacingOccurrences(of: " = ?", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
    
    func addSpinningMeteorDecoration() {
        gameScene.rootNode.childNodes
            .filter { $0.name == "gameOverDecorMeteor" }
            .forEach { $0.removeFromParentNode() }
        
        guard let meteorScene = SCNScene(named: "art.scnassets/meteor_detailed.dae") else { return }
        
        let decorMeteor = SCNNode()
        decorMeteor.name = "gameOverDecorMeteor"
        for child in meteorScene.rootNode.childNodes {
            decorMeteor.addChildNode(child)
        }
        
        decorMeteor.scale = SCNVector3(x: 1.1, y: 1.1, z: 1.1)
        decorMeteor.position = SCNVector3(x: 4.5, y: 2.4, z: -18)
        gameScene.rootNode.addChildNode(decorMeteor)
        
        let rotateAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0.4, y: 1.3, z: 0.2, duration: 2.3))
        decorMeteor.runAction(rotateAction)
    }
    
    @objc func playAgainWithMissed() {
        guard !isEndingSession else { return }
        isEndingSession = true
        AudioManager.shared.playButtonTap()
        let replaySource = difficulty == .easy ? retryCandidateQuestions : missedQuestions
        let missedProblems = replaySource.map { normalizedProblemKey(from: $0) } + repairReviewProblems
        playAgainCallback?(missedProblems)
    }

    func markQuestionForRetryIfNeeded(_ question: String) {
        let normalized = normalizedProblemKey(from: question)
        let existing = Set(retryCandidateQuestions.map { normalizedProblemKey(from: $0) })
        if !existing.contains(normalized) {
            retryCandidateQuestions.append(question)
        }
    }

    func starRewardBreakdown(includeRepairStars: Bool = true) -> [StarRewardLine] {
        var lines: [StarRewardLine] = [
            StarRewardLine(title: "BOARD CLEAR", stars: 10, accent: arcadeWarning)
        ]
        let accuracyBonus: Int
        if firstAttemptCorrect >= 27 {
            accuracyBonus = 8
        } else if firstAttemptCorrect >= 24 {
            accuracyBonus = 5
        } else {
            accuracyBonus = 0
        }
        if accuracyBonus > 0 {
            lines.append(StarRewardLine(title: "ACCURACY BONUS", stars: accuracyBonus, accent: arcadeSuccess))
        }
        let masteryBonus = (missedQuestions.isEmpty ? 3 : 0) + (topScore >= 10 ? 2 : 0)
        if masteryBonus > 0 {
            lines.append(StarRewardLine(title: missedQuestions.isEmpty ? "PERFECT RUN" : "STREAK BONUS", stars: masteryBonus, accent: arcadeCool))
        }
        if includeRepairStars, repairStarsEarned > 0 {
            lines.append(StarRewardLine(title: "REPAIR BONUS", stars: repairStarsEarned, accent: arcadeSignalBright))
        }

        return lines
    }

    func calculateMissionStars() -> Int {
        starRewardBreakdown(includeRepairStars: false).reduce(0) { $0 + $1.stars }
    }

    func animateStarCount(
        on label: UILabel,
        targetValue: Int,
        delay: Double,
        onStep: ((Int) -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        label.text = "+0"
        guard targetValue > 0 else {
            completion?()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            var currentValue = 0
            let steps = max(targetValue, 1)
            let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                currentValue += 1
                label.text = "+\(currentValue)"
                onStep?(currentValue)
                if currentValue >= steps {
                    timer.invalidate()
                    self.activeStarRewardTimers.removeAll { $0 === timer }
                    completion?()
                }
            }
            self.activeStarRewardTimers.append(timer)
        }
    }

    func animateRewardBreakdown(
        rows: [UIView],
        valueLabels: [UILabel],
        totalLabel: UILabel,
        breakdown: [StarRewardLine],
        finalTotal: Int
    ) {
        totalLabel.alpha = 1
        totalLabel.text = "+0"

        func revealRow(at index: Int, runningTotal: Int) {
            guard index < rows.count else {
                totalLabel.text = "+\(finalTotal)"
                return
            }

            let row = rows[index]
            let valueLabel = valueLabels[index]
            let line = breakdown[index]

            UIView.animate(withDuration: 0.22, animations: {
                row.alpha = 1
            }) { _ in
                self.animateStarCount(on: valueLabel, targetValue: line.stars, delay: 0.0, completion: {
                    var displayedTotal = runningTotal
                    self.animateStarsToTotal(
                        from: row,
                        count: line.stars,
                        color: line.accent,
                        totalLabel: totalLabel,
                        onStarArrive: {
                            displayedTotal += 1
                            totalLabel.text = "+\(displayedTotal)"
                        }
                    ) {
                        UIView.animate(withDuration: 0.16, animations: {
                            totalLabel.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
                        }) { _ in
                            UIView.animate(withDuration: 0.16) {
                                totalLabel.transform = .identity
                            }
                            revealRow(at: index + 1, runningTotal: runningTotal + line.stars)
                        }
                    }
                })
            }
        }

        revealRow(at: 0, runningTotal: 0)
    }

    func animateStarsToTotal(
        from row: UIView,
        count: Int,
        color: UIColor,
        totalLabel: UILabel,
        onStarArrive: (() -> Void)? = nil,
        completion: @escaping () -> Void
    ) {
        guard count > 0, let banner = row.superview else {
            completion()
            return
        }
        let group = DispatchGroup()
        let startPoint = banner.convert(CGPoint(x: row.frame.maxX - 34, y: row.frame.midY), to: view)
        let endPoint = totalLabel.superview?.convert(CGPoint(x: totalLabel.frame.midX, y: totalLabel.frame.midY), to: view) ?? .zero
        for index in 0..<count {
            group.enter()
            let starLabel = UILabel(frame: CGRect(x: startPoint.x - 12, y: startPoint.y - 12, width: 24, height: 24))
            starLabel.text = "★"
            starLabel.font = UIFont.orbitronBold(size: 20)
            starLabel.textColor = color
            starLabel.textAlignment = .center
            view.addSubview(starLabel)

            let delay = 0.08 * Double(index)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                UIView.animate(withDuration: 0.34, animations: {
                    starLabel.center = endPoint
                    starLabel.transform = CGAffineTransform(scaleX: 0.35, y: 0.35)
                    starLabel.alpha = 0
                }) { _ in
                    starLabel.removeFromSuperview()
                    AudioManager.shared.playStarCollect()
                    onStarArrive?()
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    func recordPresentedQuestion(_ question: String) {
        guard let tableNumber = tableNumber(for: question) else { return }
        tableAttempts[tableNumber, default: 0] += 1
    }

    func recordCorrectAnswer(for question: String, firstTry: Bool) {
        guard let tableNumber = tableNumber(for: question) else { return }
        tableCorrectAnswers[tableNumber, default: 0] += 1
        if firstTry {
            tableFirstAttemptCorrect[tableNumber, default: 0] += 1
        }
    }

    func recordMiss(for question: String) {
        guard let tableNumber = tableNumber(for: question) else { return }
        tableMisses[tableNumber, default: 0] += 1
    }

    func tableNumber(for question: String) -> Int? {
        let compact = normalizedProblemKey(from: question)

        if compact.contains("×") {
            let parts = compact.split(separator: "×")
            if parts.count == 2, let rhs = Int(parts[1]) {
                return rhs
            }
        }

        if compact.contains("÷") {
            let parts = compact.split(separator: "÷")
            if parts.count == 2, let rhs = Int(parts[1]) {
                return rhs
            }
        }

        return nil
    }

    func persistSessionStatsIfNeeded() {
        guard !didPersistSessionStats else { return }
        didPersistSessionStats = true

        let update = PlayerSessionStatUpdate(
            arithmeticMode: arithmeticMode,
            totalCleared: totalMeteorsDestroyed,
            bestStreak: topScore,
            totalQuestionsSeen: totalMeteorsDestroyed + missedQuestions.count,
            totalCorrectAnswers: totalMeteorsDestroyed,
            totalFirstAttemptCorrect: firstAttemptCorrect,
            totalMisses: missedQuestions.count,
            didCompleteMission: didCompleteMission,
            tableAttempts: tableAttempts,
            tableFirstAttemptCorrect: tableFirstAttemptCorrect,
            tableCorrectAnswers: tableCorrectAnswers,
            tableMisses: tableMisses
        )

        PlayerProfileStore.shared.recordSession(update)
    }
    
    @objc func backToMenu() {
        guard !isEndingSession else { return }
        isEndingSession = true
        AudioManager.shared.playButtonTap()
        gameOverCallback?(totalMeteorsDestroyed, firstAttemptCorrect, perfectProblems)
    }
    
    @objc func exitGame() {
        guard !isEndingSession else { return }
        isEndingSession = true
        starfieldTimer?.invalidate()
        starfieldTimer = nil
        clearActiveMeteorEncounter()
        answerButtons.forEach { $0.isEnabled = false }
        AudioManager.shared.stopThruster()
        exitToMenuCallback?()
    }
    
    @objc func debugCompleteMission() {
        // Fill in some sample stats
        totalMeteorsDestroyed = missionQuestionLimit
        firstAttemptCorrect = 25
        currentStreak = 15
        topScore = 15
        repairsCompleted = 2
        repairStarsEarned = 4
        
        // Trigger mission complete
        completeMission()
    }
    
    func moveShipToPosition(_ x: Float) {
        let targetPosition = SCNVector3(x: x, y: -2.25, z: 0)
        
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
        starfieldTimer?.invalidate()
        starfieldTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard !self.isEndingSession else { return }
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

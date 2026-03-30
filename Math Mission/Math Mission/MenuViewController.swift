//
//  MenuViewController.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import UIKit

enum Difficulty: Hashable {
    case easy    // 3 options, 2 tries
    case medium  // 3 options, 1 try
    case hard    // Infinite mode - 3 HUD answers, 1 try
}

class MenuViewController: UIViewController {
    
    var selectedTables: Set<Int> = []
    var selectedDifficulty: Difficulty = .easy
    
    var tableButtons: [UIButton] = []
    var difficultyButtons: [UIButton] = []
    var launchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setupUI()
    }
    
    func setupUI() {
        // Title
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 80, width: view.bounds.width, height: 60))
        titleLabel.text = "MATH MISSION"
        titleLabel.font = UIFont.orbitronBold(size: 38)
        titleLabel.textColor = .cyan
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Subtitle
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 140, width: view.bounds.width, height: 30))
        subtitleLabel.text = "Select Multiplication Tables"
        subtitleLabel.font = UIFont.exo2Medium(size: 20)
        subtitleLabel.textColor = .white
        subtitleLabel.textAlignment = .center
        view.addSubview(subtitleLabel)
        
        // Table selection grid (1-12 + All)
        let buttonSize: CGFloat = 70
        let spacing: CGFloat = 15
        let columns = 4
        let startX = (view.bounds.width - (CGFloat(columns) * (buttonSize + spacing) - spacing)) / 2
        let startY: CGFloat = 200
        
        for i in 1...12 {
            let row = (i - 1) / columns
            let col = (i - 1) % columns
            let x = startX + CGFloat(col) * (buttonSize + spacing)
            let y = startY + CGFloat(row) * (buttonSize + spacing)
            
            let button = UIButton(frame: CGRect(x: x, y: y, width: buttonSize, height: buttonSize))
            button.setTitle("\(i)×", for: .normal)
            button.titleLabel?.font = UIFont.exo2Bold(size: 26)
            button.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 10
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.gray.cgColor
            button.tag = i
            button.addTarget(self, action: #selector(tableButtonTapped(_:)), for: .touchUpInside)
            view.addSubview(button)
            tableButtons.append(button)
        }
        
        // Custom practice button - tight below times tables
        let customY = startY + 3 * (buttonSize + spacing) + spacing
        let customButton = UIButton(frame: CGRect(x: 20, y: customY, width: view.bounds.width - 40, height: 45))
        customButton.setTitle("⚙️ CUSTOM PRACTICE", for: .normal)
        customButton.titleLabel?.font = UIFont.orbitronMedium(size: 18)
        customButton.backgroundColor = UIColor(red: 0.5, green: 0.3, blue: 0.7, alpha: 1.0)
        customButton.setTitleColor(.white, for: .normal)
        customButton.layer.cornerRadius = 10
        customButton.addTarget(self, action: #selector(customButtonTapped), for: .touchUpInside)
        view.addSubview(customButton)
        
        // Difficulty selection - tight below custom button
        let difficultyY = customY + 55
        
        let difficultyLabel = UILabel(frame: CGRect(x: 0, y: difficultyY, width: view.bounds.width, height: 30))
        difficultyLabel.text = "Select Difficulty"
        difficultyLabel.font = UIFont.exo2Medium(size: 20)
        difficultyLabel.textColor = .white
        difficultyLabel.textAlignment = .center
        view.addSubview(difficultyLabel)
        
        let difficulties: [(String, Difficulty)] = [("EASY", .easy), ("MEDIUM", .medium), ("INFINITE", .hard)]
        let diffButtonWidth: CGFloat = 110
        let diffStartX = (view.bounds.width - (CGFloat(difficulties.count) * (diffButtonWidth + spacing) - spacing)) / 2
        
        for (index, (title, _)) in difficulties.enumerated() {
            let x = diffStartX + CGFloat(index) * (diffButtonWidth + spacing)
            let button = UIButton(frame: CGRect(x: x, y: difficultyY + 40, width: diffButtonWidth, height: 50))
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.exo2SemiBold(size: 19)
            button.backgroundColor = index == 0 ? UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0) : UIColor(white: 0.2, alpha: 1.0)
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 10
            button.layer.borderWidth = 2
            button.layer.borderColor = index == 0 ? UIColor.cyan.cgColor : UIColor.gray.cgColor
            button.tag = index
            button.addTarget(self, action: #selector(difficultyButtonTapped(_:)), for: .touchUpInside)
            view.addSubview(button)
            difficultyButtons.append(button)
        }
        
        // Launch button
        launchButton = UIButton(frame: CGRect(x: view.bounds.width/2 - 100, y: view.bounds.height - 120, width: 200, height: 60))
        launchButton.setTitle("🚀 LAUNCH", for: .normal)
        launchButton.titleLabel?.font = UIFont.orbitronBold(size: 28)
        launchButton.backgroundColor = UIColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)
        launchButton.setTitleColor(.white, for: .normal)
        launchButton.layer.cornerRadius = 15
        launchButton.isEnabled = false
        launchButton.alpha = 0.5
        launchButton.addTarget(self, action: #selector(launchButtonTapped), for: .touchUpInside)
        view.addSubview(launchButton)
    }
    
    @objc func tableButtonTapped(_ sender: UIButton) {
        AudioManager.shared.playButtonTap()
        let table = sender.tag
        
        if selectedTables.contains(table) {
            selectedTables.remove(table)
            sender.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            sender.layer.borderColor = UIColor.gray.cgColor
        } else {
            selectedTables.insert(table)
            sender.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
            sender.layer.borderColor = UIColor.cyan.cgColor
        }
        
        updateLaunchButton()
    }
    
    @objc func difficultyButtonTapped(_ sender: UIButton) {
        AudioManager.shared.playButtonTap()
        let difficulties: [Difficulty] = [.easy, .medium, .hard]
        selectedDifficulty = difficulties[sender.tag]
        
        // Update button states
        for (index, button) in difficultyButtons.enumerated() {
            if index == sender.tag {
                button.backgroundColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
                button.layer.borderColor = UIColor.cyan.cgColor
            } else {
                button.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                button.layer.borderColor = UIColor.gray.cgColor
            }
        }
    }
    
    func updateLaunchButton() {
        if selectedTables.isEmpty {
            launchButton.isEnabled = false
            launchButton.alpha = 0.5
        } else {
            launchButton.isEnabled = true
            launchButton.alpha = 1.0
        }
    }
    
    @objc func customButtonTapped() {
        AudioManager.shared.playButtonTap()
        let customVC = CustomTimesTableViewController()
        customVC.selectedDifficulty = selectedDifficulty
        customVC.modalPresentationStyle = .fullScreen
        present(customVC, animated: true)
    }
    
    @objc func launchButtonTapped() {
        AudioManager.shared.playButtonTap()
        // Go to ship selection
        let shipSelectionVC = ShipSelectionViewController()
        shipSelectionVC.selectedTables = Array(selectedTables)
        shipSelectionVC.selectedDifficulty = selectedDifficulty
        shipSelectionVC.isCustomMode = false
        shipSelectionVC.modalPresentationStyle = .fullScreen
        present(shipSelectionVC, animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

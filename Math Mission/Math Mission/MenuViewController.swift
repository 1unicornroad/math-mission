//
//  MenuViewController.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import UIKit

enum Difficulty {
    case easy    // 3 options, 2 tries
    case medium  // 3 options, 1 try
    case hard    // 4 options, 1 try
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
        titleLabel.font = UIFont.boldSystemFont(ofSize: 48)
        titleLabel.textColor = .cyan
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Subtitle
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 140, width: view.bounds.width, height: 30))
        subtitleLabel.text = "Select Multiplication Tables"
        subtitleLabel.font = UIFont.systemFont(ofSize: 20)
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
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
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
        
        // Difficulty selection (moved up since no ALL button)
        let difficultyY = startY + 4 * (buttonSize + spacing) + 20
        
        let difficultyLabel = UILabel(frame: CGRect(x: 0, y: difficultyY, width: view.bounds.width, height: 30))
        difficultyLabel.text = "Select Difficulty"
        difficultyLabel.font = UIFont.systemFont(ofSize: 20)
        difficultyLabel.textColor = .white
        difficultyLabel.textAlignment = .center
        view.addSubview(difficultyLabel)
        
        let difficulties: [(String, Difficulty)] = [("EASY", .easy), ("MEDIUM", .medium), ("HARD", .hard)]
        let diffButtonWidth: CGFloat = 110
        let diffStartX = (view.bounds.width - (CGFloat(difficulties.count) * (diffButtonWidth + spacing) - spacing)) / 2
        
        for (index, (title, difficulty)) in difficulties.enumerated() {
            let x = diffStartX + CGFloat(index) * (diffButtonWidth + spacing)
            let button = UIButton(frame: CGRect(x: x, y: difficultyY + 40, width: diffButtonWidth, height: 50))
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
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
        launchButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 28)
        launchButton.backgroundColor = UIColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)
        launchButton.setTitleColor(.white, for: .normal)
        launchButton.layer.cornerRadius = 15
        launchButton.isEnabled = false
        launchButton.alpha = 0.5
        launchButton.addTarget(self, action: #selector(launchButtonTapped), for: .touchUpInside)
        view.addSubview(launchButton)
    }
    
    @objc func tableButtonTapped(_ sender: UIButton) {
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
    
    @objc func launchButtonTapped() {
        // Create game view controller programmatically
        let gameVC = GameViewController()
        gameVC.selectedTables = Array(selectedTables)
        gameVC.difficulty = selectedDifficulty
        gameVC.modalPresentationStyle = .fullScreen
        present(gameVC, animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

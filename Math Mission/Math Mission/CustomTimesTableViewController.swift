//
//  CustomTimesTableViewController.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import UIKit

class CustomTimesTableViewController: UIViewController {
    
    var selectedProblems: Set<String> = []
    var selectedDifficulty: Difficulty = .easy
    var problemButtons: [UIButton] = []
    var launchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setupUI()
    }
    
    func setupUI() {
        // Title
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 60, width: view.bounds.width, height: 50))
        titleLabel.text = "CUSTOM PRACTICE"
        titleLabel.font = UIFont.orbitronBold(size: 38)
        titleLabel.textColor = .cyan
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Subtitle
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 110, width: view.bounds.width, height: 25))
        subtitleLabel.text = "Select Specific Problems"
        subtitleLabel.font = UIFont.exo2Regular(size: 17)
        subtitleLabel.textColor = .white
        subtitleLabel.textAlignment = .center
        view.addSubview(subtitleLabel)
        
        // Scrollable content area for all problems (1×1 through 12×12)
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 150, width: view.bounds.width, height: view.bounds.height - 300))
        scrollView.showsVerticalScrollIndicator = true
        view.addSubview(scrollView)
        
        let buttonSize: CGFloat = 65
        let spacing: CGFloat = 10
        let columns = 5
        let startX = (view.bounds.width - (CGFloat(columns) * (buttonSize + spacing) - spacing)) / 2
        var currentY: CGFloat = 20
        
        // Create buttons for all combinations
        for table in 1...12 {
            // Section header
            let headerLabel = UILabel(frame: CGRect(x: 20, y: currentY, width: view.bounds.width - 40, height: 30))
            headerLabel.text = "\(table)× Table"
            headerLabel.font = UIFont.orbitronMedium(size: 19)
            headerLabel.textColor = .cyan
            scrollView.addSubview(headerLabel)
            currentY += 35
            
            // Buttons for this table (1-12)
            for multiplier in 1...12 {
                let row = (multiplier - 1) / columns
                let col = (multiplier - 1) % columns
                let x = startX + CGFloat(col) * (buttonSize + spacing)
                let y = currentY + CGFloat(row) * (buttonSize + spacing)
                
                let button = UIButton(frame: CGRect(x: x, y: y, width: buttonSize, height: buttonSize))
                button.setTitle("\(multiplier)×\(table)", for: .normal)
                button.titleLabel?.font = UIFont.exo2SemiBold(size: 14)
                button.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
                button.setTitleColor(.white, for: .normal)
                button.layer.cornerRadius = 8
                button.layer.borderWidth = 2
                button.layer.borderColor = UIColor.gray.cgColor
                button.tag = table * 100 + multiplier
                button.addTarget(self, action: #selector(problemButtonTapped(_:)), for: .touchUpInside)
                scrollView.addSubview(button)
                problemButtons.append(button)
            }
            
            currentY += CGFloat((11 / columns + 1)) * (buttonSize + spacing) + 20
        }
        
        scrollView.contentSize = CGSize(width: view.bounds.width, height: currentY + 20)
        
        // Back button
        let backButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 130, width: 100, height: 50))
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font = UIFont.exo2SemiBold(size: 18)
        backButton.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        backButton.setTitleColor(.white, for: .normal)
        backButton.layer.cornerRadius = 10
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Launch button
        launchButton = UIButton(frame: CGRect(x: view.bounds.width - 220, y: view.bounds.height - 130, width: 200, height: 50))
        launchButton.setTitle("🚀 LAUNCH", for: .normal)
        launchButton.titleLabel?.font = UIFont.orbitronBold(size: 24)
        launchButton.backgroundColor = UIColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)
        launchButton.setTitleColor(.white, for: .normal)
        launchButton.layer.cornerRadius = 10
        launchButton.isEnabled = false
        launchButton.alpha = 0.5
        launchButton.addTarget(self, action: #selector(launchButtonTapped), for: .touchUpInside)
        view.addSubview(launchButton)
    }
    
    @objc func problemButtonTapped(_ sender: UIButton) {
        let table = sender.tag / 100
        let multiplier = sender.tag % 100
        let problemKey = "\(multiplier)×\(table)"
        
        if selectedProblems.contains(problemKey) {
            selectedProblems.remove(problemKey)
            sender.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            sender.layer.borderColor = UIColor.gray.cgColor
        } else {
            selectedProblems.insert(problemKey)
            sender.backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
            sender.layer.borderColor = UIColor.cyan.cgColor
        }
        
        updateLaunchButton()
    }
    
    func updateLaunchButton() {
        if selectedProblems.isEmpty {
            launchButton.isEnabled = false
            launchButton.alpha = 0.5
        } else {
            launchButton.isEnabled = true
            launchButton.alpha = 1.0
        }
    }
    
    @objc func backButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc func launchButtonTapped() {
        // Go to ship selection
        let shipSelectionVC = ShipSelectionViewController()
        shipSelectionVC.selectedProblems = Array(selectedProblems)
        shipSelectionVC.selectedDifficulty = selectedDifficulty
        shipSelectionVC.isCustomMode = true
        shipSelectionVC.modalPresentationStyle = .fullScreen
        present(shipSelectionVC, animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

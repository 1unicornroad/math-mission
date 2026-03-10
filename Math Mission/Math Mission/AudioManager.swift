//
//  AudioManager.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    private enum ActiveMusicState {
        case none
        case menu
        case gameplay
    }
    
    private let menuMusicTargetVolume: Float = 0.22
    private let gameplayMusicTargetVolume: Float = 0.19
    private let crossfadeDuration: TimeInterval = 0.45
    private var menuMusicPlayer: AVAudioPlayer?
    private var thrusterPlayer: AVAudioPlayer?
    private var gameplayMusicPlayer: AVAudioPlayer?
    private var soundEffects: [String: AVAudioPlayer] = [:]
    private var activePlayers: [AVAudioPlayer] = []  // Keep strong references
    private var fadeTimers: [ObjectIdentifier: Timer] = [:]
    private var activeMusicState: ActiveMusicState = .none
    private var shouldResumeAfterInterruption = false
    
    private init() {
        setupAudio()
        observeAudioSessionNotifications()
    }
    
    func setupAudio() {
        // Configure audio session for playback and mixing
        // Use .playback category to ignore mute switch (like music/video apps)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Failed to setup audio session: \(error)")
        }

        if let menuURL = Bundle.main.url(forResource: "Retro Starfield Drift", withExtension: "mp3") {
            do {
                menuMusicPlayer = try AVAudioPlayer(contentsOf: menuURL)
                menuMusicPlayer?.numberOfLoops = -1
                menuMusicPlayer?.volume = 0.0
                menuMusicPlayer?.prepareToPlay()
            } catch {
                print("⚠️ Failed to load menu music: \(error)")
            }
        }
        
        // Prepare background thruster loop
        if let thrusterURL = Bundle.main.url(forResource: "thrusterFire_000", withExtension: "wav") {
            do {
                thrusterPlayer = try AVAudioPlayer(contentsOf: thrusterURL)
                thrusterPlayer?.numberOfLoops = -1 // Infinite loop
                thrusterPlayer?.volume = 0.12  // Low background hum
                thrusterPlayer?.prepareToPlay()
            } catch {
                print("⚠️ Failed to load thruster sound: \(error)")
            }
        }

        if let musicURL = Bundle.main.url(forResource: "Starfield Burn", withExtension: "mp3") {
            do {
                gameplayMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                gameplayMusicPlayer?.numberOfLoops = -1
                gameplayMusicPlayer?.volume = 0.0
                gameplayMusicPlayer?.prepareToPlay()
            } catch {
                print("⚠️ Failed to load gameplay music: \(error)")
            }
        }
        
        // Preload sound effects
        let soundFiles = [
            "laserSmall_000",
            "explosionCrunch_000",
            "laserLarge_001",
            "explosionCrunch_002",
            "forceField_000"
        ]
        
        for sound in soundFiles {
            if let url = Bundle.main.url(forResource: sound, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    soundEffects[sound] = player
                } catch {
                    print("⚠️ Failed to load sound \(sound): \(error)")
                }
            }
        }
    }
    
    private func observeAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }
        
        switch interruptionType {
        case .began:
            shouldResumeAfterInterruption = activeMusicState != .none
        case .ended:
            let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            guard shouldResumeAfterInterruption, options.contains(.shouldResume) else {
                shouldResumeAfterInterruption = false
                return
            }
            
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("⚠️ Failed to reactivate audio session: \(error)")
            }
            
            shouldResumeAfterInterruption = false
            resumeActiveMusic()
        @unknown default:
            break
        }
    }
    
    private func resumeActiveMusic() {
        switch activeMusicState {
        case .menu:
            guard let menuMusicPlayer else { break }
            startLoopIfNeeded(menuMusicPlayer)
            fade(player: menuMusicPlayer, to: menuMusicTargetVolume, duration: 0.25)
        case .gameplay:
            guard let gameplayMusicPlayer else { break }
            startLoopIfNeeded(gameplayMusicPlayer)
            fade(player: gameplayMusicPlayer, to: gameplayMusicTargetVolume, duration: 0.25)
        case .none:
            break
        }
    }
    
    func startThruster() {
        thrusterPlayer?.play()
    }
    
    func stopThruster() {
        thrusterPlayer?.stop()
    }

    func startMenuMusic() {
        guard let menuMusicPlayer else { return }
        activeMusicState = .menu
        fadeOut(player: gameplayMusicPlayer, duration: crossfadeDuration)
        startLoopIfNeeded(menuMusicPlayer)
        fade(player: menuMusicPlayer, to: menuMusicTargetVolume, duration: crossfadeDuration)
    }

    func stopMenuMusic() {
        if activeMusicState == .menu {
            activeMusicState = .none
        }
        fadeOut(player: menuMusicPlayer, duration: 0.22)
    }

    func startGameplayMusic() {
        guard let gameplayMusicPlayer else { return }
        activeMusicState = .gameplay
        fadeOut(player: menuMusicPlayer, duration: crossfadeDuration)
        startLoopIfNeeded(gameplayMusicPlayer)
        fade(player: gameplayMusicPlayer, to: gameplayMusicTargetVolume, duration: crossfadeDuration)
    }

    func stopGameplayMusic() {
        if activeMusicState == .gameplay {
            activeMusicState = .none
        }
        fadeOut(player: gameplayMusicPlayer, duration: 0.22)
    }
    
    func playLaserFire() {
        playSoundEffect("laserSmall_000", volume: 0.4)
    }
    
    func playMeteorExplosion() {
        playSoundEffect("explosionCrunch_000", volume: 0.5)
    }
    
    func playShipHit() {
        playSoundEffect("explosionCrunch_002", volume: 0.6)
    }
    
    func playShipExplosion() {
        playSoundEffect("laserLarge_001", volume: 0.7)
    }
    
    func playButtonTap() {
        playSoundEffect("forceField_000", volume: 0.42)
    }
    
    private func playSoundEffect(_ name: String, volume: Float) {
        // Create new player instance to allow overlapping sounds
        if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.prepareToPlay()
                
                // Keep strong reference while playing
                activePlayers.append(player)
                player.play()
                
                // Remove reference after playback finishes
                let duration = player.duration
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { [weak self] in
                    self?.activePlayers.removeAll { $0 === player }
                }
            } catch {
                print("⚠️ Failed to play sound \(name): \(error)")
            }
        }
    }

    private func startLoopIfNeeded(_ player: AVAudioPlayer) {
        if !player.isPlaying {
            player.play()
        }
    }

    private func fadeOut(player: AVAudioPlayer?, duration: TimeInterval) {
        fade(player: player, to: 0.0, duration: duration, stopWhenFinished: true)
    }

    private func fade(
        player: AVAudioPlayer?,
        to targetVolume: Float,
        duration: TimeInterval,
        stopWhenFinished: Bool = false
    ) {
        guard let player else { return }

        let playerID = ObjectIdentifier(player)
        fadeTimers[playerID]?.invalidate()
        fadeTimers[playerID] = nil

        let steps = max(Int(duration / 0.05), 1)
        let startingVolume = player.volume
        let delta = targetVolume - startingVolume

        if steps == 1 || abs(delta) < 0.001 {
            player.volume = targetVolume
            if stopWhenFinished && targetVolume <= 0.001 {
                player.stop()
            }
            return
        }

        var currentStep = 0
        let timer = Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { [weak self, weak player] timer in
            guard let self, let player else {
                timer.invalidate()
                return
            }

            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            player.volume = startingVolume + delta * progress

            if currentStep >= steps {
                timer.invalidate()
                self.fadeTimers[playerID] = nil
                player.volume = targetVolume
                if stopWhenFinished && targetVolume <= 0.001 {
                    player.stop()
                }
            }
        }

        fadeTimers[playerID] = timer
        RunLoop.main.add(timer, forMode: .common)
    }
}

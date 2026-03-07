//
//  AudioManager.swift
//  Math Mission
//
//  Created by John Ostler on 3/6/26.
//

import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    private var thrusterPlayer: AVAudioPlayer?
    private var soundEffects: [String: AVAudioPlayer] = [:]
    private var activePlayers: [AVAudioPlayer] = []  // Keep strong references
    
    private init() {
        setupAudio()
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
        
        // Preload sound effects
        let soundFiles = [
            "laserSmall_000",
            "explosionCrunch_000",
            "laserLarge_001",
            "explosionCrunch_002"
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
    
    func startThruster() {
        thrusterPlayer?.play()
    }
    
    func stopThruster() {
        thrusterPlayer?.stop()
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
}

//
//  GameScene.swift
//  OrbitZen
//
//  Created by malva on 10/12/25.
//
import SpriteKit
import SwiftUI

class GameScene: SKScene {
    // MARK: - Game State
    enum GameState {
        case start, playing, gameOver
    }
    
    var gameState: GameState = .start
    var score: Int = 0
    var frames: Int = 0
    
    // MARK: - Config
    let orbitRadius: CGFloat = 60.0 // Adjusted for smaller Watch screen
    let orbSize: CGFloat = 5.0
    let baseSpeed: CGFloat = 0.05
    let obstacleSpeed: CGFloat = 1.0
    
    // MARK: - Smart Nodes
    var centerCore: SKShapeNode!
    var orbitLine: SKShapeNode!
    var orb: SKShapeNode!
    var titleOrbit: SKLabelNode!
    var titleZen: SKLabelNode!
    var scoreLabel: SKLabelNode!
    var startLabel: SKLabelNode!
    var gameOverLabel: SKLabelNode!
    
    // MARK: - Data
    struct Obstacle {
        var node: SKShapeNode
        var gapStart: CGFloat
        var gapSize: CGFloat
        var radius: CGFloat
        var passed: Bool
    }
    
    var obstacles: [Obstacle] = []
    
    // Orb properties
    var orbAngle: CGFloat = 0
    var orbDirection: CGFloat = 1 // 1 or -1
    
    override func sceneDidLoad() {
        backgroundColor = .black
        setupScene()
    }
    
    func setupScene() {
        // Center Core
        centerCore = SKShapeNode(circleOfRadius: 6)
        centerCore.fillColor = .darkGray
        centerCore.strokeColor = .clear
        addChild(centerCore)
        
        // Orbit Line
        orbitLine = SKShapeNode(circleOfRadius: orbitRadius)
        orbitLine.strokeColor = UIColor(white: 0.2, alpha: 1.0)
        orbitLine.lineWidth = 1
        addChild(orbitLine)
        
        // Orb
        orb = SKShapeNode(circleOfRadius: orbSize)
        orb.fillColor = .cyan
        orb.strokeColor = .clear
        // Add a neon glow effect
        let glow = SKShapeNode(circleOfRadius: orbSize + 4)
        glow.fillColor = UIColor.cyan.withAlphaComponent(0.4)
        glow.strokeColor = .clear
        orb.addChild(glow)
        addChild(orb)
        
        // Add Comet Trail
        setupTrail()
        
        // UI: Title ORBIT
        titleOrbit = SKLabelNode(fontNamed: "HelveticaNeue-CondensedBlack")
        titleOrbit.fontSize = 32
        titleOrbit.text = "ORBIT"
        titleOrbit.fontColor = .cyan
        titleOrbit.position = CGPoint(x: 0, y: 15)
        addChild(titleOrbit)
        
        // UI: Title ZEN
        titleZen = SKLabelNode(fontNamed: "HelveticaNeue-CondensedBlack")
        titleZen.fontSize = 32
        titleZen.text = "ZEN"
        titleZen.fontColor = .green
        titleZen.position = CGPoint(x: 0, y: -25)
        addChild(titleZen)
        
        // UI: Score
        scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = UIColor(white: 1.0, alpha: 0.3)
        scoreLabel.position = CGPoint(x: 0, y: 70)
        scoreLabel.text = "0"
        addChild(scoreLabel)
        
        // UI: Start
        startLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        startLabel.fontSize = 14
        startLabel.text = "TAP TO START"
        startLabel.position = CGPoint(x: 0, y: -70)
        startLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
        ])))
        addChild(startLabel)
        
        // UI: Game Over
        gameOverLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        gameOverLabel.fontSize = 18
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 0)
        gameOverLabel.alpha = 0
        addChild(gameOverLabel)
        
        resetGame()
    }
    
    // MARK: - Game Logic
    
    func startGame() {
        gameState = .playing
        score = 0
        frames = 0
        orbAngle = 0
        scoreLabel.text = "0"
        
        // Clear obstacles
        obstacles.forEach { $0.node.removeFromParent() }
        obstacles.removeAll()
        
        // Fix: Remove blinking action so alpha = 0 sticks
        startLabel.removeAllActions()
        startLabel.alpha = 0
        
        titleOrbit.alpha = 0
        titleZen.alpha = 0
        gameOverLabel.alpha = 0
    }
    
    func resetGame() {
        gameState = .start
        
        titleOrbit.alpha = 1
        titleZen.alpha = 1
        
        startLabel.text = "TAP TO START"
        startLabel.alpha = 1
        startLabel.removeAllActions()
        startLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
        ])))
        
        gameOverLabel.alpha = 0
    }
    
    func failGame() {
        gameState = .gameOver
        gameOverLabel.alpha = 1
        
        // Show restart text
        startLabel.text = "TAP TO RESTART"
        startLabel.alpha = 1
        startLabel.removeAllActions()
        startLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
        ])))
        
        // Haptic feedback would go here via WKInterfaceDevice
        #if os(watchOS)
        WKInterfaceDevice.current().play(.failure)
        #endif
        
        createExplosion(at: orb.position, color: orb.fillColor)
    }
    
    func handleTap() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
        
        if gameState == .start {
            startGame()
        } else if gameState == .playing {
            orbDirection *= -1
            // Optional: Visual flair like a small scale punch
            let scaleAction = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
            ])
            orb.run(scaleAction)
        } else if gameState == .gameOver {
            resetGame()
            startGame() // Instant restart
        }
    }
    
    // MARK: - Update Loop
    
    override func update(_ currentTime: TimeInterval) {
        if gameState != .playing { return }
        
        frames += 1
        
        // 1. Move Orb
        orbAngle += baseSpeed * orbDirection
        // Normalize
        orbAngle = orbAngle.truncatingRemainder(dividingBy: .pi * 2)
        
        let ox = cos(orbAngle) * orbitRadius
        let oy = sin(orbAngle) * orbitRadius
        orb.position = CGPoint(x: ox, y: oy)
        
        // Update Trail Rotation to face opposite of movement
        // Tangent angle + 180 degrees
        // Tangent of circle at angle theta is theta + pi/2
        // So opposite is theta + pi/2 + pi = theta - pi/2
        if let trail = orb.childNode(withName: "trail") as? SKEmitterNode {
            let rotation = orbAngle + (orbDirection > 0 ? CGFloat.pi / 2 : -CGFloat.pi / 2)
            trail.emissionAngle = rotation + CGFloat.pi // Shoot backwards
        }
        
        // Color cycle
        let hue = CGFloat(frames % 360) / 360.0
        let newColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        orb.fillColor = newColor
        if let glow = orb.children.first as? SKShapeNode {
            glow.fillColor = newColor.withAlphaComponent(0.4)
        }
        // Update trail color too
        if let trail = orb.childNode(withName: "trail") as? SKEmitterNode {
            trail.particleColor = newColor
        }
        
        // 2. Spawn Obstacles
        let spawnRate = max(60, 150 - (score * 2))
        if frames % spawnRate == 0 {
            spawnObstacle()
        }
        
        // 3. Update Obstacles & Collision
        updateObstacles()
    }
    

    
    func spawnObstacle() {
        let gapSize = max(CGFloat.pi / 4, CGFloat.pi / 1.5 - (CGFloat(score) * 0.01))
        let gapStart = CGFloat.random(in: 0...(CGFloat.pi * 2))
        
        // Start from center
        let radius: CGFloat = 0
        
        // Create visual representation
        // We need to draw an arc. In SpriteKit, SKShapeNode with path.
        let obstacleNode = SKShapeNode()
        obstacleNode.lineWidth = 4
        obstacleNode.strokeColor = UIColor(hue: CGFloat(frames % 360) / 360.0, saturation: 1.0, brightness: 0.8, alpha: 1.0)
        obstacleNode.lineCap = .round
        addChild(obstacleNode)
        
        let obs = Obstacle(node: obstacleNode, gapStart: gapStart, gapSize: gapSize, radius: radius, passed: false)
        obstacles.append(obs)
    }
    
    func updateObstacles() {
        for (index, var obs) in obstacles.enumerated().reversed() {
            obs.radius += obstacleSpeed + (CGFloat(score) * 0.005)
            
            // Re-draw path at new radius
            let path = UIBezierPath()
            // Draw arc from (gapStart + gapSize) to gapStart (inverted to be the solid part)
            // SpriteKit angles are standard regular radians.
            // A full circle is 0 to 2pi.
            // We want to draw everything BUT the gap.
            // So we draw from gapStart + gapSize ... around to ... gapStart
            
            path.addArc(withCenter: .zero, radius: obs.radius, startAngle: obs.gapStart + obs.gapSize, endAngle: obs.gapStart, clockwise: true)
            // Note: clockwise true in UIBezierPath might mean regular counter-clockwise in math depending on coordinate system, but let's assume standard behavior for now.
            
            obs.node.path = path.cgPath
            
            // Collision Logic
            // Check if obstacle radius intersects orbit radius
            let dist = abs(obs.radius - orbitRadius)
            
            if dist < (orbSize + 2) && !obs.passed {
                // Check if Orb Angle is INSIDE the gap
                // Normalize orb angle to 0..2pi positive
                var currentAngle = orbAngle
                while currentAngle < 0 { currentAngle += .pi * 2 }
                while currentAngle > .pi * 2 { currentAngle -= .pi * 2 }
                
                // Gap center
                let gapCenter = obs.gapStart + obs.gapSize / 2
                let diff = angleDifference(currentAngle, gapCenter)
                
                if abs(diff) > obs.gapSize / 2 {
                    // Hit the wall!
                    failGame()
                }
            }
            
            if obs.radius > orbitRadius + 10 && !obs.passed {
                obs.passed = true
                score += 1
                scoreLabel.text = "\(score)"
                obstacles[index] = obs // Save state back
                
                // Success Haptic
                #if os(watchOS)
                WKInterfaceDevice.current().play(.success)
                #endif
            } else {
                obstacles[index] = obs // Save update radius back
            }
            
            // Remove if off screen
            if obs.radius > 200 {
                obs.node.removeFromParent()
                obstacles.remove(at: index)
            }
        }
    }
    
    func angleDifference(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        var diff = a - b
        while diff < -.pi { diff += .pi * 2 }
        while diff > .pi { diff -= .pi * 2 }
        return diff
    }
    
    func setupTrail() {
        let trail = SKEmitterNode()
        trail.name = "trail"
        trail.targetNode = self // Particles stay in world space
        
        // Use a simple blurred circle for smooth light trail
        if let particleImage = UIImage(systemName: "circle.fill") {
             trail.particleTexture = SKTexture(image: particleImage)
        } else {
             trail.particleTexture = createSparkTexture()
        }
        
        trail.particleBirthRate = 60
        trail.particleLifetime = 0.4
        trail.particleLifetimeRange = 0.1
        trail.particlePositionRange = CGVector(dx: 2, dy: 2)
        
        // Movement: The particles should just "stay" and fade, effectively creating a trail as emitter moves
        trail.particleSpeed = 0
        trail.particleAlpha = 0.6
        trail.particleAlphaSpeed = -1.5
        trail.particleScale = 0.08
        trail.particleScaleSpeed = -0.1 // Shrink over time
        trail.particleColorBlendFactor = 1.0
        trail.particleColor = .cyan // Will be updated in loop
        
        orb.addChild(trail)
    }

    func createExplosion(at point: CGPoint, color: UIColor) {
        // 1. Star Burst Particles
        let emitter = SKEmitterNode()
        if let starImage = UIImage(systemName: "star.fill") {
            emitter.particleTexture = SKTexture(image: starImage)
        } else {
            emitter.particleTexture = createSparkTexture()
        }
        
        emitter.particleBirthRate = 2000 
        emitter.numParticlesToEmit = 60
        emitter.particleLifetime = 0.8
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 70
        emitter.particleSpeedRange = 30
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = color
        emitter.particleScale = 0.12
        emitter.particleScaleSpeed = -0.1
        emitter.particleAlphaSpeed = -1.0
        emitter.position = point
        addChild(emitter)
        
        let removeEmitter = SKAction.sequence([.wait(forDuration: 1.5), .removeFromParent()])
        emitter.run(removeEmitter)
        
        // 2. Expanding Shockwaves (Hondas)
        for i in 0..<3 {
            let ripple = SKShapeNode(circleOfRadius: 10)
            ripple.strokeColor = color
            ripple.lineWidth = 3
            ripple.fillColor = .clear
            ripple.position = point
            ripple.alpha = 1.0
            addChild(ripple)
            
            // Staggered animation
            let delay = SKAction.wait(forDuration: TimeInterval(i) * 0.15)
            let scale = SKAction.scale(to: 4.0, duration: 0.6)
            let fade = SKAction.fadeOut(withDuration: 0.6)
            let group = SKAction.group([scale, fade])
            let remove = SKAction.removeFromParent()
            
            ripple.run(SKAction.sequence([delay, group, remove]))
        }
    }
    
    func createSparkTexture() -> SKTexture {
        let dimension: CGFloat = 8
        let size = CGSize(width: dimension, height: dimension)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
}


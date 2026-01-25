import SpriteKit
//import WatchKit
import UIKit
//https://xfcf1.github.io/
class MindDemonScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - 外部参数
    var gameLevel: Int = 1
    var onGameOver: ((Bool) -> Void)?
    
    // MARK: - Game Config
    private struct GameConfig {
        static let wheelRadius: CGFloat = 45.0
        static let pinLength: CGFloat = 40
        static let pinWidth: CGFloat = 7.0
        
        static let baseRotationDuration: TimeInterval = 3.0
        static let minRotationDuration: TimeInterval = 1.0
        
        // Difficulty tunings
        // Returns: (rotationSpeed, isVariable, winCount)
        static func getDifficulty(level: Int) -> (rotationSpeed: TimeInterval, isVariable: Bool, winCount: Int) {
            // Stage 0 (Zhuji): Level 1-9
            // Stage 1 (Kaiguang): Level 10-18
            // Stage 2 (Taixi): Level 19-27
            // Stage 3 (Bigu): Level 28-36
            let stage = (level - 1) / 9
          
            print("getDifficulty-stage",stage)
            print("getDifficulty-level",level)
          
            switch stage {
            case 0:
                // Level 9 Breakthrough
                return (3.0, false, 6)
            case 1:
                // Level 18 Breakthrough
                return (2.5, false, 7)
            case 2:
                // Level 27 Breakthrough
                return (2.0, true, 8)
            default:
                // Level 36+ Breakthroughs
                return (1.5, true, 9)
            }
        }
    }
    
    // MARK: - Physics Categories
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let wheel: UInt32 = 0b1
        static let pin: UInt32 = 0b10         // The flying pin
        static let pinStuck: UInt32 = 0b100   // The pin stuck in wheel
    }
    
    // MARK: - Game State
    private var isGameOverState = false
    private var successfulPins = 0
    private var requiredPins = 6
    private var lastRotationWasClockwise = true
    
    // MARK: - Nodes
    private var wheel: SKSpriteNode!
    private var centerLabel: SKLabelNode?
    private var readyPin: SKNode?
    
    // MARK: - Lifecycle
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        
       // setupGame()
        print("Scene loaded. Size: \(size)")
    }
    
    func setupGame() {
        backgroundColor = .black
        isGameOverState = false
        successfulPins = 0
        removeAllChildren()
        
        // Load dynamic difficulty
        let diff = GameConfig.getDifficulty(level: gameLevel)
        requiredPins = diff.winCount
        
        print("requiredPins",diff.winCount)
        print("requiredPins",requiredPins)
        
        setupWheel()
        startRotation(duration: diff.rotationSpeed, variable: diff.isVariable)
        spawnReadyPin()
      
        setupBackgroundParticles()
        startAmbientLightning() // ⚡️ 启动环境雷特效
    }
  
    private func setupBackgroundParticles() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark") // 用个模糊的小圆点
        emitter.particleBirthRate = 2
        emitter.particleLifetime = 10
        emitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        emitter.position = CGPoint(x: size.width/2, y: size.height/2)
        emitter.zPosition = 1
        emitter.particleColor = .gray
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlpha = 0.1 // 🔥 非常淡，似有若无
        emitter.particleScale = 0.05
        emitter.particleSpeed = 5
        emitter.zPosition = -10
        
        addChild(emitter)
    }
    
    // ⚡️ 启动环境雷电循环
    private func startAmbientLightning() {
        let randomDelay = Double.random(in: 2.0...5.0)
        run(SKAction.sequence([
            SKAction.wait(forDuration: randomDelay),
            SKAction.run { [weak self] in
                guard let self = self, !self.isGameOverState else { return }
                
                // 30% 概率触发大雷，70% 只是背景闪
                // 这里简单点，直接触发我们在 file bottom 定义的 triggerLightning
                // 为了不干扰视线，我们可以把 alpha 调低一点，或者在 createLightningBolt 里改
                self.triggerLightning()
                
                // Audio feedback (optional, maybe quieter)
                // SkyAudio.shared.playSoundEffects("thunder") 
                
                // Recursive loop
                self.startAmbientLightning()
            }
        ]), withKey: "ambientLightning")
    }
    
        
    private func setupWheel() {
        // Try to load timber image, otherwise fallback to shape
        // Using "timber" as requested placeholder for now (will be Mind Demon Eye)
        if let _ = UIImage(named: "timber") {
             wheel = SKSpriteNode(imageNamed: "timber")
        } else {
             // Fallback if asset missing
          wheel = SKSpriteNode(color: .purple, size: CGSize(width: GameConfig.wheelRadius*2, height: GameConfig.wheelRadius*2*0.93))
        }
       
        wheel.size = CGSize(width: GameConfig.wheelRadius*2, height: GameConfig.wheelRadius*2)
        wheel.position = CGPoint(x: frame.midX, y: frame.midY + GameConfig.wheelRadius/2)
        wheel.zPosition = 10
        wheel.name = "wheel"
        
        // Physics for wheel
        wheel.physicsBody = SKPhysicsBody(circleOfRadius: GameConfig.wheelRadius)
        wheel.physicsBody?.isDynamic = false
        wheel.physicsBody?.categoryBitMask = PhysicsCategory.wheel
        wheel.physicsBody?.contactTestBitMask = PhysicsCategory.pin
        wheel.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(wheel)
        
        // Add a "demon eye" look if using basic shape, or just label
//        let eyeLabel = SKLabelNode(text: "👁️")
//        eyeLabel.fontSize = 24
//        eyeLabel.verticalAlignmentMode = .center
//        eyeLabel.position = .zero
//        wheel.addChild(eyeLabel)
        
        // Display required count
        updateCenterLabel()
    }
    
    private func updateCenterLabel() {
        centerLabel?.removeFromParent()
        
        let remaining = requiredPins - successfulPins
        centerLabel = SKLabelNode(fontNamed: "Courier-Bold")
        centerLabel?.fontSize = 15
        centerLabel?.fontColor = .white
//        centerLabel?.text = "\(remaining)"
        centerLabel?.text = "\(successfulPins)/\(requiredPins)"
        #if os(watchOS)
        centerLabel?.position = CGPoint(x: GameConfig.wheelRadius, y: frame.minY + GameConfig.pinLength / 2)
        #elseif os(iOS)
        centerLabel?.position = CGPoint(x: GameConfig.wheelRadius, y: frame.minY + GameConfig.pinLength * 1.2)
        #endif
        centerLabel?.zPosition = 5
        addChild(centerLabel!)
         
    }
    
    private func startRotation(duration: TimeInterval, variable: Bool) {
        wheel.removeAllActions()
        
        if variable {
            // Variable/Chaotic rotation logic
            applyVariableRotation(baseDuration: duration)
        } else {
            // Constant rotation
            let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: duration)
            wheel.run(SKAction.repeatForever(rotateAction))
        }
    }
    
    private func applyVariableRotation(baseDuration: TimeInterval) {
        // Recursive function to apply changing rotation patterns
        let patterns: [SKAction] = [
            SKAction.rotate(byAngle: .pi * 2, duration: baseDuration), // Normal
            SKAction.rotate(byAngle: -.pi * 2, duration: baseDuration * 1.5), // Reverse Slow
            SKAction.sequence([ // Fast burst then stop
                SKAction.rotate(byAngle: .pi, duration: baseDuration * 0.3),
                SKAction.wait(forDuration: 0.5)
            ])
        ]
        
        let selectedAction = patterns.randomElement()!
        
        wheel.run(selectedAction) { [weak self] in
            guard let self = self, !self.isGameOverState else { return }
            self.applyVariableRotation(baseDuration: baseDuration)
        }
    }
    
    // MARK: - Actions
    
    // MARK: - Actions
    
    private func spawnReadyPin() {
        let pinContainer = SKNode()
      pinContainer.position = CGPoint(x: frame.midX, y: frame.minY + GameConfig.pinLength/1.5)
        pinContainer.zPosition = 20
        
        // Graphic: Gold sword/kunai
        let pinVisual: SKNode
        if let _ = UIImage(named: "kunai") {
            let sprite = SKSpriteNode(imageNamed: "kunai")
            sprite.size = CGSize(width: GameConfig.pinWidth , height: GameConfig.pinLength)
            pinVisual = sprite
        } else {
            let shape = SKShapeNode(rectOf: CGSize(width: GameConfig.pinWidth, height: GameConfig.pinLength))
            shape.fillColor = .yellow // Golden sword color
            shape.strokeColor = .orange
            pinVisual = shape
        }
        
        pinVisual.zRotation = 0
        pinContainer.addChild(pinVisual)
        
        addChild(pinContainer)
        readyPin = pinContainer
        
        // Pop in animation
        pinContainer.setScale(0)
        pinContainer.run(SKAction.scale(to: 1.0, duration: 0.1))
    }
    
    func fireNeedle() {
        guard !isGameOverState, let currentPin = readyPin else { return }
        
        readyPin = nil // clear reference so we don't fire it again
                

        // Physics Body
        currentPin.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: GameConfig.pinWidth, height: GameConfig.pinLength))
        currentPin.physicsBody?.isDynamic = true
        currentPin.physicsBody?.affectedByGravity = false
        currentPin.physicsBody?.categoryBitMask = PhysicsCategory.pin
        currentPin.physicsBody?.contactTestBitMask = PhysicsCategory.wheel | PhysicsCategory.pinStuck
        currentPin.physicsBody?.collisionBitMask = PhysicsCategory.none
        currentPin.physicsBody?.usesPreciseCollisionDetection = true
        
        // Shoot upwards
        let moveAction = SKAction.move(to: CGPoint(x: frame.midX, y: frame.midY), duration: 0.15)
        currentPin.run(moveAction)
        
        // Play sound
        
        // Spawn next pin after delay
        run(SKAction.wait(forDuration: 0.2)) { [weak self] in
            guard let self = self, !self.isGameOverState else { return }
            self.spawnReadyPin()
        }
    }
    
    // MARK: - Physics Delegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOverState else { return }
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Case 1: Pin hits Wheel -> Success
        if firstBody.categoryBitMask == PhysicsCategory.wheel && secondBody.categoryBitMask == PhysicsCategory.pin {
            if let pinNode = secondBody.node {
                handlePinStick(pinNode)
            }
        }
        
        // Case 2: Pin hits another Pin -> Fail
        if (firstBody.categoryBitMask == PhysicsCategory.pin && secondBody.categoryBitMask == PhysicsCategory.pinStuck) ||
            (firstBody.categoryBitMask == PhysicsCategory.pinStuck && secondBody.categoryBitMask == PhysicsCategory.pin) ||
            (firstBody.categoryBitMask == PhysicsCategory.pin && secondBody.categoryBitMask == PhysicsCategory.pin) {
             
          
          // 找到那根正在飞的针
            let flyingNode = (firstBody.categoryBitMask == PhysicsCategory.pin) ? firstBody.node : secondBody.node
            
            if let pin = flyingNode {
              // 🔥 核心修改：不再移除，而是弹飞
              bounceOff(pin)
            }
          
             handleGameOver(win: false)
          
             SkyAudio.shared.playSoundEffects("KnifeHitFail")

        }
    }
  
    private func bounceOff(_ pin: SKNode) {
        // 1. 停止之前的"向上飞"动作
        pin.removeAllActions()
        
        // 2. 修改物理属性：让它变成一个死物，但这受重力影响
        pin.physicsBody?.categoryBitMask = 0 // 变成无类别，防止二次碰撞
        pin.physicsBody?.contactTestBitMask = 0
        pin.physicsBody?.collisionBitMask = 0
        
        pin.physicsBody?.affectedByGravity = true // 开启重力，让它掉下去
        pin.physicsBody?.isDynamic = true
        
        // 3. 施加反弹力 (Impulse)
        // 向下弹 (dy: -5) + 随机左右弹 (dx: -3...3)
        let kickX = CGFloat.random(in: -5...5)
        let kickY = CGFloat(-2.0) // 向下弹
        pin.physicsBody?.applyImpulse(CGVector(dx: kickX, dy: kickY))
        
        // 4. 施加旋转力 (让它转着掉下去，更真实)
        let spin = CGFloat.random(in: -0.5...0.5)
        pin.physicsBody?.applyAngularImpulse(spin)
        
        // 5. 几秒后自动销毁 (防止内存泄漏)
        pin.run(SKAction.sequence([
          SKAction.wait(forDuration: 1.0),
          SKAction.fadeOut(withDuration: 0.2),
          SKAction.removeFromParent()
        ]))
    }
  
    private func handlePinStick(_ pinNode: SKNode) {
        // Remove physics from the flying pin so it doesn't trigger more collisions
        pinNode.physicsBody = nil
        pinNode.removeFromParent()
              
        SkyAudio.shared.playSoundEffects("KnifeHit")
        // Create a new static pin attached to the wheel container
        // We need to convert the position to the wheel's coordinate system
        // But since we collided exactly at the wheel radius/surface (conceptually)
        // We simplify: append it to wheel at the correct angle.
        
        // Since we shoot straight up, the contact point is roughly (midX, midY - radius) RELATIVE to scene?
        // Actually simpler: The wheel is rotating. The pin hits at bottom relative to screen?
        // Wait, the wheel is at center. We shoot from bottom.
        // So contact is at (0, -Radius) relative to Wheel if Wheel wasn't rotated.
        // But wheel IS rotated.
        
        let angle = wheel.zRotation
        
        // Create container for the struck pin
        let stuckPin = SKNode()
        // stuckPin.position = will be set later
        
        // Add visual stick
        if let _ = UIImage(named: "kunai") {
            let sprite = SKSpriteNode(imageNamed: "kunai")
            sprite.size = CGSize(width: GameConfig.pinWidth , height: GameConfig.pinLength)
            stuckPin.addChild(sprite)
        } else {
             let shape = SKShapeNode(rectOf: CGSize(width: GameConfig.pinWidth, height: GameConfig.pinLength))
             shape.fillColor = .yellow
             stuckPin.addChild(shape)
        }

        // Now the tricky part: We simply add stuckPin to wheel.
        // However, `wheel` is rotating. If we just add it at (0, -radius), it will be fixed relative to rotation.
        // But we want it to land where it HIT.
        // Since the pin always comes from bottom center, and we add it to the wheel,
        // we just need to compensate for the wheel's CURRENT rotation so it appears at the bottom initially.
        
        // Correct math:
        // We want world position to be (midX, midY - radius).
        // We convert that world pos to wheel's node space.
        let contactPosWorld = CGPoint(x: frame.midX, y: frame.midY - GameConfig.pinLength/2 - 5)
        let localPos = wheel.convert(contactPosWorld, from: self)
        
        stuckPin.position = localPos
        
        // Also rotate the pin to point towards center?
        // Since we shoot straight up, the pin is vertical.
        // We need its local rotation + wheel's rotation = 0 (vertical).
        // So localRot = -wheelRot
        stuckPin.zRotation = -wheel.zRotation
        
        // Add physics to this new stuck pin so NEXT pins can hit it
        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: GameConfig.pinWidth, height: GameConfig.pinLength))
        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = PhysicsCategory.pinStuck
        physicsBody.contactTestBitMask = PhysicsCategory.pin
        physicsBody.collisionBitMask = PhysicsCategory.none
        stuckPin.physicsBody = physicsBody
        stuckPin.zPosition = -1

        wheel.addChild(stuckPin)
        
        // Game Logic Update
        successfulPins += 1
        updateCenterLabel()
        
        // Check Win
        if successfulPins >= requiredPins {
            handleGameOver(win: true)
        } else {
            // Speed up slightly or flash effect
             wheel.run(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.05),
                SKAction.scale(to: 1.0, duration: 0.05)
             ]))
        }
    }
    
    private func handleGameOver(win: Bool) {
        isGameOverState = true
        wheel.removeAllActions()
        
        if !win {
          
            // Shake effect
            let shake = SKAction.sequence([
                SKAction.moveBy(x: -5, y: 0, duration: 0.05),
                SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                SKAction.moveBy(x: -5, y: 0, duration: 0.05)
            ])
            wheel.run(shake)
            
            // Red flash
            let flash = SKSpriteNode(color: .red, size: size)
            flash.position = CGPoint(x: frame.midX, y: frame.midY)
            flash.alpha = 0
            addChild(flash)
            flash.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.1),
                SKAction.fadeAlpha(to: 0, duration: 0.2),
                SKAction.removeFromParent()
            ]))
          
            // ⚡️ 失败特效：雷劫降临
             run(SKAction.repeat(SKAction.sequence([
                 SKAction.run { self.triggerLightning() },
                 SKAction.wait(forDuration: 0.1)
             ]), count: 3))
        } else {
             // Win effect: shatter
             shatterWheel()
        }
        
        // Delay callback slightly
        run(SKAction.wait(forDuration: 1.0)) { [weak self] in
            self?.onGameOver?(win)
        }
    }
    
    private func shatterWheel() {
        
        // ⚡️ 成功特效：天雷破阵
         run(SKAction.repeat(SKAction.sequence([
             SKAction.run { self.triggerLightning() },
             SKAction.wait(forDuration: 0.15)
         ]), count: 4))
      
        // Enable gravity for the fall effect (will apply when we enable affectedByGravity on shards)
        physicsWorld.gravity = CGVector(dx: 0, dy: -10)
        
        // 1. Snapshot settings
        let currentRotation = wheel.zRotation
        let wheelPos = wheel.position
        let size = wheel.size
        
        // 2. Hide original wheel (and its children/pins)
        // Reparent children to scene to explode them
        for child in wheel.children {
             let worldPos = wheel.convert(child.position, from: wheel)
             let worldRot = child.zRotation + currentRotation
             
             // Move to scene
             child.move(toParent: self)
             child.position = worldPos
             child.zRotation = worldRot
             
             // Add physics if missing
             if child.physicsBody == nil {
                 child.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 10))
             }
             child.physicsBody?.isDynamic = true
             child.physicsBody?.affectedByGravity = false // Start floating to fly out
             
             // Initial "Burst" impulse - Stronger now
             let dx = worldPos.x - wheelPos.x
             let dy = worldPos.y - wheelPos.y
             // Normalize and scale
             let len = sqrt(dx*dx + dy*dy)
             let burstMag: CGFloat = 10.0 // Strong burst
             
             if len > 0 {
                 let vec = CGVector(dx: (dx/len) * burstMag, dy: (dy/len) * burstMag)
                 child.physicsBody?.applyImpulse(vec)
             }
            
             // Activate gravity after short delay
             child.run(SKAction.sequence([
                 SKAction.wait(forDuration: 0.2), // Fly out for 0.2s
                 SKAction.run { child.physicsBody?.affectedByGravity = true }, // Then fall
                 SKAction.wait(forDuration: 1.0),
                 SKAction.fadeOut(withDuration: 0.5),
                 SKAction.removeFromParent()
             ]))
        }
        
        wheel.isHidden = true
        wheel.physicsBody = nil
        
        // 3. Create Shards
        let rects = [
            CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5),   // TL
            CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5), // TR
            CGRect(x: 0, y: 0, width: 0.5, height: 0.5),     // BL
            CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)    // BR
        ]
        
        let offsets = [
            CGPoint(x: -0.25, y: 0.25),
            CGPoint(x: 0.25, y: 0.25),
            CGPoint(x: -0.25, y: -0.25),
            CGPoint(x: 0.25, y: -0.25)
        ]
        
        let texture = wheel.texture
        
        for (i, rect) in rects.enumerated() {
            let shard: SKSpriteNode
            if let tex = texture {
                let shardTex = SKTexture(rect: rect, in: tex)
                shard = SKSpriteNode(texture: shardTex)
                shard.size = CGSize(width: size.width/2, height: size.height/2)
            } else {
                shard = SKSpriteNode(color: .brown, size: CGSize(width: size.width/2, height: size.height/2))
            }
            
            // Position
            let off = offsets[i]
            let r = currentRotation
            let dx = off.x * size.width * cos(r) - off.y * size.height * sin(r)
            let dy = off.x * size.width * sin(r) + off.y * size.height * cos(r)
            
            shard.position = CGPoint(x: wheelPos.x + dx, y: wheelPos.y + dy)
            shard.zRotation = currentRotation
            shard.zPosition = wheel.zPosition
            
            // Physics
            shard.physicsBody = SKPhysicsBody(rectangleOf: shard.size)
            shard.physicsBody?.isDynamic = true
            shard.physicsBody?.affectedByGravity = false // Start floating
            shard.physicsBody?.collisionBitMask = 0
            
            addChild(shard)
            
            // Impulse: Strong Outward Burst
          let impulseMag: CGFloat = 10.0 // Stronger kick
            let len = sqrt(dx*dx + dy*dy)
            if len > 0 {
                // Pure radial burst first
                let vec = CGVector(dx: (dx/len)*impulseMag, dy: (dy/len)*impulseMag)
                shard.physicsBody?.applyImpulse(vec)
                shard.physicsBody?.applyAngularImpulse(CGFloat.random(in: -0.1...0.1))
            }
            
            // Cleanup & Gravity
            shard.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.15), // Fly out briefly
                SKAction.run { shard.physicsBody?.affectedByGravity = true }, // Then drop
                SKAction.wait(forDuration: 1.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }
    // MARK: - ⚡️ Lightning Effect (Pure Code)
    
    /// 触发一道随机闪电
    private func triggerLightning() {
        // 随机起点和终点
        let start = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height)
        let end = CGPoint(x: CGFloat.random(in: 0...size.width), y: 0)
        
        createLightningBolt(from: start, to: end)
      
        SkyAudio.shared.playSoundEffects("lightning")

    }
    
    /// 创建闪电节点
    private func createLightningBolt(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start)
        
        let dist = hypot(end.x - start.x, end.y - start.y)
        let stepCount = Int(dist / 10) // 每10个点一段
        
        let dx = (end.x - start.x) / CGFloat(stepCount)
        let dy = (end.y - start.y) / CGFloat(stepCount)
        
        for i in 0..<stepCount {
            // 基础推进
            var nextPoint = CGPoint(x: start.x + dx * CGFloat(i), y: start.y + dy * CGFloat(i))
            
            // 随机抖动 (Jaggedness)
            let jitter: CGFloat = 15.0
            if i != 0 && i != stepCount - 1 { // 头尾不抖
                nextPoint.x += CGFloat.random(in: -jitter...jitter)
                nextPoint.y += CGFloat.random(in: -jitter...jitter)
            }
            
            path.addLine(to: nextPoint)
        }
        path.addLine(to: end) // 确保连到终点
        
        // 绘制
        let bolt = SKShapeNode(path: path)
        bolt.strokeColor = .white
        bolt.lineWidth = 2.0
        bolt.glowWidth = 4.0 // 发光效果
        bolt.alpha = 0.8
        bolt.zPosition = 5 // 在 Label 下面，Wheel 上面
        bolt.lineCap = .round
        
        addChild(bolt)
        
        // 动画：闪烁后消失
        let fade = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.fadeIn(withDuration: 0.05),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        bolt.run(fade)
    }
}

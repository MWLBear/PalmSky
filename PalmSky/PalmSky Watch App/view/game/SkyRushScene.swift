import SpriteKit
import UIKit

private enum SkyRushLane: Int, CaseIterable {
    case left
    case center
    case right
}

private enum SkyRushNodeKind {
    static let hazard = "hazard"
    static let seal = "seal"
}

final class SkyRushScene: SKScene {
    var gameLevel: Int = 1
    var onGameOver: ((Bool) -> Void)?

    private var backgroundNode: SKSpriteNode!
    private var playerNode: SKShapeNode!
    private var shieldNode: SKShapeNode!
    private var statusLabel: SKLabelNode!

    private var laneXPositions: [CGFloat] = []
    private var currentLane: SkyRushLane = .center

    private var activeNodes: [SKNode] = []
    private var gameEnded = false
    private var hasStarted = false

    private var elapsedActive: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var spawnAccumulator: TimeInterval = 0

    private var gameDuration: TimeInterval = 16
    private var spawnInterval: TimeInterval = 1.2
    private var movementDuration: TimeInterval = 2.8
    private var targetSeals: Int = 6
    private var hazardChance: Double = 0.72
    private var doubleHazardChance: Double = 0.12
    // 顶部 HUD 需要避开 SwiftUI 外层关闭按钮热区，所以统一下压
    private let topHUDInset: CGFloat = 45

    private var collectedSeals = 0
    private var remainingLives = 2

    private let playerYRatio: CGFloat = -0.30
    private let collisionThresholdY: CGFloat = 20
    private let rushGold = UIColor(red: 1.0, green: 0.82, blue: 0.22, alpha: 1.0)
    private let rushTeal = UIColor(red: 0.20, green: 0.84, blue: 0.78, alpha: 1.0)
    private let sealGold = UIColor(red: 1.0, green: 0.92, blue: 0.64, alpha: 1.0)
    private let sealAzure = UIColor(red: 0.84, green: 0.95, blue: 1.0, alpha: 1.0)
    private let sealAmber = UIColor(red: 1.0, green: 0.76, blue: 0.42, alpha: 1.0)

    override func sceneDidLoad() {
        super.sceneDidLoad()
        scaleMode = .aspectFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        preloadSoundEffect()
    }

    func setupGame() {
        removeAllActions()
        removeAllChildren()
        activeNodes.removeAll()
        gameEnded = false
        hasStarted = false
        elapsedActive = 0
        lastUpdateTime = 0
        spawnAccumulator = 0
        collectedSeals = 0
        remainingLives = 2
        currentLane = .center

        applyDifficulty()
        setupBackground()
        setupLanes()
        setupPlayer()
        setupUI()
        setupAmbientEffect()
        startAmbientLightning(
            shouldContinue: { [weak self] in self?.gameEnded == false },
            trigger: { [weak self] in self?.triggerLightningEffect(playSound: true) }
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.hasStarted = true
        }
    }

    private func applyDifficulty() {
        // 飞升关只覆盖最后四个大境界：12~15 档，减去 12 后映射成 0~3 难度
        let stageIndex = max(0, min(3, (gameLevel - 1) / 9 - 12))

        switch stageIndex {
        case 0:
            gameDuration = 16
            targetSeals = 6
            spawnInterval = 1.08
            movementDuration = 2.65
            hazardChance = 0.72
            doubleHazardChance = 0.12
        case 1:
            gameDuration = 18
            targetSeals = 7
            spawnInterval = 0.98
            movementDuration = 2.42
            hazardChance = 0.76
            doubleHazardChance = 0.18
        case 2:
            gameDuration = 20
            targetSeals = 8
            spawnInterval = 0.90
            movementDuration = 2.24
            hazardChance = 0.81
            doubleHazardChance = 0.25
        default:
            gameDuration = 22
            targetSeals = 10
            spawnInterval = 0.82
            movementDuration = 2.05
            hazardChance = 0.85
            doubleHazardChance = 0.30
        }

        print(
            "SkyRush applyDifficulty -> level: \(gameLevel), stageIndex: \(stageIndex), " +
            "duration: \(gameDuration), targetSeals: \(targetSeals), " +
            "spawnInterval: \(spawnInterval), movementDuration: \(movementDuration), " +
            "hazardChance: \(hazardChance), doubleHazardChance: \(doubleHazardChance)"
        )
    }

    private func setupBackground() {
        backgroundNode = SKSpriteNode(color: .black, size: size)
        backgroundNode.position = .zero
        backgroundNode.zPosition = -20
        addChild(backgroundNode)
    }

    private func setupAmbientEffect() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleBirthRate = 6
        emitter.particleLifetime = 6
        emitter.particleLifetimeRange = 2
        emitter.particleAlpha = 0.12
        emitter.particleAlphaRange = 0.08
        emitter.particleScale = 0.05
        emitter.particleScaleRange = 0.02
        emitter.particleColor = .white
        emitter.particleColorBlendFactor = 1
        emitter.particleSpeed = 26
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = -.pi / 2
        emitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
        emitter.position = CGPoint(x: 0, y: size.height / 2 + 20)
        emitter.zPosition = -10
        addChild(emitter)

        // 极速飞升的背景速度线：向下坠落，模拟主角高速上升
        let speedLineEmitter = SKEmitterNode()
        speedLineEmitter.particleTexture = SKTexture(imageNamed: "spark")
        speedLineEmitter.particleBirthRate = 10
        speedLineEmitter.particleLifetime = 1.0
        speedLineEmitter.particleLifetimeRange = 0.25
        speedLineEmitter.particlePositionRange = CGVector(dx: size.width, dy: size.height * 0.6)
        speedLineEmitter.position = CGPoint(x: 0, y: size.height / 2 + 50)
        speedLineEmitter.particleSpeed = 400
        speedLineEmitter.particleSpeedRange = 100
        speedLineEmitter.particleAlpha = 0.16
        speedLineEmitter.particleAlphaRange = 0.06
        speedLineEmitter.particleScale = 0.22
        speedLineEmitter.particleScaleRange = 0.08
        speedLineEmitter.xScale = 0.15
        speedLineEmitter.yScale = 3.8
        speedLineEmitter.emissionAngle = -.pi / 2
        speedLineEmitter.emissionAngleRange = 0.08
        speedLineEmitter.zPosition = -15
        addChild(speedLineEmitter)

       // ✨ 新增：让极速线条预热 2 秒
        speedLineEmitter.advanceSimulationTime(2.0)
          // 同样，给慢速的背景粒子也预热一下 (因为寿命是 6 秒，预热 6 秒最均匀)
        emitter.advanceSimulationTime(6.0)
      
    }

    private func setupLanes() {
        let spread = size.width * 0.34
        laneXPositions = [-spread, 0, spread]

        for x in laneXPositions {
            // 天阶底光：先铺一层很淡的纵向辉光，让轨道不只是“线”
            let laneGlow = SKShapeNode(rectOf: CGSize(width: 16, height: size.height * 1.2), cornerRadius: 8)
            laneGlow.fillColor = rushGold.withAlphaComponent(0.08)
            laneGlow.strokeColor = .clear
            laneGlow.glowWidth = 5
            laneGlow.position = CGPoint(x: x, y: 0)
            laneGlow.zPosition = -7
            addChild(laneGlow)

            let laneLine = SKShapeNode(rectOf: CGSize(width: 2, height: size.height * 0.9), cornerRadius: 1)
            laneLine.fillColor = UIColor.white.withAlphaComponent(0.13)
            laneLine.strokeColor = .clear
            laneLine.position = CGPoint(x: x, y: 0)
            laneLine.zPosition = -5
            addChild(laneLine)
            
            // 天阶阶纹：用若隐若现的横纹暗示“踏阶登天”的层次。
            // 不直接移动主线，避免影响玩家判定；只让阶纹缓慢下流，制造主角持续上冲的错觉。
            let stepCount = 10
            let laneHeight = size.height * 0.82
            let stepSpacing = laneHeight / CGFloat(stepCount)
            let stepContainer = SKNode()
            stepContainer.position = CGPoint(x: x, y: 0)
            stepContainer.zPosition = -4
            addChild(stepContainer)
            
            for index in 0..<stepCount {
                let progress = CGFloat(index) / CGFloat(stepCount - 1)
                let step = SKShapeNode(rectOf: CGSize(width: 10, height: 1.5), cornerRadius: 0.75)
                step.fillColor = UIColor.white.withAlphaComponent(0.10)
                step.strokeColor = .clear
                step.position = CGPoint(
                    x: 0,
                    y: -laneHeight / 2 + laneHeight * progress
                )
                stepContainer.addChild(step)
            }
            
            stepContainer.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: -stepSpacing, duration: 0.32),
                SKAction.run { stepContainer.position.y += stepSpacing }
            ])))
        }
    }

    private func setupPlayer() {
        playerNode = SKShapeNode(circleOfRadius: 7)
        playerNode.fillColor = rushGold
        playerNode.strokeColor = UIColor.white.withAlphaComponent(0.5)
        playerNode.lineWidth = 1
        playerNode.glowWidth = 3
        playerNode.position = CGPoint(x: laneXPositions[currentLane.rawValue], y: size.height * playerYRatio)
        playerNode.zPosition = 10
        addChild(playerNode)

        let innerCore = SKShapeNode(circleOfRadius: 3.0)
        innerCore.fillColor = .white
        innerCore.strokeColor = .clear
        innerCore.zPosition = 1
        playerNode.addChild(innerCore)

        shieldNode = SKShapeNode(circleOfRadius: 11.5)
        shieldNode.strokeColor = rushTeal.withAlphaComponent(0.95)
        shieldNode.lineWidth = 2
        shieldNode.glowWidth = 4
        shieldNode.fillColor = rushTeal.withAlphaComponent(0.08)
        shieldNode.zPosition = 0
        playerNode.addChild(shieldNode)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.06, duration: 0.6),
            SKAction.scale(to: 0.98, duration: 0.6)
        ])
        playerNode.run(SKAction.repeatForever(pulse))
    }

    private func setupUI() {
        statusLabel = SKLabelNode(fontNamed: "Courier-Bold")
        statusLabel.fontSize = 13
        statusLabel.fontColor = .white
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .center
        statusLabel.position = CGPoint(x: 0, y: size.height / 2 - topHUDInset)
        statusLabel.zPosition = 30
        addChild(statusLabel)

        updateStatusLabel()
    }

    override func update(_ currentTime: TimeInterval) {
        guard !gameEnded else { return }
        guard hasStarted else { return }

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        elapsedActive += delta
        spawnAccumulator += delta

        updateStatusLabel()
        spawnWaveIfNeeded()
        checkCollisions()
        cleanupExpiredNodes()

        if collectedSeals >= targetSeals || elapsedActive >= gameDuration {
            finishGame(success: true)
        }
    }

    func handleTap(at location: CGPoint, viewSize: CGSize) {
        guard !gameEnded, hasStarted else { return }

        let thirdWidth = viewSize.width / 3
        let laneIndex: Int

        if location.x < thirdWidth {
            laneIndex = SkyRushLane.left.rawValue
        } else if location.x < thirdWidth * 2 {
            laneIndex = SkyRushLane.center.rawValue
        } else {
            laneIndex = SkyRushLane.right.rawValue
        }

        movePlayer(to: laneIndex)
    }

    private func movePlayer(to laneIndex: Int) {
        guard laneIndex != currentLane.rawValue else { return }
        guard let lane = SkyRushLane(rawValue: laneIndex) else { return }

        currentLane = lane
        HapticManager.shared.play(.click)

        let move = SKAction.moveTo(x: laneXPositions[laneIndex], duration: 0.12)
        move.timingMode = .easeOut
        playerNode.run(move)
    }

    private func spawnWaveIfNeeded() {
        guard spawnAccumulator >= spawnInterval else { return }
        spawnAccumulator = 0
        spawnWave()
    }

    private func spawnWave() {
        let lanes = SkyRushLane.allCases.shuffled()
        let spawnY = size.height / 2 + 28

        let openLane: SkyRushLane
        let shouldDoubleHazard = Double.random(in: 0...1) < doubleHazardChance

        if shouldDoubleHazard {
            let blocked = Array(lanes.prefix(2))
            openLane = lanes[2]
            blocked.forEach { spawnHazard(lane: $0, y: spawnY) }
            if Bool.random() {
                spawnSeal(lane: openLane, y: spawnY + 8)
            }
            return
        }

        openLane = lanes[0]
        if Double.random(in: 0...1) < hazardChance {
            spawnHazard(lane: lanes[1], y: spawnY)
        }

        spawnSeal(lane: openLane, y: spawnY + CGFloat.random(in: -6...10))

        if Double.random(in: 0...1) < 0.18 {
            spawnHazard(lane: lanes[2], y: spawnY + 12)
        }
    }

    private func spawnHazard(lane: SkyRushLane, y: CGFloat) {
        let hazard = SKSpriteNode(imageNamed: "lightning")
        hazard.size = CGSize(width: 18, height: 18)
        hazard.position = CGPoint(x: laneXPositions[lane.rawValue], y: y)
        hazard.zPosition = 14
        hazard.name = SkyRushNodeKind.hazard
        hazard.userData = NSMutableDictionary()
        hazard.userData?["lane"] = lane.rawValue
        addChild(hazard)
        activeNodes.append(hazard)

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 1.2)
        hazard.run(SKAction.repeatForever(spin))
        hazard.run(SKAction.sequence([
            SKAction.moveTo(y: -size.height / 2 - 40, duration: movementDuration),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnSeal(lane: SkyRushLane, y: CGFloat) {
        let node = SKNode()
        node.position = CGPoint(x: laneXPositions[lane.rawValue], y: y)
        node.zPosition = 13
        node.name = SkyRushNodeKind.seal
        node.userData = NSMutableDictionary()
        node.userData?["lane"] = lane.rawValue
        let sealColor = randomSealColor()

        let halo = SKShapeNode(circleOfRadius: 9.5)
        halo.fillColor = sealColor.withAlphaComponent(0.22)
        halo.strokeColor = sealColor.withAlphaComponent(0.85)
        halo.lineWidth = 1.2
        halo.glowWidth = 3
        node.addChild(halo)

        let text = SKLabelNode(fontNamed: "PingFangSC-Semibold")
        text.text = "印"
        text.fontSize = 10
        text.fontColor = .white
        text.verticalAlignmentMode = .center
        text.position = CGPoint(x: 0, y: -0.5)
        node.addChild(text)

        addChild(node)
        activeNodes.append(node)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.4),
            SKAction.scale(to: 0.96, duration: 0.4)
        ])
        node.run(SKAction.repeatForever(pulse))
        node.run(SKAction.sequence([
            SKAction.moveTo(y: -size.height / 2 - 40, duration: movementDuration),
            SKAction.removeFromParent()
        ]))
    }

    /// 印的颜色在金亮 / 天青白 / 橙金之间轻微随机，保持奖励物的统一亮色系
    private func randomSealColor() -> UIColor {
        let roll = Double.random(in: 0...1)
        switch roll {
        case ..<0.65:
            return sealGold
        case ..<0.88:
            return sealAzure
        default:
            return sealAmber
        }
    }

    private func checkCollisions() {
        let playerX = laneXPositions[currentLane.rawValue]
        let playerY = size.height * playerYRatio

        for node in activeNodes {
            guard node.parent != nil else { continue }
            guard let laneRaw = node.userData?["lane"] as? Int, laneRaw == currentLane.rawValue else { continue }
            guard abs(node.position.x - playerX) < 6 else { continue }
            guard abs(node.position.y - playerY) < collisionThresholdY else { continue }

            if node.name == SkyRushNodeKind.seal {
                collectSeal(node)
            } else if node.name == SkyRushNodeKind.hazard {
                hitHazard(node)
                return
            }
        }
    }

    private func collectSeal(_ node: SKNode) {
        activeNodes.removeAll { $0 === node }
        node.name = nil
        node.removeAllActions()
        
        // 吃到“印”时做一次吸入反馈：缩小、飞向主角，再让主角轻微脉冲
        node.zPosition = 18
        node.run(SKAction.group([
            SKAction.move(to: playerNode.position, duration: 0.12),
            SKAction.scale(to: 0.22, duration: 0.12),
            SKAction.fadeOut(withDuration: 0.12)
        ])) { [weak self, weak node] in
            node?.removeFromParent()
            guard let self else { return }
            
            let absorbFlash = SKShapeNode(circleOfRadius: 10)
            absorbFlash.fillColor = self.rushGold.withAlphaComponent(0.45)
            absorbFlash.strokeColor = .clear
            absorbFlash.glowWidth = 8
            absorbFlash.position = self.playerNode.position
            absorbFlash.zPosition = 19
            self.addChild(absorbFlash)
            absorbFlash.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.4, duration: 0.12),
                    SKAction.fadeOut(withDuration: 0.12)
                ]),
                SKAction.removeFromParent()
            ]))

            self.playerNode.run(SKAction.sequence([
                SKAction.scale(to: 1.08, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.12)
            ]))
        }

        collectedSeals += 1
        updateStatusLabel()
        HapticManager.shared.play(.directionUp)
    }

    private func hitHazard(_ node: SKNode) {
        activeNodes.removeAll { $0 === node }
        node.name = nil
        node.removeAllActions()
        node.removeFromParent()
        remainingLives -= 1
        HapticManager.shared.play(.failure)

        let shake = SKAction.sequence([
            SKAction.moveBy(x: -6, y: 0, duration: 0.03),
            SKAction.moveBy(x: 12, y: 0, duration: 0.06),
            SKAction.moveBy(x: -6, y: 0, duration: 0.03)
        ])
        playerNode.run(shake)

        if remainingLives == 1 {
            // 护罩第一次被击碎时，给一次局部雷闪，强化“护体罡气破碎”的反馈
            triggerShieldBreakEffect()
            shieldNode.run(SKAction.group([
                SKAction.scale(to: 1.25, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.12)
            ]))
            spawnShieldShards()
            shieldNode.run(SKAction.removeFromParent())
        } else if remainingLives <= 0 {
            finishGame(success: false)
        }
    }

    private func cleanupExpiredNodes() {
        activeNodes.removeAll { $0.parent == nil }
    }
    
    /// 护罩破碎时的局部受击效果：红闪一下，再触发一次环境闪电
    private func triggerShieldBreakEffect() {
        let flash = SKShapeNode(circleOfRadius: 16)
        flash.fillColor = UIColor.red.withAlphaComponent(0.78)
        flash.strokeColor = .clear
        flash.glowWidth = 6
        flash.zPosition = 25
        flash.alpha = 0
        flash.position = playerNode.position
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.75, duration: 0.05),
            SKAction.fadeOut(withDuration: 0.14),
            SKAction.removeFromParent()
        ]))
        
        triggerLightningEffect(playSound: true)
    }
    
    /// 护罩碎裂时抛出少量碎片，增强“罡气破碎”的质感
    private func spawnShieldShards() {
        for index in 0..<6 {
            let shard = SKShapeNode(rectOf: CGSize(width: 4, height: 2), cornerRadius: 1)
            shard.fillColor = rushTeal.withAlphaComponent(0.85)
            shard.strokeColor = .clear
            shard.glowWidth = 2
            shard.position = playerNode.position
            shard.zPosition = 18
            addChild(shard)
            
            let angle = (CGFloat(index) / 6.0) * (.pi * 2)
            let distance = CGFloat.random(in: 12...20)
            let target = CGPoint(
                x: playerNode.position.x + cos(angle) * distance,
                y: playerNode.position.y + sin(angle) * distance
            )
            shard.zRotation = angle
            shard.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: target, duration: 0.16),
                    SKAction.fadeOut(withDuration: 0.16),
                    SKAction.rotate(byAngle: .pi, duration: 0.16)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func updateStatusLabel() {
        let remaining = max(0, Int(ceil(gameDuration - elapsedActive)))
        statusLabel.text = "印 \(collectedSeals)/\(targetSeals) · \(remaining)s"
    }

    private func finishGame(success: Bool) {
        guard !gameEnded else { return }
        gameEnded = true
        removeAllActions()
        activeNodes.forEach { node in
            node.removeAllActions()
            node.removeFromParent()
        }
        activeNodes.removeAll()

        if success {
            let flash = SKShapeNode(circleOfRadius: max(size.width, size.height) * 0.9)
            flash.fillColor = UIColor.white.withAlphaComponent(0.95)
            flash.strokeColor = .clear
            flash.zPosition = 100
            flash.alpha = 0
            addChild(flash)

            flash.run(SKAction.sequence([
                SKAction.fadeIn(withDuration: 0.18),
                SKAction.fadeOut(withDuration: 0.35),
                SKAction.removeFromParent()
            ]))
          
        } else {
            let flash = SKSpriteNode(color: .red, size: size)
            flash.position = .zero
            flash.zPosition = 100
            flash.alpha = 0
            addChild(flash)
            flash.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.42, duration: 0.1),
                SKAction.fadeAlpha(to: 0, duration: 0.22),
                SKAction.removeFromParent()
            ]))
            HapticManager.shared.play(.failure)
        }

        run(SKAction.repeat(SKAction.sequence([
            SKAction.run { [weak self] in self?.triggerLightningEffect(playSound: true) },
            SKAction.wait(forDuration: success ? 0.15 : 0.1)
        ]), count: success ? 4 : 3))

        DispatchQueue.main.asyncAfter(deadline: .now() + (success ? 0.5 : 0.25)) {
            self.onGameOver?(success)
        }
    }
}

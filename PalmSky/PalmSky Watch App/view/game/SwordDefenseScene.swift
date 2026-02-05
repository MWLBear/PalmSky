//
//  SwordDefenseScene.swift
//  PalmSky Watch App
//
//  Created by mac on 12/25/25.
//

import SpriteKit
import UIKit

private enum SwordPhysicsCategory {
  static let none: UInt32 = 0
  static let sword: UInt32 = 1
  static let lightning: UInt32 = 2
  static let center: UInt32 = 4
}

class SwordDefenseScene: SKScene, SKPhysicsContactDelegate {
  private static let swordTexture = SKTexture(imageNamed: "sword")
  private static let lightningTexture = SKTexture(imageNamed: "lightning")
  private static let taiChiTexture = SKTexture(imageNamed: "taiChi1")

  // MARK: - 外部参数
  var gameLevel: Int = 1
  var onGameOver: ((Bool) -> Void)?
  
  // MARK: - 节点
  private var backgroundNode: SKSpriteNode!
  private var centerNode: SKSpriteNode!
  private var swordNode: SKSpriteNode!
  private var livesLabel: SKLabelNode!
  private var countdownLabel: SKLabelNode!
  
  // MARK: - 状态
  private var isClockwise = false
  private var swordAngle: CGFloat = .pi / 2
  private var lastUpdateTime: TimeInterval = 0
  private var elapsed: TimeInterval = 0
  private var spawnAccumulator: TimeInterval = 0
  private var lives = 2
  private var gameEnded = false
  private var didStartStorm = false
  
  // MARK: - 配置
  private let swordOrbitRadius: CGFloat = 50
  private var swordAngularSpeed: CGFloat = 2.2 // radians / sec
  private let lightningBaseSpeed: CGFloat = 26
  private let centerRadius: CGFloat = 16
  
  private var gameDuration: TimeInterval = 15

  
  override func sceneDidLoad() {
    physicsWorld.contactDelegate = self
    physicsWorld.gravity = .zero
    anchorPoint = CGPoint(x: 0.5, y: 0.5)
    backgroundColor = .black
    
    self.preloadSoundEffect()
    setupBackground()
    setupCenter()
    setupSword()
    setupUI()
    startAmbientLightning(
      shouldContinue: { [weak self] in self?.gameEnded == false },
      trigger: { [weak self] in self?.triggerLightningEffect(playSound: true) }
    )
    
  }
  
  func applyGameLevel() {
    configureDurationForLevel()
    countdownLabel.text = "\(Int(ceil(gameDuration)))s"
    print("gameLevel", gameLevel, "gameDuration", gameDuration)
  }
  
  // MARK: - Setup
  private func setupBackground() {
    backgroundNode = SKSpriteNode(color: .black, size: size)
    backgroundNode.zPosition = -10
    backgroundNode.position = .zero
    addChild(backgroundNode)
  }
  
  private func setupCenter() {
    // 中心太极
    centerNode = SKSpriteNode(texture: Self.taiChiTexture)
    centerNode.size = CGSize(width: 30, height: 30)
    centerNode.position = .zero
    centerNode.zPosition = 1
    
    centerNode.physicsBody = SKPhysicsBody(circleOfRadius: centerRadius)
    centerNode.physicsBody?.isDynamic = false
    centerNode.physicsBody?.categoryBitMask = SwordPhysicsCategory.center
    centerNode.physicsBody?.contactTestBitMask = SwordPhysicsCategory.lightning
    centerNode.physicsBody?.collisionBitMask = SwordPhysicsCategory.none
    addChild(centerNode)
    
    // 轻微旋转，保持灵气感
    let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 8)
    centerNode.run(SKAction.repeatForever(rotate))
  }
  
  private func setupSword() {
    swordNode = SKSpriteNode(texture: Self.swordTexture)
    swordNode.size = CGSize(width: 7, height: 40)
    swordNode.position = CGPoint(x: 0, y: swordOrbitRadius)
    swordNode.zPosition = 2
    swordNode.zRotation = -(.pi / 2)
    
    // 让碰撞圆心偏向剑尖（向上）
    swordNode.physicsBody = SKPhysicsBody(
      circleOfRadius: 8,
      center: CGPoint(x: 0, y: 10)
    )
    swordNode.physicsBody?.isDynamic = true
    swordNode.physicsBody?.categoryBitMask = SwordPhysicsCategory.sword
    swordNode.physicsBody?.contactTestBitMask = SwordPhysicsCategory.lightning
    swordNode.physicsBody?.collisionBitMask = SwordPhysicsCategory.none
    addChild(swordNode)
    
  }
  
  private func setupUI() {
    livesLabel = SKLabelNode(fontNamed: "Courier-Bold")
    livesLabel.fontSize = 25
    livesLabel.fontColor = .white
    
      
    #if os(watchOS)
    livesLabel.position = CGPoint(x: size.width / 2 - 40, y: size.height / 2 - 30)
    #elseif os(iOS)
    livesLabel.position = CGPoint(x: 50, y: size.height / 2 - 30)
    #endif
      
    
    livesLabel.text = "❤︎ x\(lives)"
    livesLabel.zPosition = 5
    addChild(livesLabel)
    livesLabel.isHidden = true
    

   // let roundedFont = UIFont.systemFont(ofSize: 30, weight: .bold, design: .rounded)

    countdownLabel = SKLabelNode(fontNamed: "Courier-Bold")
    countdownLabel.fontSize = 15
    countdownLabel.fontColor = .white
    countdownLabel.position = CGPoint(x: 0, y: size.height / 2 - 30)
    countdownLabel.text = "15s"
    countdownLabel.zPosition = 5
    addChild(countdownLabel)
  }
  
  private func configureDurationForLevel() {
    if (4...7).contains(gameLevel) {
      switch gameLevel {
      case 4: gameDuration = 15
      case 5: gameDuration = 20
      case 6: gameDuration = 25
      case 7: gameDuration = 30
      default: gameDuration = 30
      }
    } else {
      gameDuration = 30
    }
 
  }
  
  
  // MARK: - Touch (SwiftUI 传入点击位置)
  func handleDrop(at location: CGPoint) {
    guard !gameEnded else { return }
    isClockwise.toggle()
    swordAngularSpeed = min(3.2, swordAngularSpeed + 0.08)
  }
  
  // MARK: - Update
  override func update(_ currentTime: TimeInterval) {
    guard !gameEnded else { return }
    if lastUpdateTime == 0 { lastUpdateTime = currentTime }
    let delta = currentTime - lastUpdateTime
    lastUpdateTime = currentTime
    
    elapsed += delta
    spawnAccumulator += delta
    
    let remaining = max(0, Int(ceil(gameDuration - elapsed)))
    countdownLabel.text = "\(remaining)s"
    
    updateSword(delta: delta)
    spawnLightningIfNeeded()
    updateCenterTremble()
    updatePhaseEffects()
    
    if elapsed >= gameDuration {
      finishGame(success: true)
    }
  }
  
  private func updateSword(delta: TimeInterval) {
    let direction: CGFloat = isClockwise ? -1 : 1
    swordAngle += direction * swordAngularSpeed * CGFloat(delta)
    let x = cos(swordAngle) * swordOrbitRadius
    let y = sin(swordAngle) * swordOrbitRadius
    swordNode.position = CGPoint(x: x, y: y)
    swordNode.zRotation = swordAngle - (.pi / 2)
  }
  
  private func spawnLightningIfNeeded() {
    let phase = currentPhase()
    let interval = phase.spawnInterval
    
    if spawnAccumulator < interval { return }
    spawnAccumulator = 0
    
    for _ in 0..<phase.spawnCount {
      spawnLightning(speed: phase.lightningSpeed)
    }
  }
  
  private func spawnLightning(speed: CGFloat) {
    let orb = SKSpriteNode(texture: Self.lightningTexture)
    orb.size = CGSize(width: 15, height: 15)
    orb.position = randomEdgePoint()
    orb.zPosition = 3
    
    orb.physicsBody = SKPhysicsBody(circleOfRadius: 8)
    orb.physicsBody?.isDynamic = true
    orb.physicsBody?.categoryBitMask = SwordPhysicsCategory.lightning
    orb.physicsBody?.contactTestBitMask = SwordPhysicsCategory.sword | SwordPhysicsCategory.center
    orb.physicsBody?.collisionBitMask = SwordPhysicsCategory.none
    orb.name = "lightning"
    addChild(orb)

    // 雷球自转
    let spin = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
    orb.run(SKAction.repeatForever(spin), withKey: "spin")
        
    let travel = SKAction.move(to: .zero, duration: distance(from: orb.position, to: .zero) / speed)
    let remove = SKAction.removeFromParent()
    orb.run(SKAction.sequence([travel, remove]))
    
  }
  
  private func randomEdgePoint() -> CGPoint {
    let halfW = size.width / 2
    let halfH = size.height / 2
    let offset: CGFloat = 20
    let corners = [
      CGPoint(x: -halfW - offset, y: -halfH - offset),
      CGPoint(x: halfW + offset, y: -halfH - offset),
      CGPoint(x: -halfW - offset, y: halfH + offset),
      CGPoint(x: halfW + offset, y: halfH + offset)
    ]
    return corners.randomElement() ?? .zero
  }
  
  private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
    let dx = from.x - to.x
    let dy = from.y - to.y
    return sqrt(dx * dx + dy * dy)
  }
  
  private func currentPhase() -> (spawnInterval: TimeInterval, spawnCount: Int, lightningSpeed: CGFloat) {
    if elapsed < 5 {
      return (1.8, 1, lightningBaseSpeed)
    } else if elapsed < 10 {
      return (1.6, 1, lightningBaseSpeed + 4)
    } else {
      return (1.4, 1, lightningBaseSpeed + 6)
    }
  }
  
  private func updatePhaseEffects() {
    if elapsed >= 10, !didStartStorm {
      didStartStorm = true
      let flashUp = SKAction.fadeAlpha(to: 0.35, duration: 0.1)
      let flashDown = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
      let flash = SKAction.sequence([flashUp, flashDown])
      backgroundNode.run(SKAction.repeatForever(flash), withKey: "storm")
    }
  }
  
  private func updateCenterTremble() {
    var nearestDistance: CGFloat = .greatestFiniteMagnitude
    enumerateChildNodes(withName: "lightning") { node, _ in
      let d = hypot(node.position.x, node.position.y)
      if d < nearestDistance { nearestDistance = d }
    }
    
    if nearestDistance < 60 {
      if centerNode.action(forKey: "tremble") == nil {
        let up = SKAction.scale(to: 1.06, duration: 0.06)
        let down = SKAction.scale(to: 1.0, duration: 0.08)
        centerNode.run(SKAction.sequence([up, down]), withKey: "tremble")
      }
    }
  }
  
  
  // MARK: - Contact
  func didBegin(_ contact: SKPhysicsContact) {
    let category = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    
    if category == (SwordPhysicsCategory.sword | SwordPhysicsCategory.lightning) {
      handleSwordHit(contact)
    } else if category == (SwordPhysicsCategory.center | SwordPhysicsCategory.lightning) {
      handleCenterHit(contact)
    }
  }
  
  private func handleSwordHit(_ contact: SKPhysicsContact) {
    guard let node = (contact.bodyA.categoryBitMask == SwordPhysicsCategory.lightning ? contact.bodyA.node : contact.bodyB.node) else { return }
    spawnLightningBurst(at: node.position, color: SKColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1.0))
    node.removeFromParent()
    SkyAudio.shared.playSoundEffects("attack")

  }
  
  private func handleCenterHit(_ contact: SKPhysicsContact) {
    guard let node = (contact.bodyA.categoryBitMask == SwordPhysicsCategory.lightning ? contact.bodyA.node : contact.bodyB.node) else { return }
    spawnLightningBurst(at: node.position, color: SKColor(red: 0.9, green: 0.4, blue: 0.6, alpha: 1.0))
    node.removeFromParent()
    
    centerNode.run(.blink(color: .red))
    lives -= 1
    livesLabel.text = "❤︎ x\(lives)"
    
    if lives <= 0 {
      flashRed()
      finishGame(success: false)
    }
  }
  
  private func finishGame(success: Bool) {
    guard !gameEnded else { return }
    gameEnded = true
    removeAllActions()
    enumerateChildNodes(withName: "lightning") { node, _ in
      node.removeFromParent()
    }
    
    run(SKAction.repeat(SKAction.sequence([
      SKAction.run { [weak self] in self?.triggerLightningEffect(playSound: true) },
      SKAction.wait(forDuration: 0.1)
    ]), count: 3))
    
    run(SKAction.wait(forDuration: 1.0)) { [weak self] in
      self?.onGameOver?(success)
    }
  }

  private func flashRed() {
    let flash = SKSpriteNode(color: .red, size: size)
    flash.position = .zero
    flash.alpha = 0
    addChild(flash)
    flash.run(SKAction.sequence([
      SKAction.fadeAlpha(to: 0.5, duration: 0.1),
      SKAction.fadeAlpha(to: 0, duration: 0.2),
      SKAction.removeFromParent()
    ]))
  }

  private func spawnLightningBurst(at position: CGPoint, color: SKColor) {
    let burst = SKEmitterNode()
    burst.particleTexture = SKTexture(imageNamed: "spark")
    burst.position = position
    burst.particleBirthRate = 200
    burst.numParticlesToEmit = 20
    burst.particleLifetime = 0.20
    burst.particleLifetimeRange = 0.1
    burst.emissionAngleRange = .pi * 2
    burst.particleSpeed = 80
    burst.particleSpeedRange = 30
    burst.particleAlpha = 0.9
    burst.particleAlphaSpeed = -1.2
    burst.particleScale = 0.18
    burst.particleScaleRange = 0.08
    burst.particleColor = color
    burst.particleColorBlendFactor = 1.0
    burst.particleBlendMode = .add
    addChild(burst)
    
    burst.run(SKAction.sequence([
      SKAction.wait(forDuration: 0.5),
      SKAction.removeFromParent()
    ]))
  }
}

import SpriteKit

extension SKScene {
  // MARK: - ⚡️ Lightning Effect (Pure Code)
  
  /// 触发一道随机闪电
  public func triggerLightningEffect(playSound: Bool = false) {
    let minX = frame.minX
    let maxX = frame.maxX
    let minY = frame.minY
    let maxY = frame.maxY
    let start = CGPoint(x: CGFloat.random(in: minX...maxX), y: maxY)
    let end = CGPoint(x: CGFloat.random(in: minX...maxX), y: minY)
    createLightningBolt(from: start, to: end)
    
    if playSound {
      SkyAudio.shared.playSoundEffects("lightning")
    }
  }
  
  /// 创建闪电节点
  public  func createLightningBolt(from start: CGPoint, to end: CGPoint) {
    let path = CGMutablePath()
    path.move(to: start)
    
    let dist = hypot(end.x - start.x, end.y - start.y)
    let stepCount = max(1, Int(dist / 10))
    
    let dx = (end.x - start.x) / CGFloat(stepCount)
    let dy = (end.y - start.y) / CGFloat(stepCount)
    
    for i in 0..<stepCount {
      var nextPoint = CGPoint(x: start.x + dx * CGFloat(i), y: start.y + dy * CGFloat(i))
      
      let jitter: CGFloat = 15.0
      if i != 0 && i != stepCount - 1 {
        nextPoint.x += CGFloat.random(in: -jitter...jitter)
        nextPoint.y += CGFloat.random(in: -jitter...jitter)
      }
      
      path.addLine(to: nextPoint)
    }
    path.addLine(to: end)
    
    let bolt = SKShapeNode(path: path)
    bolt.strokeColor = .white
    bolt.lineWidth = 2.0
    bolt.glowWidth = 4.0
    bolt.alpha = 0.8
    bolt.zPosition = 5
    bolt.lineCap = .round
    
    addChild(bolt)
    
    let fade = SKAction.sequence([
      SKAction.fadeOut(withDuration: 0.1),
      SKAction.fadeIn(withDuration: 0.05),
      SKAction.fadeOut(withDuration: 0.2),
      SKAction.removeFromParent()
    ])
    bolt.run(fade)
  }
}


public extension SKAction {
  static func blink(color: SKColor) -> SKAction {
    let blinkOff = SKAction.colorize(withColorBlendFactor: 0.0,
                                     duration: 0.08)

    let blinkOn = SKAction.colorize(with: color,
                                    colorBlendFactor: 1.0,
                                    duration: 0.08)

    let blink = SKAction.repeat(SKAction.sequence([blinkOn,blinkOff]), count: 2)

    return blink
  }
}

import SpriteKit

extension SKScene {
  // ⚡️ 环境雷电循环（可复用）
  public func startAmbientLightning(
    shouldContinue: @escaping () -> Bool = { true },
    trigger: @escaping () -> Void
  ) {
    let randomDelay = Double.random(in: 3.5...7.0)
    run(
      SKAction.sequence([
        SKAction.wait(forDuration: randomDelay),
        SKAction.run { [weak self] in
          guard let self = self, shouldContinue() else { return }
          trigger()
          self.startAmbientLightning(shouldContinue: shouldContinue, trigger: trigger)
        }
      ]),
      withKey: "ambientLightning"
    )
  }
}

extension SKScene {
  
  // 预先加载音效
  public func preloadSoundEffect () {
    
      SkyAudio.shared.preloadSoundEffects([
        "lightning",
        "attack",
        "KnifeHit",
        "KnifeHitFail"
      ])
    
  }
}

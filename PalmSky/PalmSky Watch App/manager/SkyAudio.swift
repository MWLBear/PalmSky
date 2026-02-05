import AVFoundation
import SwiftUI
import SpriteKit

public class SkyAudio {
  
  public static let shared = SkyAudio() // 单例
  
  private var backgroundMusicPlayer: AVAudioPlayer?
  private var soundEffectPlayer: AVAudioPlayer?
  private var soundEffectPlayers: [AVAudioPlayer] = [] // 音效池
  private var effectCache: [String: [AVAudioPlayer]] = [:]
  private var lastEffectPlayTime: [String: TimeInterval] = [:]
  private let maxPlayersPerEffect = 2
  private let effectCooldown: TimeInterval = 0.12

  private init() {} // 私有初始化，防止外部创建实例
  
  /// 读取 soundEnabled 状态
  private var isSoundEnabled: Bool {
    return GameManager.shared.player.settings.soundEnabled
  }
  
  /// 读取 soundEnabled 状态
  private var isVibrationEnabled: Bool {
    return GameManager.shared.player.settings.hapticEnabled
  }
  
  /// 播放背景音乐（循环播放）
  public func playBackgroundMusic(_ filename: String) {
    guard isSoundEnabled else { return } // 如果声音关闭，直接返回
    
    guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
      print("Could not find file: \(filename).mp3")
      return
    }
    
    do {
      backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
      backgroundMusicPlayer?.numberOfLoops = -1 // 无限循环
      backgroundMusicPlayer?.prepareToPlay()
      backgroundMusicPlayer?.play()
    } catch {
      print("Could not create audio player: \(error.localizedDescription)")
    }
  }
  
  /// 暂停背景音乐
  public func pauseBackgroundMusic() {
    if backgroundMusicPlayer?.isPlaying == true {
      backgroundMusicPlayer?.pause()
    }
  }
  
  /// 恢复背景音乐
  public func resumeBackgroundMusic() {
    if isSoundEnabled, backgroundMusicPlayer?.isPlaying == false {
      backgroundMusicPlayer?.play()
    }
  }
  
  /// 播放音效（不循环）快速点击播放会有问题呢
  public func playSoundEffect(_ filename: String) {
    guard isSoundEnabled else { return } // 如果声音关闭，直接返回
    
    guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
      print("Could not find file: \(filename).mp3")
      return
    }
    
    do {
      soundEffectPlayer = try AVAudioPlayer(contentsOf: url)
      soundEffectPlayer?.numberOfLoops = 0
      soundEffectPlayer?.prepareToPlay()
      soundEffectPlayer?.play()
    } catch {
      print("Could not create audio player: \(error.localizedDescription)")
    }
  }
  
  
  // MARK: - 音效播放池（支持并发）
  public func playSoundEffects(_ filename: String) {
    guard isSoundEnabled else { return }
    let now = Date().timeIntervalSince1970
    if let lastTime = lastEffectPlayTime[filename], now - lastTime < effectCooldown {
      return
    }
    lastEffectPlayTime[filename] = now
    
    guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
      print("Could not find file: \(filename).mp3")
      return
    }
    
    do {
      let player: AVAudioPlayer
      if var pool = effectCache[filename], let reusable = pool.first(where: { !$0.isPlaying }) {
        player = reusable
      } else {
        player = try AVAudioPlayer(contentsOf: url)
        player.numberOfLoops = 0
        player.prepareToPlay()
        if effectCache[filename] != nil {
          if effectCache[filename]!.count < maxPlayersPerEffect {
            effectCache[filename]?.append(player)
          }
        } else {
          effectCache[filename] = [player]
        }
      }
      player.numberOfLoops = 0
      player.prepareToPlay()
      player.play()
    } catch {
      print("Could not create sound effect player: \(error.localizedDescription)")
    }
  }

  // MARK: - 预加载音效，减少首次播放卡顿
  public func preloadSoundEffects(_ filenames: [String]) {
    guard isSoundEnabled else { return }
    for name in filenames {
      if let pool = effectCache[name], !pool.isEmpty { continue }
      guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
        print("Could not find file: \(name).mp3")
        continue
      }
      do {
        let player = try AVAudioPlayer(contentsOf: url)
        player.numberOfLoops = 0
        player.prepareToPlay()
        effectCache[name] = [player]
      } catch {
        print("Could not create sound effect player: \(error.localizedDescription)")
      }
    }
  }

  
  
  /// 停止背景音乐
  public func stopBackgroundMusic() {
    print("stopBackgroundMusic")
    if let player = backgroundMusicPlayer {
      player.stop()
      backgroundMusicPlayer = nil  // 释放 player
    }
  }
}


extension SkyAudio {
  
  
//  public func play(_ type: WKHapticType) {
//    guard isVibrationEnabled else { return } // 如果震动关闭，直接返回
//    WKInterfaceDevice.current().play(type)
//  }
  
  
  public func nodePlay(_ filename: String, on node: SKNode) {
      guard isSoundEnabled else { return } // 如果声音关闭，直接返回
      node.run(SKAction.playSoundFileNamed(filename, waitForCompletion: false))
  }
  
}

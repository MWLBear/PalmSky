//
//  LifeReviewView.swift
//  PalmSky Watch App
//
//  Created by mac on 12/15/25.
//

import Foundation
import SwiftUI

// 1. 定义数据结构：回忆板块
struct ReviewSection: Identifiable, Equatable {
    let id = UUID()
    let icon: String        // 图标 (SF Symbol)
    let title: String       // 小标题
    let content: String     // 正文内容
    let highlight: String?  // 高亮总结句 (可选)
    let color: Color        // 主题色
    let pause: Double       // 停留时间
}

struct LifeReviewView: View {
    @ObservedObject var recordManager = RecordManager.shared
    
    // 状态
    @State private var script: [ReviewSection] = []
    @State private var visibleSections: [ReviewSection] = []
    @State private var currentIndex = 0
    @State private var isFinished = false
    
    // 定时器
    @State private var timer: Timer?
    
    var onClose: (() -> Void)? = nil

  
    private let dateForamtter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.M.d"
        return f
    }()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) { // 板块间距
                        
//                        // 顶部留白
                        Spacer().frame(height: 10)
                        
                        // 标题单独放
                        if !visibleSections.isEmpty {
                          VStack(spacing: 6) {
                            Text("此生修行小记")
                            // ✅ 规范：总标题 .headline + rounded + semibold
                              .font(.system(.title3, design: .rounded).weight(.semibold))
                              .foregroundColor(.white)
                              .fixedSize(horizontal: false, vertical: true) // 保持高度固定

                            Text("— 掌上修仙 —")
                            // ✅ 规范：引言 .caption2 + serif
                              .font(.system(.caption2, design: .serif))
                              .foregroundColor(.gray)
                          }
                          .padding(.bottom, 12)
                          .opacity(visibleSections.isEmpty ? 0 : 1)
                          .animation(.easeIn(duration: 0.6), value: visibleSections.count)
                        }
                                          
                        
                        // 循环显示卡片
                        ForEach(visibleSections) { section in
                            ReviewCard(section: section)
                                .id(section.id)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                      // 底部按钮
                      if isFinished {
                        VStack(spacing: 20) {
                          Divider()
                            .background(Color.white.opacity(0.15))
                            .padding(.horizontal, 40) // 线短一点，更雅致
                          
                          // ✅ 规范：禅语 .callout + serif + italic (这里稍微用大一点的 callout 撑场面)
                          VStack(spacing: 6) {
                            Text("此道漫长，不必急行。")
                              .font(.system(.callout, design: .serif).italic())
                              .foregroundColor(.white.opacity(0.9))
                            
                            Text("—— 你已经走得足够远了")
                              .font(.system(.caption2, design: .serif))
                              .foregroundColor(.gray)
                          }
                          .padding(.vertical, 8)
                          
                          Button(action: {
                              GameManager.shared.enterZenMode()
                              onClose?()
                              HapticManager.shared.playIfEnabled(.click)

                          }) {
                              Text("合上札记")
                                  .font(.system(.headline, design: .rounded).weight(.semibold))
                                  .foregroundColor(.black)
                                  .frame(maxWidth: .infinity)
                                  .padding(.vertical, 12)
                                  .background(
                                      LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.7)],
                                                     startPoint: .top,
                                                     endPoint: .bottom)
                                  )
                                  .clipShape(Capsule())
                                  .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                          }
                          .buttonStyle(.plain)

                          Button(action: {
                            GameManager.shared.reincarnate()
                            onClose?()
                          }) {
                            Text("转世重修")
                              .font(.system(.footnote, design: .rounded))
                              .foregroundColor(.gray.opacity(0.6))
                              .padding(.vertical, 4)
                          }
                          .buttonStyle(.plain)
                        }
                        .padding(.top, 10)
                        .transition(.opacity.animation(.easeIn(duration: 1.5))) // 出现得更慢一点
                        .id("BOTTOM")
                      }
                      
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 12)
                }
                .onChange(of: visibleSections.count) { _ , _ in
                    withAnimation(.spring()) {
                        if isFinished {
                            proxy.scrollTo("BOTTOM", anchor: .bottom)
                        } else if let last = visibleSections.last {
                            proxy.scrollTo(last.id, anchor: .center)
                        }
                    }
                    HapticManager.shared.playIfEnabled(.click)

                }
            }
            
            // 点击加速
            Color.white.opacity(0.001)
                .onTapGesture { showNext() }
                .allowsHitTesting(!isFinished)
        }
        .onAppear {
            generateScript()
            startPlayback()
        }
        .onDisappear { timer?.invalidate() }
    }
    
    // MARK: - 播放控制
    private func startPlayback() {
        showNext()
    }
    
    private func showNext() {
        timer?.invalidate()
        
        guard currentIndex < script.count else {
            withAnimation { isFinished = true }
            return
        }
        
        let nextSection = script[currentIndex]
        withAnimation(.easeOut(duration: 0.6)) {
            visibleSections.append(nextSection)
        }
        currentIndex += 1
        
        timer = Timer.scheduledTimer(withTimeInterval: nextSection.pause, repeats: false) { _ in
            showNext()
        }
    }
    
    // MARK: - 剧本生成
    private func generateScript() {
        let rec = recordManager.record
        var s: [ReviewSection] = []
        
        // 1. 时间
        s.append(ReviewSection(
            icon: "hourglass",
            title: "岁月",
            content: "始于 \(dateForamtter.string(from: rec.startDate))\n终于 \(dateForamtter.string(from: rec.finishDate ?? Date()))",
            highlight: "共修行 \(rec.totalDays) 天",
            color: .blue,
            pause: 2.5
        ))
        
        // 2. 苦难
        var struggleText = "即便天赋异禀，亦有困顿之时。"
        if let stage = rec.longestStagnationStageName, rec.maxStagnationDays > 0 {
            struggleText = "最长的一次停滞，你在「\(stage)」停留了 \(rec.maxStagnationDays) 天。"
        }
        s.append(ReviewSection(
            icon: "mountain.2.fill",
            title: "坚持",
            content: struggleText,
            highlight: rec.breakFailures > 0 ? "历经 \(rec.breakFailures) 次失败，未曾放弃。" : "道心通明，势如破竹。",
            color: .orange,
            pause: 2.5
        ))
        
        // 3. 选择
        s.append(ReviewSection(
            icon: "signpost.right.and.left.fill",
            title: "机缘",
            content: "途中遇奇遇 \(rec.eventsTriggered) 次。\n接受 \(rec.eventsAccepted) 次，放弃 \(rec.eventsRejected) 次。",
            highlight: getEventSummary(),
            color: .purple,
            pause: 2.5
        ))
        
        // 4. 性格
        s.append(ReviewSection(
            icon: "person.fill.viewfinder",
            title: "道心",
            content: getPersonalityDescription(),
            highlight: getOverviewText(), // "这一年，你走得很慢..."
            color: .green,
            pause: 3.0
        ))
        
        self.script = s
    }
}

// MARK: - 单个卡片视图 (UI 核心)
struct ReviewCard: View {
    let section: ReviewSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // 稍微收紧一点间距
            // 1. 头部：卡片标题 (UI 框架 -> Rounded)
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(.footnote, weight: .semibold))

                    .foregroundColor(section.color)
                
                Text(section.title)
                    // ✅ 规范：.footnote + rounded + semibold
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundColor(section.color)
                
                Spacer()
            }
            
            // 2. 正文：客观记录 (历史 -> Default)
            Text(section.content)
                // ✅ 规范：.body + default (去掉了 rounded，回归阅读本质)
                .font(.system(.body, design: .default))
                .foregroundColor(.white.opacity(0.85)) // 稍微亮一点，保证易读
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4) // 增加行距，呼吸感
            
            // 3. 高亮总结：个人感悟 (人味 -> Serif Italic)
            if let highlight = section.highlight {
                Text(highlight)
                    // ✅ 规范：.callout + serif + italic
                    .font(.system(.callout, design: .serif).italic())
                    .foregroundColor(.white)
                    .padding(.top, 6)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08)) // 背景再淡一点，更克制
        .clipShape(RoundedRectangle(cornerRadius: 16))
        // 左侧装饰条保持不变，增加一点点精致感
        .overlay(
            HStack {
                Rectangle()
                    .fill(section.color.opacity(0.7)) // 稍微柔和一点
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}

// MARK: - 文案生成逻辑扩展
extension LifeReviewView {
    
    // 内部辅助枚举：性格类型
    private enum PersonalityType {
        case risky    // 冒险型
        case steady   // 稳健型
        case balanced // 平衡型
    }
    
    // 辅助计算：判断玩家性格
    private func getPersonalityType() -> PersonalityType {
        let rec = recordManager.record
        // 如果冒险次数是稳健次数的1.5倍以上 -> 冒险型
        if rec.riskyBreakCount > Int(Double(rec.steadyBreakCount) * 1.5) {
            return .risky
        }
        // 如果稳健次数是冒险次数的1.5倍以上 -> 稳健型
        else if rec.steadyBreakCount > Int(Double(rec.riskyBreakCount) * 1.5) {
            return .steady
        }
        // 否则 -> 平衡型
        else {
            return .balanced
        }
    }
    
    // 1. 获取总览金句 (对应 ReviewSection 4 的 highlight)
    func getOverviewText() -> String {
        switch getPersonalityType() {
        case .steady:
            return "这一年，你走得很慢，但从未后退。"
        case .risky:
            return "这一年，你常在未明之时出手。"
        case .balanced:
            return "这一年，你懂得等待，也敢于一搏。"
        }
    }
    
    // 2. 获取性格详细描述 (对应 ReviewSection 4 的 content)
    func getPersonalityDescription() -> String {
        switch getPersonalityType() {
        case .risky:
            return "当成功率不足六成时，你仍然选择向前。你曾在险境中，押上自己的道心。"
        case .steady:
            return "你很少在胜算不足时出手。你相信时机，而非侥幸。"
        case .balanced:
            return "你既懂得等待，也不惧尝试。你知道，有些关口，必须自己走过去。"
        }
    }
    
    // 3. 获取奇遇总结 (对应 ReviewSection 3 的 highlight)
    func getEventSummary() -> String {
        let rec = recordManager.record
        // 简单的比值判断
        if rec.eventsAccepted > Int(Double(rec.eventsRejected) * 1.5) {
            return "面对未知，你愿意选择相信。"
        } else if rec.eventsRejected > Int(Double(rec.eventsAccepted) * 1.5) {
            return "面对诱惑，你更珍惜当下的安稳。"
        } else {
            return "你总是在权衡利弊之后，再决定是否前行。"
        }
    }
}
// 预览
struct LifeReviewView_Previews: PreviewProvider {
    static var previews: some View {
        LifeReviewView()
    }
}

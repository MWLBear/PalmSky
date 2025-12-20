import SwiftUI
import GameKit

// MARK: - Leaderboard Row
              
struct SegmentedSelectorView: View {
    let items: [(name: String, scope: GKLeaderboard.TimeScope)]
    @Binding var selectedScope: GKLeaderboard.TimeScope

    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            ForEach(items, id: \.scope) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedScope = item.scope
                    }
                } label: {
                    Text(item.name)
                       .font(.subheadline)
                       .fontWeight(selectedScope == item.scope ? .bold : .semibold)
                        .foregroundColor(
                          selectedScope == item.scope ? .white : .secondary
                          // 适配：选中时用主题色/白色，未选中用次级文字色
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical,10)
                        .background {
                          ZStack  {
                              if selectedScope == item.scope {
                                Capsule()
                                  .fill(Color.green)

                                  .matchedGeometryEffect(
                                    id: "selection",
                                    in: animation
                                  )
                              }
                          }
                        }
                }
                .buttonStyle(.plain)
            }
        }
      // 适配：容器背景使用系统填充色 (浅色是浅灰，深色是深灰)
        .padding(4)
        .background(Color(UIColor.secondarySystemFill), in: Capsule())
        .padding(.horizontal)
    }

}


struct LeaderboardRowView: View {

  
  let entry: LeaderboardEntry
    
    var body: some View {
        HStack() { // Align to baseline
            // 排名
            Text("\(entry.rank)")
                .font(.body)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .foregroundColor(rankColor(for: entry.rank))
                .frame(width: 30, alignment: .center)

            
            if let avatar = entry.avatar {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .padding(.leading,-5)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.secondary)
                    .padding(.leading,-5)

            }
          
            // 玩家名
            Text(entry.playerName)
            .font(.body)
                .fontWeight(.medium)
                .fontDesign(.rounded)
                .foregroundColor(Color.primary)
                .lineLimit(1) // Allow wrapping to 2 lines
            
            Spacer(minLength: 4) // Add a minimum space
            
            let scoreInt = Int64(entry.score) ?? 0
            let name = GameLevelManager.shared.getRankDescription(totalScore: scoreInt)
          
            // 分数
            Text(name)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
      
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
      
    }
    
    // 根据排名返回不同颜色
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1:
            return .yellow
        case 2:
            return Color(red: 192/255, green: 192/255, blue: 192/255) // 银色
        case 3:
            return Color(red: 205/255, green: 127/255, blue: 50/255) // 古铜色
        default:
            return .secondary // 适配：系统次级色
        }
    }
}

// MARK: - 主排行榜视图 (List 基础版本)
struct LeaderboardListView: View {
   
    @State private var entries: [LeaderboardEntry] = []
    @State private var selectedTimeScope: GKLeaderboard.TimeScope = .today
    @State private var isLoading = false
    @State private var cachedEntries: [GKLeaderboard.TimeScope: [LeaderboardEntry]] = [:]

  
    @Namespace private var animation
   
    // --- 新增状态 ---
    @State private var showTimeoutToast = false
    @State private var timeoutTimer: Timer?

    // 为 watchOS 添加 SkySyncManager 观察者
    @ObservedObject private var skySyncManager = SkySyncManager.shared
    
      
    private let timeScopes: [(name: String, scope: GKLeaderboard.TimeScope)] = [
        (NSLocalizedString("leaderboard.daily", comment: ""), .today),
        (NSLocalizedString("leaderboard.weekly", comment: ""), .week),
        (NSLocalizedString("leaderboard.alltime", comment: ""), .allTime),
    ]

    var body: some View {
      ZStack {
        
         // 适配：使用系统分组背景色 (Light是浅灰，Dark是纯黑)
          Color(UIColor.systemGroupedBackground)
            .ignoresSafeArea()
        
            VStack(spacing: 8) {
                // 分段选择器
          
              SegmentedSelectorView(
                  items: timeScopes,
                  selectedScope: $selectedTimeScope)
                  
                // 列表内容
                if isLoading {
                    Spacer()
                  ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .green))
                    Spacer()
                } else if entries.isEmpty {
                    Spacer()
                    Text(NSLocalizedString("leaderboard.no.rank", comment: "") )
                    .font(.body)
                    .fontWeight(.bold)

                    Spacer()
                } else {
                  ScrollView {
                    LazyVStack(spacing: 8) {
                      ForEach(entries) { entry in
                        LeaderboardRowView(entry: entry)
                      }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                  }
                  .refreshable {
                       loadRealEntries(forceRefresh: true)
                  }
                }
            }
        }
        .onAppear {
          loadRealEntries(forceRefresh: true) // 页面首次显示强制刷新

        }
        .onChange(of: selectedTimeScope) { newScope in
          
          loadRealEntries(forceRefresh: true) //手机每次都强制刷新
          
        }
        .onReceive(skySyncManager.$leaderboardEntries) { newEntries in
            // 收到数据，说明请求成功，取消超时定时器
            timeoutTimer?.invalidate()
            
            // 仅当还在加载状态时才更新UI，防止旧的请求覆盖新数据
            if isLoading {
                self.entries = newEntries
                self.isLoading = false
                self.cachedEntries[self.selectedTimeScope] = newEntries
            }
        }
      
    }

    private func loadRealEntries(forceRefresh: Bool = false) {
        // 1. 取消上一个定时器
        timeoutTimer?.invalidate()

        // 2. 优先使用缓存
        if !forceRefresh, let cached = cachedEntries[selectedTimeScope] {
            self.entries = cached
            self.isLoading = false
            return
        }

        // 3. 清空当前条目并开始加载
        self.isLoading = true
        if forceRefresh {
            self.entries = []
        }

        // 5. 在 iOS 上：直接请求
        Task {
            let fetchedEntries = await GameCenterManager.shared.fetchLeaderboardEntries(
              for: SkyConstants.GameCenter.Leaderboard.playerLevel.rawValue,
                timeScope: selectedTimeScope
            )
            await MainActor.run {
                cachedEntries[selectedTimeScope] = fetchedEntries
                self.entries = fetchedEntries
                self.isLoading = false
            }
        }
    }

    
}


import SwiftUI
struct PhoneSettingsView: View {
    @ObservedObject private var syncManager = SkySyncManager.shared

    @AppStorage("app_theme_preference") private var selectedTheme: AppTheme = .dark

  
    @State private var faqItems: [SkyFAQItem] = [
        SkyFAQItem(
            question: "手机和手表的数据是独立的吗？",
            answer: "是的，手机版和手表版的游戏进度是完全独立的。您可以在两个平台上分别体验修仙之旅，互不影响。"
        ),
        SkyFAQItem(
            question: "手机购买后，手表没有解锁怎么办？",
            answer: "购买是通用的，但可能需要几分钟同步。请尝试：\n1. 在设置中点击「恢复契约」按钮；\n2. 完全关闭并重新打开 App；\n3. 确保手机和手表使用同一个 Apple ID 登录。"
        ),
    
        SkyFAQItem(
            question: "排行榜显示的是手机还是手表的成绩？",
            answer: "排行榜可以切换显示。点击排行榜页面右上角的图标（⌚️/📱）即可在手表排行榜和手机排行榜之间切换查看。"
        ),
        SkyFAQItem(
            question: "游戏数据会丢失吗？",
            answer: "游戏数据保存在设备本地。\n注意：卸载应用会导致所有游戏数据永久丢失，请谨慎操作。\n建议定期通过 iCloud 或 iTunes 备份您的设备。"
        ),
        SkyFAQItem(
            question: NSLocalizedString("faq_missing_app_q", comment: ""),
            answer: NSLocalizedString("faq_missing_app_a", comment: "")
        ),
        SkyFAQItem(
            question: NSLocalizedString("faq_missing_sounds_q", comment: ""),
            answer: NSLocalizedString("faq_missing_sounds_a", comment: "")
        ),
        SkyFAQItem(
            question: NSLocalizedString("faq_missing_data_q", comment: ""),
            answer: NSLocalizedString("faq_missing_data_a", comment: "")
        ),
        
//        SkyFAQItem(
//            question: NSLocalizedString("faq_missing_center_q", comment: ""),
//            answer: NSLocalizedString("faq_missing_center_a", comment: "")
//        )
        
    ]
    
    private let privacyURL = URL(string: "https://sites.google.com/view/landlord-privacy-policy/")!
    private let termsURL = URL(string: "https://sites.google.com/view/landlord-privacy-policy/")!
    private let contactEmail = "lbbox@foxmail.com"
    
    @Environment(\.openURL) private var openURL
    
    // 支持我们 App Store ID
    private let appStoreID =  "6756813357"
  
    // 我们的产品数组
    private let products: [SkyProductItem] = [
      
        SkyProductItem(
            id: "6755930349",
            name: NSLocalizedString("product_6755930349_name", comment: "产品名称"),
            subtitle: NSLocalizedString("product_6755930349_subtitle", comment: "产品副标题"),
            iconName: "logo7",
            color: Color.tabColor
        ),
      
        SkyProductItem(
            id: "6755140397",
            name: NSLocalizedString("product_6755140397_name", comment: "产品名称"),
            subtitle: NSLocalizedString("product_6755140397_subtitle", comment: "产品副标题"),
            iconName: "logo0",
            color: Color.tabColor
        ),
        
        SkyProductItem(
            id: "6743487416",
            name: NSLocalizedString("product_6743487416_name", comment: "产品名称"),
            subtitle: NSLocalizedString("product_6743487416_subtitle", comment: "产品副标题"),
            iconName: "logo1",
            color: Color.tabColor
        ),
        SkyProductItem(
            id: "6742131931",
            name: NSLocalizedString("product_6742131931_name", comment: "产品名称"),
            subtitle: NSLocalizedString("product_6742131931_subtitle", comment: "产品副标题"),
            iconName: "logo2",
            color: Color.tabColor
        ),
        SkyProductItem(
            id: "6744266001",
            name: NSLocalizedString("product_6744266001_name", comment: "产品名称"),
            subtitle: NSLocalizedString("product_6744266001_subtitle", comment: "产品副标题"),
            iconName: "logo3",
            color: Color.tabColor
        ),
        SkyProductItem(
            id: "6744744278",
            name: NSLocalizedString("product_6744744278_name", comment: "产品名称"),
            subtitle: NSLocalizedString("product_6744744278_subtitle", comment: "产品副标题"),
            iconName: "logo4",
            color: Color.tabColor
        ),
        SkyProductItem(
            id: "6749309578",
            name: NSLocalizedString("product_6749309578_name", comment: "产品名称"),
            subtitle: NSLocalizedString("product_6749309578_subtitle", comment: "产品副标题"),
            iconName: "logo5",
            color: Color.tabColor
        ),
        SkyProductItem(
            id: "6752029081",
            name: NSLocalizedString("product_6752029081_name", comment: "产品名称"),
            subtitle: NSLocalizedString("product_6752029081_subtitle", comment: "产品副标题"),
            iconName: "logo6",
            color: Color.tabColor
        )
    ]


    var body: some View {
      
      ZStack {
        
        List {
          
//          // ✨ 新增：外观设置 Section
//          Section(header: Text(NSLocalizedString("settings_section_appearance", comment: "外观"))) {
//            Picker(NSLocalizedString("theme_title", comment: "主题模式"), selection: $selectedTheme) {
//              ForEach(AppTheme.allCases) { theme in
//                Text(theme.displayName).tag(theme)
//              }
//            }
//            .pickerStyle(.segmented) // 或者 .navigationLink，看你喜好
//          }
          
          // --- 连接状态 ---
          Section(header: Text(NSLocalizedString("settings_section_connection", comment: ""))) {
            StatusRow(title: NSLocalizedString("phone_service", comment: ""), status: phoneServiceStatus)
            StatusRow(title: NSLocalizedString("watch_app_status", comment: ""), status: watchAppInstallStatus)
            StatusRow(title: NSLocalizedString("reachability_status", comment: ""), status: reachabilityStatus)
          }

          
          //            // --- FAQ ---
          Section(header: Text(NSLocalizedString("settings_section_faq", comment: ""))) {
            ForEach($faqItems) { $item in
              VStack(alignment: .leading, spacing: 6) {
                Button {
                  withAnimation {
                    item.isExpanded.toggle()
                  }
                } label: {
                  HStack {
                    Text(item.question)
                      .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                      .font(.body)               // 使用系统字体大小
                      .foregroundColor(.gray)    // 箭头灰色
                      .rotationEffect(.degrees(item.isExpanded ? 90 : 0))
                      .animation(.spring, value:item.isExpanded)
                  }
                }
                .padding(.vertical, 4)
                
                if item.isExpanded {
                  Text(item.answer)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
                    .padding(.leading, 0)
                    .padding(.vertical, 4)
                }
              }
            }
          }

          // --- 支持我们 ---
          Section(header: Text(NSLocalizedString("settings_section_supportus", comment: ""))) {
            // 分享
            LinkRow(title: NSLocalizedString("shareus", comment: ""), icon: "square.and.arrow.up") {
              let appURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
              let description = "Check out this awesome billiards game! Fun for all ages."
              let items: [Any] = [description, appURL]
              let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
              
              if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                 let root = scene.windows.first?.rootViewController {
                root.present(av, animated: true, completion: nil)
              }
              
            }
            
            // 去评分
            LinkRow(title: NSLocalizedString("rateus", comment: ""), icon: "star") {
              if let url = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review") {
                openURL(url)
              }
            }
            
            // 联系我们
            LinkRow(title: NSLocalizedString("contact_us", comment: ""), icon: "envelope") {
              
              let device = UIDevice.current
              let model = device.model
              let systemVersion = device.systemVersion
              let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
              let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
              let subject = "Sky \(appVersion)(\(buildNumber)) \(model) iOS \(systemVersion)"
              
              if let url = URL(string: "mailto:\(contactEmail)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                openURL(url)
              }
            }
          }

          
          // --- 其他 ---
          Section(header: Text(NSLocalizedString("settings_section_other", comment: ""))) {
            LinkRow(title: NSLocalizedString("privacy_policy", comment: ""), icon: "chevron.right") {
              openURL(privacyURL)
            }
            LinkRow(title: NSLocalizedString("terms_of_service", comment: ""), icon: "chevron.right") {
              openURL(termsURL)
            }
          }

          // --- 我们的产品 ---
          Section(header: Text(NSLocalizedString("settings_section_apps", comment: "")),
                  footer: Text("Version " +  "\(appVersion) (\(buildVersion))")
            .font(.footnote)
            .foregroundColor(.gray)
          ) {
            ForEach(products) { product in
              LinkRow(title: "", icon: nil) {
                if let url = URL(string: "https://apps.apple.com/app/id\(product.id)") {
                  openURL(url)
                }
              } customContent: {
                AnyView(
                  HStack(spacing: 12) {
                    Image(product.iconName)
                      .resizable()
                      .scaledToFit()
                      .frame(width: 40, height: 40)
                      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    
                    
                    VStack(alignment: .leading, spacing: 2) {
                      Text(product.name)
                        .foregroundColor(.green)
                      // .fontWeight(.semibold)
                      Text(product.subtitle)
                        .foregroundColor(.secondary)
                        .font(.footnote)
                    }
                    Spacer()
                  }
                )
              }
            }
          }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(NSLocalizedString("settings_nav_title", comment: ""))
        // ✨ 新增：右上角工具栏 九天玄仙颜色白色
//        .toolbar {
//          ToolbarItem(placement: .topBarTrailing) {
//            // 使用 Menu 包装 Picker
//            Menu {
//              Picker(NSLocalizedString("theme_title", comment: "主题模式"), selection: $selectedTheme) {
//                ForEach(AppTheme.allCases) { theme in
//                  // 这里加个图标更直观
//                  Label(theme.displayName, systemImage: getThemeIcon(theme))
//                    .tag(theme)
//                }
//              }
//              // 在 Menu 里通常不需要设置 pickerStyle，系统会自动处理为勾选列表
//            } label: {
//              // 导航栏上显示的图标 (根据当前模式变化)
//              Image(systemName: "circle.lefthalf.filled") // 经典的深浅色切换图标
//                .foregroundColor(.primary)
//            }
//          }
//        }
      }
   
    }
  
  // 辅助：给不同主题配个小图标
     private func getThemeIcon(_ theme: AppTheme) -> String {
         switch theme {
         case .system: return "gearshape"
         case .dark: return "moon.fill"
         case .light: return "sun.max.fill"
         }
     }
  
    
    // --- 状态计算属性 ---
    private var phoneServiceStatus: (text: String, color: Color) {
        switch syncManager.activationState {
        case .activated: return (NSLocalizedString("status_on", comment: ""), .green)
        case .inactive: return (NSLocalizedString("status_inactive", comment: ""), .orange)
        case .notActivated: return (NSLocalizedString("status_not_started", comment: ""), .red)
        @unknown default: return (NSLocalizedString("status_unknown", comment: ""), .gray)
        }
    }
    
    private var watchAppInstallStatus: (text: String, color: Color) {
        syncManager.isWatchAppInstalled
        ? (NSLocalizedString("installed", comment: ""), .green)
        : (NSLocalizedString("not_installed", comment: ""), .red)
    }
    
    private var reachabilityStatus: (text: String, color: Color) {
        syncManager.isReachable
        ? (NSLocalizedString("online", comment: ""), .green)
        : (NSLocalizedString("offline", comment: ""), .orange)
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
    }
  
    private var buildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
    }
  
}

// --- 通用 LinkRow ---
struct LinkRow: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let customContent: (() -> AnyView)?

    init(title: String, icon: String? = nil, action: @escaping () -> Void, customContent: (() -> AnyView)? = nil) {
        self.title = title
        self.icon = icon
        self.action = action
        self.customContent = customContent
    }

  var body: some View {
          Button {
              action()
          } label: {
              HStack {
                  // 自定义内容或文字
                  if let customContent = customContent {
                      customContent()
                  } else {
                      Text(title)
                      Spacer()
                  }

                  // 图标处理
                  if let icon = icon {
                      if icon == "chevron.right" {
                          // 系统箭头大小，跟 List 一致
                          Image(systemName: icon)
                              .font(.body)               // 使用系统字体大小
                              .foregroundColor(.gray)    // 箭头灰色
                      } else {
                          // 其他图标统一大小
                          Image(systemName: icon)
                              .resizable()
                              .scaledToFit()
                              .frame(width: 20, height: 20)
                              .foregroundColor(.primary)
                      }
                  }
              }
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
    }
}

// --- 子视图 ---
struct StatusRow: View {
    let title: String
    let status: (text: String, color: Color)
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(status.text)
                .foregroundColor(status.color)
                .fontWeight(.bold)
        }
    }
}

struct SkyFAQItem: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let answer: String
    var isExpanded: Bool = false
}

struct SkyProductItem: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let iconName: String
    let color: Color
}

// --- App Store 信息结构 ---
struct SkyAppInfo: Identifiable {
    let id: String        // App ID
    let name: String
    let subtitle: String
    let iconURL: String
}

// --- SwiftUI Preview ---
#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PhoneSettingsView()
        }
    }
}
#endif


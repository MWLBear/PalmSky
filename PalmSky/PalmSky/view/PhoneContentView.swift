import SwiftUI

struct PhoneContentView: View {
    @State private var showReference = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. 设置背景色 (深色)
                Color.black.ignoresSafeArea()
                // 2. 核心八卦容器
                BaguaContainerView()
            }
            .navigationTitle("掌上修仙")
            .navigationBarTitleDisplayMode(.inline)
            // ✨ 保留图鉴入口
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showReference = true
                    }) {
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showReference) {
                RealmReferenceView()
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

// 预览需要模拟数据
struct PhoneContentView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneContentView()
    }
}

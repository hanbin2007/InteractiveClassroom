struct CustomTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面内容
            TabView(selection: $selectedTab) {
                Color.red.tag(0)
                Color.green.tag(1)
                Color.blue.tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // 自定义底部栏
            HStack {
                TabButton(icon: "house", title: "Home", index: 0, selectedTab: $selectedTab)
                TabButton(icon: "gear", title: "Settings", index: 1, selectedTab: $selectedTab)
                TabButton(icon: "person", title: "Profile", index: 2, selectedTab: $selectedTab)
            }
            .padding()
            .background(.ultraThinMaterial) // 毛玻璃效果
        }
    }
}

struct TabButton: View {
    var icon: String
    var title: String
    var index: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        Button {
            selectedTab = index
        } label: {
            VStack {
                Image(systemName: icon)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selectedTab == index ? .blue : .gray)
        }
    }
}
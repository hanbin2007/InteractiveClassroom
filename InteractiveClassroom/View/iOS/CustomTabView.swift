
import SwiftUI

struct TabItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}

struct CustomTabView: View {
    let tabs: [TabItem]
    @Binding var selection: Int

    private var itemSize: CGFloat {
        #if canImport(UIKit)
        return min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.12
        #elseif canImport(AppKit)
        return min(NSScreen.main?.frame.width ?? 800, NSScreen.main?.frame.height ?? 600) * 0.12
        #else
        return 60
        #endif
    }

    var body: some View {
        let size = itemSize
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: size * 0.3) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: { selection = index }) {
                        VStack(spacing: size * 0.1) {
                            RoundedRectangle(cornerRadius: size * 0.25)
                                .fill(selection == index ? Color.accentColor : Color.gray)
                                .overlay(
                                    Image(systemName: tab.icon)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.white)
                                        .padding(size * 0.2)
                                )
                                .frame(width: size, height: size)
                            Text(tab.title)
                                .font(.system(size: size * 0.25))
                                .foregroundColor(selection == index ? .primary : .secondary)
                        }
                        .frame(width: size)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, size * 0.2)
        }
        .background(.ultraThinMaterial)
    }
}

#Preview {
    @State var selection = 0
    let demoTabs = [
        TabItem(icon: "person.3.fill", title: "Students"),
        TabItem(icon: "book.closed.fill", title: "Lessons"),
        TabItem(icon: "gearshape.fill", title: "Settings"),
        TabItem(icon: "chart.bar.xaxis", title: "Reports"),
        TabItem(icon: "questionmark.circle", title: "Help")
    ]
    return CustomTabView(tabs: demoTabs, selection: $selection)
}

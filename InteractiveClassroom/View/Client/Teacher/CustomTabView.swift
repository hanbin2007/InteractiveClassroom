#if os(iOS)
import SwiftUI

struct CustomTabView: View {
    let tabs: [TabItem]
    let statusTab: TabItem
    @Binding var selection: Int

    private var itemSize: CGFloat { 70 }

    var body: some View {
        let size = itemSize * 0.8
        HStack(spacing: size * 0.6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: size * 0.6) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        tabButton(tab, index: index, size: size)
                    }
                }
                .padding(.horizontal, size * 0.5)
                .padding(.vertical, size * 0.4)
            }
            Spacer(minLength: size * 0.4)
            tabButton(statusTab, index: tabs.count, size: size)
                .padding(.trailing, size * 0.5)
        }
    }

    private func tabButton(_ tab: TabItem, index: Int, size: CGFloat) -> some View {
        Button(action: { selection = index }) {
            VStack(spacing: size * 0.1) {
                RoundedRectangle(cornerRadius: size * 0.25)
                    .fill(selection == index ? Color.accentColor : Color.gray)
                    .overlay(
                        Image(systemName: tab.icon)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .padding(size * 0.25)
                    )
                    .frame(width: size, height: size)
                Text(tab.title)
                    .font(.system(size: size * 0.3))
                    .foregroundColor(selection == index ? .primary : .secondary)
                    .bold()
            }
            .frame(width: size * 1.3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selection = 0
    let demoTabs = [
        TabItem(icon: "person.3.fill", title: "Students"),
        TabItem(icon: "book.closed.fill", title: "Lessons"),
        TabItem(icon: "gearshape.fill", title: "Settings"),
        TabItem(icon: "chart.bar.xaxis", title: "Reports"),
        TabItem(icon: "questionmark.circle", title: "Help")
    ]
    let status = TabItem(icon: "waveform.path.ecg", title: "Status")
    return CustomTabView(tabs: demoTabs, statusTab: status, selection: $selection)
}
#endif

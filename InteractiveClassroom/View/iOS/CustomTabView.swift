#if os(iOS)
import SwiftUI

struct CustomTabView: View {
    let tabs: [TabItem]
    @Binding var selection: Int

    private var itemSize: CGFloat {
        // Slightly smaller buttons for a lighter visual footprint
        70
    }

    var body: some View {
        let size = itemSize * 0.8
        ScrollView(.horizontal, showsIndicators: false) {
            // Wider gaps so tab items feel less cramped
            HStack(spacing: size * 0.6) {
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
                                        // Extra padding reduces the rendered SF Symbol size
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
            .padding(.horizontal, size * 0.5)
            .padding(.vertical, size * 0.4)
        }
//        .background(.ultraThinMaterial)
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
    return CustomTabView(tabs: demoTabs, selection: $selection)
}
#endif

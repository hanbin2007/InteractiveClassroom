#if os(macOS)
import SwiftUI

/// Overlay shown on the big screen during a quiz session.
struct ScreenOverlayView: View {
    @StateObject private var model = ScreenOverlayModel()

    var body: some View {
        GeometryReader { geometry in
            let padding: CGFloat = 32
            ZStack {
                // Top area with question type and remaining time
                VStack {
                    HStack {
                        Text(model.questionType.displayName)
                            .font(.system(size: 40, weight: .bold))
                            .shadow(color: .black, radius: 2)
                            .padding(.leading, padding)
                            .padding(.top, padding)
                        Spacer()
                        Text(model.remainingTimeString)
                            .font(.system(size: 40, weight: .bold))
                            .shadow(color: .black, radius: 2)
                            .padding(.trailing, padding)
                            .padding(.top, padding)
                    }
                    Spacer()
                }
                // Left side statistics
                HStack {
                    if !model.statsDisplay.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(model.statsDisplay, id: .self) { stat in
                                Text(stat)
                                    .font(.title3)
                                    .shadow(color: .black, radius: 1)
                            }
                        }
                        .padding(.leading, padding)
                    }
                    Spacer()
                }
                // Right side submitted names
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(model.submittedNames, id: .self) { name in
                            Text(name)
                                .font(.title3)
                                .shadow(color: .black, radius: 1)
                        }
                    }
                    .padding(.trailing, padding)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color.clear)
        .ignoresSafeArea()
        .foregroundStyle(.white)
    }
}
#endif

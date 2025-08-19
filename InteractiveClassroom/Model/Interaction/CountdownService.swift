import Foundation
import Combine

@MainActor
final class CountdownService: ObservableObject {
    @Published private(set) var remainingSeconds: Int
    private var timer: AnyCancellable?
    private var endDate: Date?

    init(seconds: Int) {
        self.remainingSeconds = max(0, seconds)
    }

    func start(onCompletion: @escaping @MainActor () -> Void) {
        stop()
        guard remainingSeconds > 0 else {
            onCompletion()
            return
        }
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self, let endDate else { return }
                let newValue = max(0, Int(endDate.timeIntervalSince(now).rounded(.down)))
                if newValue != self.remainingSeconds {
                    self.remainingSeconds = newValue
                }
                if newValue == 0 {
                    self.stop()
                    onCompletion()
                }
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        endDate = nil
    }
}

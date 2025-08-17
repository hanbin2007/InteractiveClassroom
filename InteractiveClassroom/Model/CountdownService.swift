import Foundation
import Combine

@MainActor
final class CountdownService: ObservableObject {
    @Published private(set) var remainingSeconds: Int
    private var task: Task<Void, Never>?

    init(seconds: Int) {
        self.remainingSeconds = max(0, seconds)
    }

    func start(onCompletion: @escaping @MainActor () -> Void) {
        task?.cancel()
        task = Task { [weak self] in
            while let self, self.remainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.remainingSeconds -= 1
            }
            await onCompletion()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}

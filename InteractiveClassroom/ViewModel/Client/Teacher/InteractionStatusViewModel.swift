#if os(iOS)
import Foundation
import Combine

@MainActor
final class InteractionStatusViewModel: ObservableObject {
    @Published var countdownService: CountdownService?
    @Published var activeInteraction: Interaction?

    private var service: InteractionService?
    private var cancellables = Set<AnyCancellable>()

    func bind(to service: InteractionService) {
        guard self.service == nil else { return }
        self.service = service

        service.$countdownService
            .receive(on: RunLoop.main)
            .assign(to: \.countdownService, on: self)
            .store(in: &cancellables)

        service.$activeInteraction
            .receive(on: RunLoop.main)
            .assign(to: \.activeInteraction, on: self)
            .store(in: &cancellables)
    }

    func stopCurrentInteraction() {
        service?.endInteraction()
    }
}
#endif

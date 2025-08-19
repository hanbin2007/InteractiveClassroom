#if os(iOS)
import Foundation
import Combine

@MainActor
final class InteractionStatusViewModel: ObservableObject {
    @Published var countdownService: CountdownService?
    @Published var activeInteraction: Interaction?
    @Published var canAdvanceStage: Bool = false

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
            .sink { [weak self] interaction in
                self?.activeInteraction = interaction
                if let interaction,
                   case .multipleChoice = interaction.request.content {
                    self?.canAdvanceStage = !interaction.isLastStage
                } else {
                    self?.canAdvanceStage = false
                }
            }
            .store(in: &cancellables)
    }

    func stopCurrentInteraction() {
        service?.endInteraction()
    }

    func advanceStage() {
        service?.nextStage()
    }
}
#endif

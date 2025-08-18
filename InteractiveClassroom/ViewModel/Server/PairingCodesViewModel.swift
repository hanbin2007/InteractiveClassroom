import Combine
import Foundation

@MainActor
final class PairingCodesViewModel: ObservableObject {
    @Published var teacherCode: String?
    @Published var studentCode: String?

    private var cancellables = Set<AnyCancellable>()
    private var pairingService: PairingService?

    func bind(to service: PairingService) {
        guard pairingService == nil else { return }
        pairingService = service

        service.$teacherCode
            .receive(on: RunLoop.main)
            .assign(to: \.teacherCode, on: self)
            .store(in: &cancellables)

        service.$studentCode
            .receive(on: RunLoop.main)
            .assign(to: \.studentCode, on: self)
            .store(in: &cancellables)
    }
}

#if os(iOS)
import Foundation

/// View model managing the creation of a multiple-choice interaction.
final class MultipleChoiceSetupViewModel: ObservableObject {
    /// Editable option used in the setup form.
    struct EditableOption: Identifiable {
        var id = UUID()
        var text: String = ""
    }

    @Published var duration: Int = 60
    @Published var allowsMultipleSelection = false
    @Published var options: [EditableOption] = [EditableOption(), EditableOption()]
    @Published var correctOptionIDs: Set<UUID> = []

    var canStart: Bool {
        duration > 0 && options.count >= 2 && !correctOptionIDs.isEmpty
    }

    func addOption() {
        options.append(EditableOption())
    }

    func removeOption(id: UUID) {
        options.removeAll { $0.id == id }
        correctOptionIDs.remove(id)
    }

    func toggleCorrect(for id: UUID) {
        if allowsMultipleSelection {
            if correctOptionIDs.contains(id) { correctOptionIDs.remove(id) } else { correctOptionIDs.insert(id) }
        } else {
            correctOptionIDs = [id]
        }
    }

    func start(interactionService: InteractionService) {
        let question = MultipleChoiceQuestion(
            options: options.map { .init(id: $0.id.uuidString, text: $0.text) },
            correctOptionIDs: correctOptionIDs.map { $0.uuidString },
            allowsMultipleSelection: allowsMultipleSelection
        )
        let request = InteractionRequest(
            template: .floatingCorner,
            lifecycle: .finite(seconds: duration),
            content: .multipleChoice(question)
        )
        interactionService.startInteraction(request)
    }
}
#endif

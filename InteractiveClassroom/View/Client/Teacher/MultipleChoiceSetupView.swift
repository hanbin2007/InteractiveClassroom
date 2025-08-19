#if os(iOS)
import SwiftUI

/// View allowing teachers to configure and launch a multiple-choice interaction.
struct MultipleChoiceSetupView: View {
    @EnvironmentObject private var interactionService: InteractionService
    @StateObject private var viewModel = MultipleChoiceSetupViewModel()

    var body: some View {
        Form {
            Section("Duration") {
                Stepper(value: $viewModel.duration, in: 10...3600, step: 10) {
                    Text("\(viewModel.duration) s")
                }
            }

            Section("Options") {
                ForEach($viewModel.options) { $option in
                    HStack {
                        TextField("Option", text: $option.text)
                        Button(role: .destructive) {
                            viewModel.removeOption(id: option.id)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button {
                    viewModel.addOption()
                } label: {
                    Label("Add Option", systemImage: "plus.circle")
                }
            }

            Section("Answer") {
                Toggle("Allow multiple selection", isOn: $viewModel.allowsMultipleSelection)
                ForEach(viewModel.options) { option in
                    Button {
                        viewModel.toggleCorrect(for: option.id)
                    } label: {
                        HStack {
                            Text(option.text.isEmpty ? "Untitled" : option.text)
                            Spacer()
                            if viewModel.correctOptionIDs.contains(option.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                Button("Start Interaction") {
                    viewModel.start(interactionService: interactionService)
                }
                .disabled(!viewModel.canStart || interactionService.activeInteraction != nil)
            }
        }
        .navigationTitle("Quiz")
        .onAppear {
            interactionService.requestInteractionStatus()
        }
    }
}
#endif

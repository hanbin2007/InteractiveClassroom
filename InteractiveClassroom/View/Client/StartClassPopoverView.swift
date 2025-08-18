#if os(iOS)
import SwiftUI

/// Popover allowing teachers to schedule a class start time.
struct StartClassPopoverView: View {
    var onSchedule: (Date) -> Void
    @State private var selectedDate: Date = Date()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            DatePicker("Start Time", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                .datePickerStyle(.wheel)
            HStack {
                Button("Start Now") {
                    onSchedule(Date())
                    dismiss()
                }
                Spacer()
                Button("Schedule") {
                    onSchedule(selectedDate)
                    dismiss()
                }
            }
        }
        .padding()
        .presentationCompactAdaptation(.none)
    }
}
#endif

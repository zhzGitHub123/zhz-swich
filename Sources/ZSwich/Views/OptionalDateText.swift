import SwiftUI

struct OptionalDateText: View {
    let date: Date?
    var includesTime = false

    var body: some View {
        if let date {
            if includesTime {
                Text(date, format: .dateTime.month().day().hour().minute())
            } else {
                Text(date, format: .dateTime.year().month().day())
            }
        } else {
            Text("—")
                .foregroundStyle(.tertiary)
        }
    }
}

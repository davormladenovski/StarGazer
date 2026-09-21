import SwiftUI

struct EventsCalendarView: View {
    @State private var vm = EventsViewModel()

    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "LLLL yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader
                    calendarGrid
                    legend
                    Divider().background(ColorTheme.textSecondary.opacity(0.3))
                    eventList
                }
                .padding()
            }
        }
        .navigationTitle("Events")
        .toolbarBackground(.hidden, for: .navigationBar)
        .themedToolbar()
    }

    private var monthHeader: some View {
        HStack {
            Button { vm.goToPreviousMonth() } label: {
                Image(systemName: "chevron.left").font(.title3.bold())
            }
            Spacer()
            Text(monthFormatter.string(from: vm.displayedMonth).capitalized)
                .font(.title3.bold())
                .foregroundStyle(ColorTheme.textPrimary)
            Spacer()
            Button { vm.goToNextMonth() } label: {
                Image(systemName: "chevron.right").font(.title3.bold())
            }
        }
        .foregroundStyle(ColorTheme.secondaryAccent)
    }

    // MARK: - Grid

    private var calendarGrid: some View {
        let days = daysInMonth(vm.displayedMonth)
        return VStack(spacing: 6) {
            HStack {
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { d in
                    Text(d).font(.caption2.bold())
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { date in
                    dayCell(date: date)
                }
            }
        }
    }

    private func dayCell(date: Date) -> some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: vm.displayedMonth, toGranularity: .month)
        let isSelected = calendar.isDate(date, inSameDayAs: vm.selectedDate)
        let isToday = calendar.isDateInToday(date)
        let day = calendar.component(.day, from: date)
        let dot = calendar.startOfDay(for: date)
        let dotTypes = vm.datesWithEvents[dot] ?? []

        return VStack(spacing: 3) {
            Text("\(day)")
                .font(.callout)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(
                    isSelected ? .black
                    : isCurrentMonth ? ColorTheme.textPrimary
                    : ColorTheme.textSecondary.opacity(0.5)
                )
            HStack(spacing: 2) {
                ForEach(Array(dotTypes.prefix(3).enumerated()), id: \.offset) { _, t in
                    Circle().fill(t.color).frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(isSelected ? ColorTheme.primaryAccent : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday && !isSelected ? ColorTheme.secondaryAccent : .clear, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            vm.selectedDate = date
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 12) {
            legendItem(color: .white, label: "Full moon")
            legendItem(color: .red, label: "Meteors")
            legendItem(color: .purple, label: "Eclipse")
            legendItem(color: .blue, label: "ISS")
            Spacer()
        }
        .font(.caption2)
        .foregroundStyle(ColorTheme.textSecondary)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
        }
    }

    // MARK: - Event list

    private var eventList: some View {
        let events = vm.monthEvents
        return VStack(alignment: .leading, spacing: 10) {
            Text(events.isEmpty ? "No events this month" : "Events this month")
                .font(.caption.bold())
                .foregroundStyle(ColorTheme.textSecondary)
            ForEach(events) { event in
                NavigationLink {
                    EventDetailView(event: event)
                } label: {
                    eventRow(event)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func eventRow(_ event: AstronomicalEvent) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(event.type.color.opacity(0.25)).frame(width: 40, height: 40)
                Image(systemName: event.type.icon).foregroundStyle(event.type.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name).font(.subheadline.bold()).foregroundStyle(ColorTheme.textPrimary)
                Text(dateLine(event.date)).font(.caption).foregroundStyle(ColorTheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { vm.notifyToggles[event.id] ?? false },
                set: { _ in vm.toggleNotify(for: event) }
            ))
            .labelsHidden()
            .tint(ColorTheme.primaryAccent)
        }
        .padding(12)
        .glassCard(cornerRadius: 14, tint: event.type.color)
    }

    private func dateLine(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d MMM, HH:mm"
        return f.string(from: d)
    }

    private func daysInMonth(_ month: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeekday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthInterval.start)) else {
            return []
        }
        // Find Monday of the week containing the first of the month
        var startOfGrid = monthInterval.start
        let weekday = calendar.component(.weekday, from: startOfGrid)
        // weekday: 1 = Sunday, 2 = Monday, ...
        let backOff = (weekday + 5) % 7
        startOfGrid = calendar.date(byAdding: .day, value: -backOff, to: startOfGrid) ?? firstWeekday
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfGrid) }
    }
}

#Preview {
    EventsCalendarView().preferredColorScheme(.dark)
}

import SwiftUI

struct CalendarView: View {
    @State private var displayMonth: Date = Self.firstDayOfMonth(Date())
    @State private var sessionsByDay: [String: Int] = [:]
    @State private var loading = false

    private let cal = Calendar.current
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f
    }()

    // MARK: - 달력 계산

    private var monthTitle: String {
        Self.monthFormatter.string(from: displayMonth)
    }

    private var gridDays: [Date?] {
        let first = displayMonth
        let weekday = cal.component(.weekday, from: first) - 1   // 0=일
        let count   = cal.range(of: .day, in: .month, for: first)!.count
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for i in 0 ..< count {
            days.append(cal.date(byAdding: .day, value: i, to: first))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private var monthTotalSeconds: Int { sessionsByDay.values.reduce(0, +) }

    // MARK: - body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigator
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                weekdayHeader
                    .padding(.horizontal, 8)

                Divider()

                if loading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            calendarGrid
                                .padding(.horizontal, 8)
                                .padding(.top, 4)

                            if monthTotalSeconds > 0 {
                                monthSummary
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("달력")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: displayMonth) { await loadSessions() }
    }

    // MARK: - 서브뷰

    private var monthNavigator: some View {
        HStack {
            Button {
                displayMonth = cal.date(byAdding: .month, value: -1, to: displayMonth)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }
            Spacer()
            Text(monthTitle).font(.title3.bold())
            Spacer()
            Button {
                let next = cal.date(byAdding: .month, value: 1, to: displayMonth)!
                if next <= Self.firstDayOfMonth(Date()) {
                    displayMonth = next
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(
                        cal.date(byAdding: .month, value: 1, to: displayMonth)! <= Self.firstDayOfMonth(Date())
                        ? Color.appPrimary : Color.secondary.opacity(0.3)
                    )
            }
            .disabled(cal.date(byAdding: .month, value: 1, to: displayMonth)! > Self.firstDayOfMonth(Date()))
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { d in
                Text(d)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(gridDays.enumerated()), id: \.offset) { _, date in
                if let date {
                    let key = dayKey(date)
                    DayCell(
                        day:          cal.component(.day, from: date),
                        studySeconds: sessionsByDay[key] ?? 0,
                        isToday:      cal.isDateInToday(date)
                    )
                } else {
                    Color.clear.frame(height: 60)
                }
            }
        }
    }

    private var monthSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("이번 달 총 학습")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formattedTime(monthTotalSeconds))
                    .font(.title2.bold())
                    .foregroundStyle(Color.appPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("학습일")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(sessionsByDay.filter { $0.value > 0 }.count)일")
                    .font(.title2.bold())
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - 헬퍼

    private func dayKey(_ date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }

    private static func firstDayOfMonth(_ date: Date) -> Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: date))!
    }

    // MARK: - 데이터

    private func loadSessions() async {
        loading = true
        defer { loading = false }
        let year  = cal.component(.year,  from: displayMonth)
        let month = cal.component(.month, from: displayMonth)
        let sessions = (try? await DataService.fetchMonthlySessions(year: year, month: month)) ?? []
        var byDay: [String: Int] = [:]
        for s in sessions {
            let key = Self.dayFormatter.string(from: s.studiedAt)
            byDay[key, default: 0] += s.durationSeconds
        }
        sessionsByDay = byDay
    }
}

// MARK: - 날짜 셀

private struct DayCell: View {
    let day: Int
    let studySeconds: Int
    let isToday: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 28, height: 28)
                }
                Text("\(day)")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? .white : .primary)
            }

            if studySeconds > 0 {
                Text(formattedTime)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
            } else {
                Text(" ").font(.system(size: 9))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(studySeconds > 0 && !isToday ? Color.appPrimary.opacity(0.05) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var formattedTime: String {
        let h = studySeconds / 3600
        let m = (studySeconds % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }
}

import SwiftUI

struct TestView: View {
    let title: String
    let cards: [Card]

    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .setup
    @State private var questions: [StudyQuestion] = []
    @State private var results: [QuestionResult] = []
    @State private var selectedCount = 10
    @State private var sessionStart = Date()

    enum Phase { case setup, playing, result }

    private var availableCounts: [Int] {
        let steps = [10, 20, 30, 50]
        return steps.filter { $0 <= cards.count } + (cards.count % 10 != 0 ? [cards.count] : [])
    }

    var body: some View {
        Group {
            switch phase {
            case .setup:
                setupView
            case .playing:
                QuestionPlayerView(
                    title: title,
                    questions: questions,
                    wrongMode: "test",
                    onClose: { dismiss() },
                    onFinish: { r in
                        let duration = Int(Date().timeIntervalSince(sessionStart))
                        Task { try? await DataService.recordStudySession(durationSeconds: duration, mode: "test") }
                        results = r
                        phase = .result
                    }
                )
            case .result:
                let correct = results.filter(\.correct).count
                let score = Int((Double(correct) / Double(results.count)) * 100)
                let wrong = results.filter { !$0.correct }
                StudyResultView(
                    systemImage: score >= 90 ? "star.circle.fill" : score >= 70 ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill",
                    imageColor: score >= 90 ? .appYellow : score >= 70 ? .appGreen : .appOrange,
                    headline: score >= 90 ? "훌륭해요!" : score >= 70 ? "잘 했어요!" : "더 열심히 해봐요!",
                    score: score,
                    correctCount: correct,
                    total: results.count,
                    wrongResults: wrong,
                    savedToWrongNote: !wrong.isEmpty,
                    onRetry: { phase = .setup },
                    onRetryWrong: wrong.isEmpty ? nil : {
                        questions = StudyBuilder.testQuestions(
                            cards: wrong.map(\.question.card),
                            count: wrong.count
                        )
                        results = []
                        sessionStart = Date()
                        phase = .playing
                    },
                    onClose: { dismiss() }
                )
            }
        }
    }

    private var setupView: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("문항 수를 선택하세요")
                        .font(.title3.bold())
                    Text("총 카드 수: \(cards.count)개")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    ForEach(availableCounts, id: \.self) { count in
                        Button {
                            selectedCount = count
                        } label: {
                            HStack {
                                Text("\(count)문항")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedCount == count {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                            .padding(16)
                            .background(selectedCount == count ? Color.appPrimary.opacity(0.08) : Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectedCount == count ? Color.appPrimary : Color.black.opacity(0.08), lineWidth: 1.5)
                            )
                        }
                    }
                }

                Spacer()

                VStack(spacing: 6) {
                    Text("리콜(4지선다)과 스펠(직접 입력)이 섞여 출제돼요.\n오답은 자동으로 오답 노트에 저장됩니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)

                    PrimaryButton(title: "시작") {
                        questions = StudyBuilder.testQuestions(cards: cards, count: selectedCount)
                        results = []
                        sessionStart = Date()
                        phase = .playing
                    }
                }
            }
            .padding(24)
            .background(Color.appBackground)
            .navigationTitle("테스트 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
            }
        }
        .onAppear {
            selectedCount = availableCounts.first ?? cards.count
        }
    }
}

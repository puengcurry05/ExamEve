import SwiftUI

struct RecallView: View {
    let title: String
    let cards: [Card]

    @Environment(\.dismiss) private var dismiss
    @State private var questions: [StudyQuestion] = []
    @State private var results: [QuestionResult] = []
    @State private var phase: Phase = .playing
    @State private var sessionStart = Date()

    enum Phase { case playing, result }

    var body: some View {
        Group {
            switch phase {
            case .playing:
                if questions.isEmpty {
                    ProgressView()
                } else {
                    QuestionPlayerView(
                        title: title,
                        questions: questions,
                        wrongMode: "recall",
                        onClose: { dismiss() },
                        onFinish: { r in
                            let duration = Int(Date().timeIntervalSince(sessionStart))
                            Task { try? await DataService.recordStudySession(durationSeconds: duration, mode: "recall") }
                            results = r
                            phase = .result
                        }
                    )
                }
            case .result:
                let wrong = results.filter { !$0.correct }
                StudyResultView(
                    systemImage: wrong.isEmpty ? "checkmark.circle.fill" : "pencil.circle.fill",
                    imageColor: wrong.isEmpty ? .appGreen : .appPrimary,
                    headline: wrong.isEmpty ? "모두 맞혔어요!" : "조금 더 연습해볼까요?",
                    score: nil,
                    correctCount: results.filter(\.correct).count,
                    total: results.count,
                    wrongResults: wrong,
                    savedToWrongNote: !wrong.isEmpty,
                    onRetry: {
                        questions = StudyBuilder.recallQuestions(cards: cards)
                        results = []
                        phase = .playing
                    },
                    onRetryWrong: wrong.isEmpty ? nil : {
                        questions = StudyBuilder.recallQuestions(cards: wrong.map(\.question.card))
                        results = []
                        phase = .playing
                    },
                    onClose: { dismiss() }
                )
            }
        }
        .task {
            questions = StudyBuilder.recallQuestions(cards: cards)
            sessionStart = Date()
        }
    }
}

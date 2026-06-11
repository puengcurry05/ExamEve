import SwiftUI

struct SpellView: View {
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
                        wrongMode: nil,
                        onClose: { dismiss() },
                        onFinish: { r in
                            let duration = Int(Date().timeIntervalSince(sessionStart))
                            Task { try? await DataService.recordStudySession(durationSeconds: duration, mode: "spell") }
                            results = r
                            phase = .result
                        }
                    )
                }
            case .result:
                let wrong = results.filter { !$0.correct }
                StudyResultView(
                    systemImage: wrong.isEmpty ? "checkmark.circle.fill" : "book.circle.fill",
                    imageColor: wrong.isEmpty ? .appGreen : .appPrimary,
                    headline: wrong.isEmpty ? "스펠링 완벽!" : "한 번 더 연습해봐요",
                    score: nil,
                    correctCount: results.filter(\.correct).count,
                    total: results.count,
                    wrongResults: wrong,
                    savedToWrongNote: false,
                    onRetry: {
                        questions = StudyBuilder.spellQuestions(cards: cards)
                        results = []
                        phase = .playing
                    },
                    onRetryWrong: wrong.isEmpty ? nil : {
                        questions = StudyBuilder.spellQuestions(cards: wrong.map(\.question.card))
                        results = []
                        phase = .playing
                    },
                    onClose: { dismiss() }
                )
            }
        }
        .task {
            questions = StudyBuilder.spellQuestions(cards: cards)
            sessionStart = Date()
        }
    }
}

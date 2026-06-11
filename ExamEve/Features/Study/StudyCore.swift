import SwiftUI

enum QuestionKind {
    case recall
    case spell
}

struct StudyQuestion: Identifiable {
    let id = UUID()
    let card: Card
    let kind: QuestionKind
    let options: [String]
    let answerIndex: Int
}

struct QuestionResult {
    let question: StudyQuestion
    let correct: Bool
    let userAnswer: String
}

enum StudyBuilder {
    /// 같은 덱 내 다른 카드의 개념 3개를 랜덤 추출해 4지선다 보기 구성.
    /// 고유 개념이 부족하면 의미(meaning) 값으로 보기를 채워 항상 4지선다를 보장.
    static func recallOptions(for card: Card, in cards: [Card]) -> (options: [String], answerIndex: Int) {
        var seen = Set<String>()
        seen.insert(card.concept)

        let conceptPool = cards
            .filter { $0.id != card.id }
            .compactMap { c -> String? in
                seen.insert(c.concept).inserted ? c.concept : nil
            }
            .shuffled()

        let meaningPool = cards
            .filter { $0.id != card.id }
            .compactMap { c -> String? in
                seen.insert(c.meaning).inserted ? c.meaning : nil
            }
            .shuffled()

        var distractors = Array((conceptPool + meaningPool).prefix(3))
        // Edge case: fewer than 3 unique candidates → pad with numbered placeholders
        while distractors.count < 3 {
            distractors.append("보기 \(distractors.count + 1)")
        }

        var options = distractors
        options.append(card.concept)
        options.shuffle()
        let answerIndex = options.firstIndex(of: card.concept) ?? 0
        return (options, answerIndex)
    }

    static func recallQuestions(cards: [Card]) -> [StudyQuestion] {
        cards.shuffled().map { card in
            let (options, answerIndex) = recallOptions(for: card, in: cards)
            return StudyQuestion(card: card, kind: .recall, options: options, answerIndex: answerIndex)
        }
    }

    static func spellQuestions(cards: [Card]) -> [StudyQuestion] {
        cards.shuffled().map {
            StudyQuestion(card: $0, kind: .spell, options: [], answerIndex: 0)
        }
    }

    /// 테스트: 리콜+스펠 혼합
    static func testQuestions(cards: [Card], count: Int) -> [StudyQuestion] {
        cards.shuffled().prefix(count).map { card in
            if Bool.random() {
                let (options, answerIndex) = recallOptions(for: card, in: cards)
                return StudyQuestion(card: card, kind: .recall, options: options, answerIndex: answerIndex)
            } else {
                return StudyQuestion(card: card, kind: .spell, options: [], answerIndex: 0)
            }
        }
    }

    static func normalize(_ text: String) -> String {
        text.lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}

struct StudyHeader: View {
    let title: String
    let progressText: String
    let progress: Double
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(progressText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .monospacedDigit()
            }
            ProgressView(value: progress)
                .tint(.appPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

/// 리콜/스펠/테스트 공용 문제 플레이어
struct QuestionPlayerView: View {
    let title: String
    let questions: [StudyQuestion]
    /// 오답 기록 모드 ("recall" / "test"), nil이면 기록 안 함 (스펠)
    let wrongMode: String?
    let onClose: () -> Void
    let onFinish: ([QuestionResult]) -> Void

    @State private var current = 0
    @State private var selected: Int?
    @State private var spellInput = ""
    @State private var spellSubmitted = false
    @State private var results: [QuestionResult] = []
    @FocusState private var spellFocused: Bool

    private var question: StudyQuestion { questions[current] }

    var body: some View {
        VStack(spacing: 0) {
            StudyHeader(
                title: title,
                progressText: "\(current + 1) / \(questions.count)",
                progress: Double(current + 1) / Double(questions.count),
                onClose: onClose
            )

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("의미")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appPurple)
                        Text(question.card.meaning)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .cardStyle()

                    if question.kind == .recall {
                        recallOptions
                    } else {
                        spellInputArea
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.appBackground)
    }

    // MARK: - 리콜 (4지선다)

    private var recallOptions: some View {
        VStack(spacing: 10) {
            Text("알맞은 개념을 고르세요")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                Button {
                    selectOption(index)
                } label: {
                    HStack {
                        Text(option)
                            .font(.body.weight(.medium))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if let selected {
                            if index == question.answerIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.appGreen)
                            } else if index == selected {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.appRed)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(optionBackground(index))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(optionBorder(index), lineWidth: 1.5)
                    )
                }
                .disabled(selected != nil)
            }
        }
    }

    private func optionBackground(_ index: Int) -> Color {
        guard let selected else { return Color(.systemBackground) }
        if index == question.answerIndex { return Color.appGreen.opacity(0.12) }
        if index == selected { return Color.appRed.opacity(0.12) }
        return Color(.systemBackground)
    }

    private func optionBorder(_ index: Int) -> Color {
        guard let selected else { return Color.black.opacity(0.08) }
        if index == question.answerIndex { return Color.appGreen }
        if index == selected { return Color.appRed }
        return Color.black.opacity(0.05)
    }

    private func selectOption(_ index: Int) {
        guard selected == nil else { return }
        selected = index
        let correct = index == question.answerIndex
        finishQuestion(correct: correct, userAnswer: question.options[index])
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            advance()
        }
    }

    // MARK: - 스펠 (직접 입력)

    private var spellInputArea: some View {
        VStack(spacing: 12) {
            if spellSubmitted {
                let correct = results.last?.correct == true
                VStack(spacing: 8) {
                    Text(correct ? "정답이에요!" : "아쉬워요")
                        .font(.headline)
                        .foregroundStyle(correct ? Color.appGreen : Color.appRed)
                    if !correct {
                        Text("내 답: \(spellInput.isEmpty ? "(입력 없음)" : spellInput)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("정답: \(question.card.concept)")
                        .font(.title3.weight(.bold))
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background((correct ? Color.appGreen : Color.appRed).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                PrimaryButton(title: current + 1 == questions.count ? "결과 보기" : "다음") {
                    advance()
                }
            } else {
                Text("개념을 직접 입력하세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                RoundedField(placeholder: "정답 입력", text: $spellInput)
                    .focused($spellFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { submitSpell() }
                PrimaryButton(title: "제출") {
                    submitSpell()
                }
            }
        }
        .onAppear { spellFocused = true }
    }

    private func submitSpell() {
        guard !spellSubmitted else { return }
        spellSubmitted = true
        spellFocused = false
        let correct = StudyBuilder.normalize(spellInput) == StudyBuilder.normalize(question.card.concept)
        finishQuestion(correct: correct, userAnswer: spellInput)
    }

    // MARK: - 공통

    private func finishQuestion(correct: Bool, userAnswer: String) {
        results.append(QuestionResult(question: question, correct: correct, userAnswer: userAnswer))
        if !correct, let wrongMode {
            let cardId = question.card.id
            Task { try? await DataService.recordWrong(cardId: cardId, mode: wrongMode) }
        }
    }

    private func advance() {
        if current + 1 < questions.count {
            current += 1
            selected = nil
            spellInput = ""
            spellSubmitted = false
        } else {
            onFinish(results)
        }
    }
}

/// 학습 결과 공용 화면
struct StudyResultView: View {
    let systemImage: String
    let imageColor: Color
    let headline: String
    let score: Int?
    let correctCount: Int
    let total: Int
    let wrongResults: [QuestionResult]
    let savedToWrongNote: Bool
    let onRetry: () -> Void
    let onRetryWrong: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: systemImage)
                    .font(.system(size: 56))
                    .foregroundStyle(imageColor)
                    .padding(.top, 40)
                Text(headline).font(.title2.bold())

                if let score {
                    ZStack {
                        Circle()
                            .stroke(Color.appPrimary.opacity(0.15), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: Double(score) / 100)
                            .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack {
                            Text("\(score)점")
                                .font(.system(size: 40, weight: .heavy))
                            Text("100점 만점")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 160, height: 160)
                }

                Text("\(total)문항 중 \(correctCount)개 정답")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if !wrongResults.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("틀린 문제").font(.headline)
                            Spacer()
                            if savedToWrongNote {
                                Label("오답에 저장됨", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.appGreen)
                            }
                        }
                        ForEach(wrongResults, id: \.question.id) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.question.card.concept)
                                    .font(.subheadline.weight(.semibold))
                                Text(result.question.card.meaning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appRed.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(16)
                    .cardStyle()
                }

                VStack(spacing: 10) {
                    PrimaryButton(title: "다시 하기", action: onRetry)
                    if !wrongResults.isEmpty, let onRetryWrong {
                        Button(action: onRetryWrong) {
                            Text("틀린 카드만 다시 (\(wrongResults.count)개)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.appRed.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    Button("닫기", action: onClose)
                        .font(.headline)
                        .padding(.vertical, 8)
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Color.appBackground)
    }
}

import SwiftUI

struct WrongAnswersView: View {
    let deckName: String
    let entries: [WrongAnswerEntry]

    @Environment(\.dismiss) private var dismiss
    @State private var current = 0
    @State private var flipped = false
    @State private var cleared = false
    @State private var errorMessage: String?

    private var card: Card { entries[current].card }

    var body: some View {
        if cleared {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.appGreen)
                Text("오답을 모두 학습했어요!")
                    .font(.title2.bold())
                Button("닫기") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        } else {
            VStack(spacing: 0) {
                StudyHeader(
                    title: "오답 복습",
                    progressText: "\(current + 1) / \(entries.count)",
                    progress: Double(current + 1) / Double(entries.count),
                    onClose: { dismiss() }
                )

                Spacer()

                VStack(spacing: 20) {
                    HStack {
                        TagChip(text: entries[current].modeLabel + " 오답", color: .appRed)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                    ZStack {
                        cardFace(text: card.meaning, label: "의미", color: .appPurple, bg: Color(.systemBackground))
                            .rotation3DEffect(.degrees(flipped ? -180 : 0), axis: (x: 0, y: 1, z: 0))
                            .opacity(flipped ? 0 : 1)
                        cardFace(text: card.concept, label: "개념", color: .appPrimary, bg: Color.appPrimary.opacity(0.05))
                            .rotation3DEffect(.degrees(flipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                            .opacity(flipped ? 1 : 0)
                    }
                    .padding(.horizontal, 24)
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.4)) { flipped.toggle() }
                    }

                    Text("탭하면 뒤집기")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                footer
            }
            .background(Color.appBackground)
            .alert("오류", isPresented: .constant(errorMessage != nil)) {
                Button("확인") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private func cardFace(text: String, label: String, color: Color, bg: Color) -> some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text(text)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .padding(28)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    Task {
                        do {
                            try await DataService.removeWrong(cardId: card.id)
                            advance()
                        } catch {
                            errorMessage = koreanMessage(for: error)
                        }
                    }
                } label: {
                    Label("알았어요", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appGreen)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                Button {
                    advance()
                } label: {
                    Label("다음에", systemImage: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 36)
    }

    private func advance() {
        flipped = false
        if current + 1 < entries.count {
            current += 1
        } else {
            cleared = true
        }
    }
}

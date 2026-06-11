import SwiftUI

struct MemorizeView: View {
    let title: String
    let cards: [Card]

    @Environment(\.dismiss) private var dismiss
    @State private var current = 0
    @State private var flipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var sessionStart = Date()

    private var card: Card { cards[current] }

    var body: some View {
        VStack(spacing: 0) {
            StudyHeader(
                title: title,
                progressText: "\(current + 1) / \(cards.count)",
                progress: Double(current + 1) / Double(cards.count),
                onClose: { dismiss() }
            )

            Spacer()

            ZStack {
                flashCard
            }
            .padding(.horizontal, 24)

            Spacer()

            footer
        }
        .background(Color.appBackground)
        .onAppear { sessionStart = Date() }
        .onDisappear {
            let duration = Int(Date().timeIntervalSince(sessionStart))
            Task { try? await DataService.recordStudySession(durationSeconds: duration, mode: "memorize") }
        }
    }

    private var flashCard: some View {
        ZStack {
            // 뒷면 (의미)
            cardFace(
                text: card.meaning,
                label: "의미",
                labelColor: .appPurple,
                background: Color.appPrimary.opacity(0.07)
            )
            .rotation3DEffect(.degrees(flipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .opacity(flipped ? 1 : 0)

            // 앞면 (개념)
            cardFace(
                text: card.concept,
                label: "개념",
                labelColor: .appPrimary,
                background: Color(.systemBackground)
            )
            .rotation3DEffect(.degrees(flipped ? -180 : 0), axis: (x: 0, y: 1, z: 0))
            .opacity(flipped ? 0 : 1)
        }
        .offset(x: dragOffset.width)
        .rotationEffect(.degrees(Double(dragOffset.width) / 20))
        .onTapGesture {
            withAnimation(.spring(duration: 0.4)) { flipped.toggle() }
        }
        .gesture(
            DragGesture()
                .onChanged { dragOffset = $0.translation }
                .onEnded { value in
                    let threshold: CGFloat = 120
                    if value.translation.width > threshold && current > 0 {
                        advance(direction: -1)
                    } else if value.translation.width < -threshold && current < cards.count - 1 {
                        advance(direction: 1)
                    } else {
                        withAnimation(.spring()) { dragOffset = .zero }
                    }
                }
        )
        .animation(.spring(), value: dragOffset)
    }

    private func cardFace(text: String, label: String, labelColor: Color, background: Color) -> some View {
        VStack(spacing: 16) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(labelColor)
            Text(text)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(28)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Text("탭하면 뒤집기 · 좌우로 밀면 카드 이동")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 24) {
                Button {
                    guard current > 0 else { return }
                    advance(direction: -1)
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(current > 0 ? Color.appPrimary : Color.secondary.opacity(0.3))
                }
                .disabled(current == 0)

                Button {
                    guard current < cards.count - 1 else {
                        dismiss()
                        return
                    }
                    advance(direction: 1)
                } label: {
                    Image(systemName: current < cards.count - 1
                          ? "chevron.right.circle.fill"
                          : "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.appPrimary)
                }
            }
        }
        .padding(.bottom, 40)
    }

    private func advance(direction: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            dragOffset = CGSize(width: direction < 0 ? 400 : -400, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            current += direction
            flipped = false
            dragOffset = .zero
        }
    }
}

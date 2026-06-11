import SwiftUI

struct DeckDetailView: View {
    let deckId: UUID

    @State private var deck: Deck
    @State private var cards: [Card] = []
    @State private var wrongEntries: [WrongAnswerEntry] = []
    @State private var loaded = false
    @State private var errorMessage: String?
    @State private var noticeMessage: String?
    @State private var showEditor = false
    @State private var showShare = false
    @State private var showDeleteConfirm = false
    @State private var studyRoute: StudyRoute?

    @Environment(\.dismiss) private var dismiss

    init(deckId: UUID, initialDeck: Deck) {
        self.deckId = deckId
        self._deck = State(initialValue: initialDeck)
    }

    enum StudyRoute: Identifiable {
        case memorize, recall, spell, test, wrong
        var id: Self { self }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                modeGrid
                cardList
            }
            .padding(16)
        }
        .background(Color.appBackground)
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditor = true
                    } label: {
                        Label("덱 편집", systemImage: "pencil")
                    }
                    Button {
                        showShare = true
                    } label: {
                        Label("공유하기", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("덱 삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            DeckEditorView(mode: .edit(deck: deck, cards: cards)) {
                Task { await load() }
            }
        }
        .sheet(isPresented: $showShare) {
            ShareDeckSheet(deck: deck) {
                Task { await load() }
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(item: $studyRoute, onDismiss: { Task { await load() } }) { route in
            switch route {
            case .memorize:
                MemorizeView(title: deck.name, cards: cards)
            case .recall:
                RecallView(title: deck.name, cards: cards)
            case .spell:
                SpellView(title: deck.name, cards: cards)
            case .test:
                TestView(title: deck.name, cards: cards)
            case .wrong:
                WrongAnswersView(deckName: deck.name, entries: wrongEntries)
            }
        }
        .confirmationDialog("이 덱을 삭제할까요?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                Task {
                    do {
                        try await DataService.deleteDeck(id: deckId)
                        dismiss()
                    } catch {
                        errorMessage = koreanMessage(for: error)
                    }
                }
            }
        } message: {
            Text("덱에 들어 있는 카드도 모두 삭제돼요.")
        }
        .alert("오류", isPresented: .constant(errorMessage != nil)) {
            Button("확인") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("안내", isPresented: .constant(noticeMessage != nil)) {
            Button("확인") { noticeMessage = nil }
        } message: {
            Text(noticeMessage ?? "")
        }
        .task { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if !deck.subject.isEmpty { TagChip(text: deck.subject) }
                if !deck.unit.isEmpty { TagChip(text: deck.unit, color: .appPurple) }
            }
            HStack(spacing: 12) {
                Label("카드 \(cards.count)개", systemImage: "rectangle.stack")
                if deck.isSharedPublic {
                    Label("전체 공유", systemImage: "globe")
                        .foregroundStyle(Color.appPrimary)
                }
                if deck.isSharedSchool {
                    Label("학교 공유", systemImage: "building.2")
                        .foregroundStyle(Color.appTeal)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var modeGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("학습 모드").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ModeButton(icon: "rectangle.stack.fill", color: .appPrimary, title: "암기", subtitle: "카드 넘기며 외우기") {
                    guard !cards.isEmpty else {
                        noticeMessage = "카드가 없어요. 먼저 카드를 추가해주세요."
                        return
                    }
                    studyRoute = .memorize
                }
                ModeButton(icon: "checklist", color: .appPurple, title: "리콜", subtitle: "4지선다 퀴즈") {
                    guard cards.count >= 4 else {
                        noticeMessage = "리콜 모드는 카드가 4개 이상일 때 사용할 수 있어요."
                        return
                    }
                    studyRoute = .recall
                }
                ModeButton(icon: "keyboard.fill", color: .appTeal, title: "스펠", subtitle: "직접 입력하기") {
                    guard !cards.isEmpty else {
                        noticeMessage = "카드가 없어요. 먼저 카드를 추가해주세요."
                        return
                    }
                    studyRoute = .spell
                }
                ModeButton(icon: "doc.text.fill", color: .appOrange, title: "테스트", subtitle: "100점 만점 시험") {
                    guard cards.count >= 4 else {
                        noticeMessage = "테스트 모드는 카드가 4개 이상일 때 사용할 수 있어요."
                        return
                    }
                    studyRoute = .test
                }
                ModeButton(
                    icon: "exclamationmark.triangle.fill",
                    color: .appRed,
                    title: "오답",
                    subtitle: wrongEntries.isEmpty ? "틀린 카드 없음" : "틀린 카드 \(wrongEntries.count)개"
                ) {
                    guard !wrongEntries.isEmpty else {
                        noticeMessage = "아직 오답이 없어요. 리콜이나 테스트에서 틀린 카드가 자동으로 모여요."
                        return
                    }
                    studyRoute = .wrong
                }
            }
        }
    }

    private var cardList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카드 목록").font(.headline)
            if cards.isEmpty && loaded {
                Text("카드가 없어요. 우측 상단 메뉴에서 덱을 편집해 카드를 추가해보세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                ForEach(cards) { card in
                    HStack(alignment: .top, spacing: 12) {
                        Text(card.concept)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Divider()
                        Text(card.meaning)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(14)
                    .cardStyle()
                }
            }
        }
    }

    private func load() async {
        do {
            if let fresh = try await DataService.fetchDeck(id: deckId) {
                deck = fresh
            }
            cards = try await DataService.cards(deckId: deckId)
            wrongEntries = try await DataService.wrongEntries(deckId: deckId)
            loaded = true
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

struct ModeButton: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct ShareDeckSheet: View {
    let deck: Deck
    var onSaved: () -> Void

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var isPublic: Bool
    @State private var isSchool: Bool
    @State private var busy = false
    @State private var errorMessage: String?

    init(deck: Deck, onSaved: @escaping () -> Void) {
        self.deck = deck
        self.onSaved = onSaved
        self._isPublic = State(initialValue: deck.isSharedPublic)
        self._isSchool = State(initialValue: deck.isSharedSchool)
    }

    private var hasSchool: Bool { appState.profile?.schoolId != nil }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Toggle(isOn: $isPublic) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("일반 공유", systemImage: "globe")
                            .font(.headline)
                        Text("모든 사용자가 공유 탭에서 볼 수 있어요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $isSchool) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("학교 공유", systemImage: "building.2")
                            .font(.headline)
                        Text(hasSchool
                             ? "\(appState.profile?.school?.name ?? "내 학교") 친구들만 볼 수 있어요."
                             : "프로필에서 학교를 설정하면 사용할 수 있어요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!hasSchool)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.appRed)
                }

                Spacer()

                PrimaryButton(title: "저장", busy: busy) {
                    Task { await save() }
                }
            }
            .padding(20)
            .navigationTitle("공유하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        busy = true
        errorMessage = nil
        defer { busy = false }
        do {
            try await DataService.setSharing(
                deckId: deck.id,
                isPublic: isPublic,
                isSchool: isSchool && hasSchool,
                schoolId: appState.profile?.schoolId
            )
            onSaved()
            dismiss()
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

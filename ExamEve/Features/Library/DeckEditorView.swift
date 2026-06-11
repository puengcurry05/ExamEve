import SwiftUI

struct EditableCard: Identifiable, Equatable {
    let id = UUID()
    var existingId: UUID?
    var concept = ""
    var meaning = ""

    var isValid: Bool {
        !concept.trimmingCharacters(in: .whitespaces).isEmpty
            && !meaning.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func == (lhs: EditableCard, rhs: EditableCard) -> Bool {
        lhs.existingId == rhs.existingId
            && lhs.concept == rhs.concept
            && lhs.meaning == rhs.meaning
    }
}

struct DeckEditorView: View {
    enum Mode {
        case create
        case edit(deck: Deck, cards: [Card])
    }

    let mode: Mode
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedSubject: Subject?
    @State private var unit = ""
    @State private var cards: [EditableCard] = [EditableCard(), EditableCard()]
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var showCancelConfirm = false
    @State private var hasEdited = false

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var saveDisabled: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty || !cards.contains(where: \.isValid)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: 덱 정보
                Section("덱 정보") {
                    TextField("덱 이름 (예: 영단어 1과)", text: $name)
                    SubjectPickerField(selectedSubject: $selectedSubject)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    TextField("단원 (예: 1단원)", text: $unit)
                }

                // MARK: 카드 목록
                Section {
                    ForEach($cards) { $card in
                        compactCardRow($card)
                    }
                    .onMove { cards.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { cards.remove(atOffsets: $0) }

                    Button {
                        withAnimation { cards.append(EditableCard()) }
                    } label: {
                        Label("카드 추가", systemImage: "plus")
                            .foregroundStyle(Color.appPrimary)
                    }
                } header: {
                    HStack {
                        Text("카드")
                        Spacer()
                        Text("\(cards.filter(\.isValid).count)개")
                            .textCase(.none)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("드래그해서 순서를 바꾸고, 스와이프해서 삭제할 수 있어요.")
                }

                // MARK: 에러
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color.appRed)
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .scrollDismissesKeyboard(.interactively)
            .background(Color.appBackground)
            .navigationTitle(isEdit ? "덱 편집" : "새 덱 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        if hasEdited { showCancelConfirm = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if busy {
                        ProgressView()
                    } else {
                        Button(isEdit ? "저장" : "만들기") {
                            Task { await save() }
                        }
                        .bold()
                        .disabled(saveDisabled)
                    }
                }
            }
            .confirmationDialog(
                "변경 내용을 버릴까요?",
                isPresented: $showCancelConfirm,
                titleVisibility: .visible
            ) {
                Button("변경 내용 버리기", role: .destructive) { dismiss() }
            }
            .onAppear { populate() }
            .onChange(of: name) { hasEdited = true }
            .onChange(of: unit) { hasEdited = true }
            .onChange(of: selectedSubject) { hasEdited = true }
            .onChange(of: cards) { hasEdited = true }
        }
        .interactiveDismissDisabled(hasEdited)
    }

    // MARK: - 카드 로우

    private func compactCardRow(_ card: Binding<EditableCard>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("개념 (앞면)", text: card.concept, axis: .vertical)
                .font(.subheadline.weight(.semibold))
                .lineLimit(3)
            Divider()
            TextField("의미 (뒷면)", text: card.meaning, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    // MARK: - 초기화

    private func populate() {
        guard case .edit(let deck, let existingCards) = mode,
              cards.allSatisfy({ $0.existingId == nil && !$0.isValid }) else { return }
        name = deck.name
        selectedSubject = deck.subjectInfo
        unit = deck.unit
        if !existingCards.isEmpty {
            cards = existingCards.map { card in
                var editable = EditableCard()
                editable.existingId = card.id
                editable.concept = card.concept
                editable.meaning = card.meaning
                return editable
            }
        }
        // onChange가 populate로 인해 트리거되지 않도록 다음 루프에서 리셋
        Task { @MainActor in hasEdited = false }
    }

    // MARK: - 저장 (병렬/배치 처리)

    private func save() async {
        busy = true
        errorMessage = nil
        defer { busy = false }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let validCards = cards.filter(\.isValid)
        do {
            switch mode {
            case .create:
                _ = try await DataService.createDeck(
                    name: trimmedName,
                    subject: selectedSubject?.name ?? "",
                    subjectId: selectedSubject?.id,
                    unit: unit.trimmingCharacters(in: .whitespacesAndNewlines),
                    cards: validCards.map {
                        (concept: $0.concept.trimmingCharacters(in: .whitespacesAndNewlines),
                         meaning: $0.meaning.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                )

            case .edit(let deck, let originalCards):
                // 1. 덱 메타 업데이트
                try await DataService.updateDeckInfo(
                    id: deck.id,
                    name: trimmedName,
                    subject: selectedSubject?.name ?? "",
                    subjectId: selectedSubject?.id,
                    unit: unit.trimmingCharacters(in: .whitespacesAndNewlines)
                )

                let keptIds = Set(validCards.compactMap(\.existingId))
                let originalById = Dictionary(uniqueKeysWithValues: originalCards.map { ($0.id, $0) })

                // 2. 삭제할 카드 배치 삭제
                let idsToDelete = originalCards
                    .filter { !keptIds.contains($0.id) }
                    .map(\.id)
                if !idsToDelete.isEmpty {
                    try await DataService.deleteCards(ids: idsToDelete)
                }

                // 3. 새 카드 배치 삽입
                let toInsert = validCards.enumerated().compactMap { index, editable -> DataService.CardInsert? in
                    guard editable.existingId == nil else { return nil }
                    return DataService.CardInsert(
                        deck_id: deck.id,
                        concept: editable.concept.trimmingCharacters(in: .whitespacesAndNewlines),
                        meaning: editable.meaning.trimmingCharacters(in: .whitespacesAndNewlines),
                        order: index
                    )
                }
                if !toInsert.isEmpty {
                    try await DataService.insertCards(toInsert)
                }

                // 4. 변경된 기존 카드 병렬 업데이트
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for (index, editable) in validCards.enumerated() {
                        guard let existingId = editable.existingId else { continue }
                        let original = originalById[existingId]
                        let concept = editable.concept.trimmingCharacters(in: .whitespacesAndNewlines)
                        let meaning = editable.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard original?.concept != concept
                            || original?.meaning != meaning
                            || (original?.position ?? -1) != index
                        else { continue }
                        group.addTask {
                            try await DataService.updateCard(
                                id: existingId, concept: concept, meaning: meaning, order: index
                            )
                        }
                    }
                    try await group.waitForAll()
                }
            }
            onSaved()
            dismiss()
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

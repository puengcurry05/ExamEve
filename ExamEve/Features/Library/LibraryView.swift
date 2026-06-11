import SwiftUI

struct LibraryView: View {
    @State private var decks: [Deck] = []
    @State private var isLoading = false
    @State private var loaded = false
    @State private var errorMessage: String?
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && !loaded {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if decks.isEmpty && loaded {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(decks) { deck in
                                NavigationLink(value: deck) {
                                    DeckRowView(deck: deck)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("학습함")
            .navigationDestination(for: Deck.self) { deck in
                DeckDetailView(deckId: deck.id, initialDeck: deck)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                DeckEditorView(mode: .create) {
                    Task { await load() }
                }
            }
            .onAppear {
                if decks.isEmpty { Task { await load() } }
            }
            .refreshable { await load() }
            .alert("오류", isPresented: .constant(errorMessage != nil)) {
                Button("확인") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("아직 덱이 없어요")
                .font(.headline)
            Text("첫 덱을 만들거나 공유 탭에서\n친구들의 덱을 다운로드해보세요!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showCreate = true
            } label: {
                Label("덱 만들기", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            decks = try await DataService.myDecks()
            loaded = true
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

struct DeckRowView: View {
    let deck: Deck

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(deck.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Spacer()
                if deck.isDownloaded {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(Color.appTeal)
                }
            }
            HStack(spacing: 6) {
                if !deck.subject.isEmpty { TagChip(text: deck.subject) }
                if !deck.unit.isEmpty { TagChip(text: deck.unit, color: .appPurple) }
            }
            HStack(spacing: 12) {
                Label("카드 \(deck.cardCount)개", systemImage: "rectangle.stack")
                if deck.isShared {
                    Label("공유 중", systemImage: "person.2.fill")
                        .foregroundStyle(Color.appPrimary)
                }
                if deck.downloadedCount > 0 {
                    Label("\(deck.downloadedCount)", systemImage: "arrow.down.to.line")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

import SwiftUI

struct CommunityView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: CommunityTab = .general
    @State private var generalDecks: [Deck] = []
    @State private var schoolDecks: [Deck] = []
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .latest
    @State private var downloadingId: UUID?
    @State private var downloadSuccess: UUID?
    @State private var downloadedSourceIds: Set<UUID> = []

    enum SortOrder { case latest, popular }

    enum CommunityTab: String, CaseIterable {
        case general = "일반"
        case school  = "학교"
    }

    private var hasSchool: Bool { appState.profile?.schoolId != nil }
    private var schoolName: String { appState.profile?.school?.name ?? "학교" }

    private var activeDecks: [Deck] {
        let source = selectedTab == .general ? generalDecks : schoolDecks
        let filtered = searchText.isEmpty ? source : source.filter { deck in
            deck.name.localizedCaseInsensitiveContains(searchText)
                || deck.subject.localizedCaseInsensitiveContains(searchText)
                || deck.unit.localizedCaseInsensitiveContains(searchText)
                || deck.ownerNickname.localizedCaseInsensitiveContains(searchText)
        }
        return sortOrder == .popular
            ? filtered.sorted { $0.downloadedCount > $1.downloadedCount }
            : filtered
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                if selectedTab == .school && !hasSchool {
                    schoolPrompt
                } else {
                    content
                }
            }
            .background(Color.appBackground)
            .navigationTitle("공유")
            .searchable(text: $searchText, prompt: "덱 이름, 과목, 닉네임 검색")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .alert("오류", isPresented: .constant(errorMessage != nil)) {
                Button("확인") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    // MARK: - 탭 피커

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(CommunityTab.allCases, id: \.self) { tab in
                let disabled = tab == .school && !hasSchool
                Button {
                    guard !disabled else { return }
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Text(tab == .school && hasSchool ? schoolName : tab.rawValue)
                            .font(.subheadline.weight(selectedTab == tab ? .bold : .regular))
                            .foregroundStyle(disabled ? .secondary : selectedTab == tab ? Color.appPrimary : .primary)
                            .lineLimit(1)
                        Rectangle()
                            .frame(height: 2)
                            .foregroundStyle(selectedTab == tab && !disabled ? Color.appPrimary : .clear)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .disabled(disabled)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 학교 미설정 안내

    private var schoolPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("학교를 설정해주세요")
                .font(.headline)
            Text("프로필에서 학교를 입력하면\n우리 학교 친구들이 공유한 덱을 볼 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 콘텐츠

    private var content: some View {
        Group {
            if loading && activeDecks.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if activeDecks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(activeDecks) { deck in
                            CommunityDeckRow(
                                deck: deck,
                                isDownloading: downloadingId == deck.id,
                                justDownloaded: downloadSuccess == deck.id,
                                isAlreadyDownloaded: downloadedSourceIds.contains(deck.id)
                            ) {
                                Task { await download(deck: deck) }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "아직 공유된 덱이 없어요" : "검색 결과가 없어요")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sortMenu: some View {
        Menu {
            Button {
                sortOrder = .latest
            } label: {
                Label("최신 순", systemImage: sortOrder == .latest ? "checkmark" : "clock")
            }
            Button {
                sortOrder = .popular
            } label: {
                Label("인기 순", systemImage: sortOrder == .popular ? "checkmark" : "arrow.down.to.line")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.title3)
        }
    }

    // MARK: - 데이터

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            async let pub = DataService.publicDecks()
            async let myAll = DataService.myDecks()

            if hasSchool, let schoolId = appState.profile?.schoolId {
                async let sch = DataService.schoolDecks(schoolId: schoolId)
                let (publicResult, schoolResult, mine) = try await (pub, sch, myAll)
                generalDecks = publicResult
                schoolDecks  = schoolResult
                downloadedSourceIds = Set(mine.compactMap(\.sourceDeckId))
            } else {
                let (publicResult, mine) = try await (pub, myAll)
                generalDecks = publicResult
                downloadedSourceIds = Set(mine.compactMap(\.sourceDeckId))
            }
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }

    private func download(deck: Deck) async {
        downloadingId = deck.id
        defer { downloadingId = nil }
        do {
            _ = try await DataService.downloadDeck(id: deck.id)
            downloadSuccess = deck.id
            // 로컬 상태만 업데이트해 전체 재조회 방지
            downloadedSourceIds.insert(deck.id)
            if selectedTab == .general, let idx = generalDecks.firstIndex(where: { $0.id == deck.id }) {
                generalDecks[idx].downloadedCount += 1
            } else if let idx = schoolDecks.firstIndex(where: { $0.id == deck.id }) {
                schoolDecks[idx].downloadedCount += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if downloadSuccess == deck.id { downloadSuccess = nil }
            }
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

struct CommunityDeckRow: View {
    let deck: Deck
    let isDownloading: Bool
    let justDownloaded: Bool
    let isAlreadyDownloaded: Bool
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(deck.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text("by \(deck.ownerNickname)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                downloadButton
            }

            HStack(spacing: 6) {
                if !deck.subject.isEmpty { TagChip(text: deck.subject) }
                if !deck.unit.isEmpty { TagChip(text: deck.unit, color: .appPurple) }
            }

            HStack(spacing: 12) {
                Label("카드 \(deck.cardCount)개", systemImage: "rectangle.stack")
                Label("\(deck.downloadedCount)", systemImage: "arrow.down.to.line")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var downloadButton: some View {
        Button(action: onDownload) {
            ZStack {
                if isDownloading {
                    ProgressView().tint(.white)
                } else if justDownloaded || isAlreadyDownloaded {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                } else {
                    Image(systemName: "arrow.down.to.line")
                        .font(.subheadline.weight(.bold))
                }
            }
            .frame(width: 36, height: 36)
            .background(isAlreadyDownloaded ? Color.appGreen.opacity(0.8) : justDownloaded ? Color.appGreen : Color.appPrimary)
            .foregroundStyle(.white)
            .clipShape(Circle())
        }
        .disabled(isDownloading || justDownloaded || isAlreadyDownloaded)
        .animation(.easeInOut(duration: 0.2), value: justDownloaded)
    }
}

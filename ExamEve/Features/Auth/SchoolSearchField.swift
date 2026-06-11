import SwiftUI

// MARK: - SchoolSearchField
// 학교명 입력 → Supabase 실시간 검색 → 드롭다운 선택
// 반드시 목록에서 탭으로 선택해야 school 값이 확정됨

struct SchoolSearchField: View {
    /// 선택된 학교 (nil = 미선택)
    @Binding var selectedSchool: School?
    /// 검색창 placeholder
    var placeholder = "학교 이름 검색"

    @State private var query = ""
    @State private var results: [School] = []
    @State private var searching = false
    @State private var showDropdown = false
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── 입력 필드 ──────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)

                TextField(placeholder, text: $query)
                    .focused($focused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: query) { _, newVal in
                        handleQueryChange(newVal)
                    }

                if searching {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if selectedSchool != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appGreen)
                } else if !query.isEmpty {
                    Button {
                        clear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        focused ? Color.appPrimary : Color.black.opacity(0.08),
                        lineWidth: focused ? 1.5 : 1
                    )
            )

            // ── 드롭다운 ────────────────────────────────
            if showDropdown && !results.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { school in
                            Button {
                                select(school)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(school.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(school.region)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedSchool?.id == school.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.appPrimary)
                                            .font(.caption.weight(.bold))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            if school.id != results.last?.id {
                                Divider().padding(.leading, 14)
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if showDropdown && !query.isEmpty && !searching && results.isEmpty {
                Text("일치하는 학교가 없어요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showDropdown)
        .animation(.easeInOut(duration: 0.18), value: results.count)
        .onAppear {
            if let school = selectedSchool {
                query = school.name
            }
        }
    }

    // MARK: - 로직

    private func handleQueryChange(_ newVal: String) {
        // 직접 입력 시 선택 상태 해제
        if selectedSchool != nil && newVal != selectedSchool?.name {
            selectedSchool = nil
        }
        // 빈 문자열이면 드롭다운 닫기
        guard newVal.trimmingCharacters(in: .whitespaces).count >= 1 else {
            results = []
            showDropdown = false
            return
        }
        showDropdown = true
        scheduleSearch(query: newVal)
    }

    private func scheduleSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            // 타이핑 멈춤을 300ms 기다린 후 검색
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await search(query: query)
        }
    }

    private func search(query q: String) async {
        searching = true
        defer { searching = false }
        do {
            results = try await DataService.searchSchools(query: q)
        } catch {
            results = []
        }
    }

    private func select(_ school: School) {
        selectedSchool = school
        query = school.name
        showDropdown = false
        focused = false
        results = []
    }

    private func clear() {
        query = ""
        selectedSchool = nil
        results = []
        showDropdown = false
    }
}

import SwiftUI

// MARK: - SubjectPickerField

struct SubjectPickerField: View {
    @Binding var selectedSubject: Subject?

    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            HStack(spacing: 10) {
                if let s = selectedSubject {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.name)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text("\(s.category) · \(s.type)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("과목 선택 (선택사항)")
                        .foregroundStyle(Color(.placeholderText))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            SubjectPickerSheet(selectedSubject: $selectedSubject)
        }
    }
}

// MARK: - Sheet (자체 데이터 로딩)

private struct SubjectPickerSheet: View {
    @Binding var selectedSubject: Subject?
    @Environment(\.dismiss) private var dismiss

    @State private var allSubjects: [Subject] = []
    @State private var loading = true

    private static let categoryOrder = [
        "국어", "수학", "영어", "사회(역사·도덕 포함)", "과학",
        "기술·가정", "정보", "제2외국어", "한문", "교양",
    ]

    private var orderedCategories: [String] {
        let present = Set(allSubjects.map(\.category))
        var result = Self.categoryOrder.filter { present.contains($0) }
        let extra = present.subtracting(Self.categoryOrder).sorted()
        result.append(contentsOf: extra)
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("과목 목록 불러오는 중…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(orderedCategories, id: \.self) { category in
                            NavigationLink {
                                SubjectListView(
                                    subjects: allSubjects.filter { $0.category == category },
                                    selectedSubject: $selectedSubject,
                                    onSelect: { dismiss() }
                                )
                            } label: {
                                HStack {
                                    Text(category)
                                    Spacer()
                                    if let sel = selectedSubject, sel.category == category {
                                        Text(sel.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("교과 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                if selectedSubject != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("초기화", role: .destructive) {
                            selectedSubject = nil
                            dismiss()
                        }
                    }
                }
            }
        }
        .task {
            allSubjects = (try? await DataService.fetchAllSubjects()) ?? []
            loading = false
        }
    }
}

// MARK: - 과목 목록

private struct SubjectListView: View {
    let subjects: [Subject]
    @Binding var selectedSubject: Subject?
    let onSelect: () -> Void

    private static let typeOrder = ["공통", "일반선택", "진로선택", "융합선택"]
    private static let typeColors: [String: Color] = [
        "공통":    .appPrimary,
        "일반선택": .appGreen,
        "진로선택": .appOrange,
        "융합선택": .appPurple,
    ]

    private var grouped: [(String, [Subject])] {
        let byType = Dictionary(grouping: subjects) { $0.type }
        return Self.typeOrder.compactMap { type in
            guard let list = byType[type], !list.isEmpty else { return nil }
            return (type, list)
        }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.0) { type, items in
                Section {
                    ForEach(items) { subject in
                        Button {
                            selectedSubject = subject
                            onSelect()
                        } label: {
                            HStack {
                                Text(subject.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedSubject?.id == subject.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                        }
                    }
                } header: {
                    Text(type)
                        .foregroundStyle(Self.typeColors[type] ?? .secondary)
                }
            }
        }
        .navigationTitle(subjects.first?.category ?? "과목 선택")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var sharedDecks: [Deck] = []
    @State private var downloadedDecks: [Deck] = []
    @State private var showProfileEditor = false
    @State private var showSchoolEditor = false
    @State private var showSignOutConfirm = false
    @State private var errorMessage: String?

    private var profile: Profile? { appState.profile }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileCard
                    sharedSection
                    downloadedSection
                    signOutButton
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("프로필")
            .sheet(isPresented: $showProfileEditor) {
                ProfileEditorView { Task { await appState.refreshProfile() } }
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showSchoolEditor) {
                SchoolEditorView { Task { await appState.refreshProfile() } }
                    .presentationDetents([.medium])
            }
            .confirmationDialog("로그아웃할까요?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("로그아웃", role: .destructive) { Task { await appState.signOut() } }
            }
            .alert("오류", isPresented: .constant(errorMessage != nil)) {
                Button("확인") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .task { await loadDecks() }
        }
    }

    // MARK: - 프로필 카드

    private var profileCard: some View {
        VStack(spacing: 16) {
            avatarView(size: 80)

            VStack(spacing: 6) {
                Text(profile?.nickname ?? "")
                    .font(.title3.bold())
                if let school = profile?.school {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                        Text(school.name)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                    Text("학교 미설정")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button { showProfileEditor = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("프로필 수정")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary.opacity(0.1))
                    .foregroundStyle(Color.appPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button { showSchoolEditor = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2")
                        Text("학교 수정")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appTeal.opacity(0.1))
                    .foregroundStyle(Color.appTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(20)
        .cardStyle()
    }

    @ViewBuilder
    func avatarView(size: CGFloat) -> some View {
        if let urlStr = profile?.avatarUrl, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                default: Color(ProfileColor.resolve(profile?.avatarColor))
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(ProfileColor.resolve(profile?.avatarColor))
                .frame(width: size, height: size)
        }
    }

    // MARK: - 공유/다운로드 섹션

    private var sharedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("내가 공유한 덱").font(.headline).padding(.leading, 4)
            if sharedDecks.isEmpty {
                emptyRow("공유한 덱이 없어요.")
            } else {
                ForEach(sharedDecks) { DeckRowView(deck: $0) }
            }
        }
    }

    private var downloadedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("다운로드한 덱").font(.headline).padding(.leading, 4)
            if downloadedDecks.isEmpty {
                emptyRow("다운로드한 덱이 없어요.")
            } else {
                ForEach(downloadedDecks) { DeckRowView(deck: $0) }
            }
        }
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(.subheadline).foregroundStyle(.secondary)
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
    }

    private var signOutButton: some View {
        Button { showSignOutConfirm = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("로그아웃")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.appRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.appRed.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.top, 4)
    }

    private func loadDecks() async {
        guard let uid = DataService.uid else { return }
        do {
            let all = try await DataService.myDecks()
            sharedDecks     = all.filter { $0.isShared && $0.userId == uid }
            downloadedDecks = all.filter { $0.sourceDeckId != nil }
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

// MARK: - 프로필 편집 시트

struct ProfileEditorView: View {
    let onSaved: () -> Void
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // 아바타 모드
    enum AvatarMode { case color, existingPhoto, newPhoto }
    @State private var avatarMode: AvatarMode = .color
    @State private var selectedColorKey: String = ProfileColor.sky.rawValue
    @State private var pendingPhoto: UIImage? = nil
    @State private var photoItem: PhotosPickerItem? = nil

    @State private var nickname = ""
    @State private var busy = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    avatarSection
                    nicknameSection
                    if let errorMessage {
                        Text(errorMessage).font(.caption).foregroundStyle(Color.appRed)
                    }
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(
                    title: "저장",
                    disabled: nickname.trimmingCharacters(in: .whitespaces).isEmpty,
                    busy: busy
                ) { Task { await save() } }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(Color.appBackground)
            }
            .background(Color.appBackground)
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("취소") { dismiss() } }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    guard let item,
                          let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    pendingPhoto = image
                    avatarMode = .newPhoto
                }
            }
            .onAppear { loadInitial() }
        }
    }

    // MARK: - 아바타 섹션

    private var avatarSection: some View {
        VStack(spacing: 20) {
            // 미리보기
            ZStack(alignment: .bottomTrailing) {
                avatarPreview
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(Color(white: 0.2))
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // 색상 팔레트
            VStack(spacing: 10) {
                Text("색상 선택")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    ForEach(ProfileColor.allCases, id: \.rawValue) { pc in
                        colorSwatch(pc)
                    }
                }
            }

            // 사진 삭제 버튼 (사진 모드일 때만)
            if avatarMode == .existingPhoto || avatarMode == .newPhoto {
                Button {
                    pendingPhoto = nil
                    photoItem = nil
                    avatarMode = .color
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.slash")
                        Text("사진 삭제")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.appRed)
                }
            }
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        Group {
            switch avatarMode {
            case .newPhoto:
                if let img = pendingPhoto {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 90, height: 90).clipShape(Circle())
                }
            case .existingPhoto:
                if let urlStr = appState.profile?.avatarUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: Circle().fill(ProfileColor.resolve(selectedColorKey))
                        }
                    }
                    .frame(width: 90, height: 90).clipShape(Circle())
                }
            case .color:
                Circle()
                    .fill(ProfileColor.resolve(selectedColorKey))
                    .frame(width: 90, height: 90)
            }
        }
    }

    private func colorSwatch(_ pc: ProfileColor) -> some View {
        let isSelected = avatarMode == .color && selectedColorKey == pc.rawValue
        return Button {
            selectedColorKey = pc.rawValue
            pendingPhoto = nil
            photoItem = nil
            avatarMode = .color
        } label: {
            ZStack {
                Circle().fill(pc.color).frame(width: 40, height: 40)
                if isSelected {
                    Circle().stroke(Color.primary.opacity(0.4), lineWidth: 2).frame(width: 46, height: 46)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(white: 0.25))
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - 닉네임 섹션

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임").font(.headline)
            RoundedField(placeholder: "닉네임", text: $nickname)
        }
    }

    // MARK: - 초기화 / 저장

    private func loadInitial() {
        nickname = appState.profile?.nickname ?? ""
        selectedColorKey = appState.profile?.avatarColor ?? ProfileColor.sky.rawValue
        avatarMode = appState.profile?.avatarUrl != nil ? .existingPhoto : .color
    }

    private func save() async {
        busy = true; errorMessage = nil; defer { busy = false }
        do {
            try await DataService.updateNickname(nickname.trimmingCharacters(in: .whitespacesAndNewlines))
            switch avatarMode {
            case .color:
                try await DataService.updateAvatarColor(selectedColorKey)
            case .newPhoto:
                if let img = pendingPhoto { try await DataService.uploadAvatar(img) }
            case .existingPhoto:
                break
            }
            onSaved()
            dismiss()
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

// MARK: - 학교 편집 시트

struct SchoolEditorView: View {
    let onSaved: () -> Void
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSchool: School?
    @State private var busy = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("학교 검색").font(.headline)
                    Text("목록에서 선택해야 저장됩니다. 비워두면 학교 정보가 삭제돼요.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                SchoolSearchField(selectedSchool: $selectedSchool, placeholder: "학교 이름으로 검색")
                if let school = selectedSchool {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill").foregroundStyle(Color.appTeal)
                        Text(school.name).font(.subheadline.weight(.semibold))
                        Text("·").foregroundStyle(.secondary)
                        Text(school.region).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button { selectedSchool = nil } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.appTeal.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(Color.appRed)
                }
                Spacer()
                PrimaryButton(title: "저장", busy: busy) { Task { await save() } }
            }
            .padding(20)
            .background(Color.appBackground)
            .navigationTitle("학교 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("취소") { dismiss() } }
            }
            .onAppear { selectedSchool = appState.profile?.school }
        }
    }

    private func save() async {
        busy = true; errorMessage = nil; defer { busy = false }
        do {
            try await DataService.updateSchool(selectedSchool?.id)
            onSaved()
            dismiss()
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var nickname = ""
    @State private var selectedSchool: School?
    @State private var busy = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("거의 다 왔어요!")
                        .font(.largeTitle.bold())
                    Text("친구들에게 보여질 프로필을 만들어주세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                VStack(alignment: .leading, spacing: 8) {
                    Text("닉네임").font(.headline)
                    RoundedField(placeholder: "예: 전교일등", text: $nickname)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("학교 (선택)").font(.headline)
                    SchoolSearchField(selectedSchool: $selectedSchool)
                    Text("학교를 선택하면 우리 학교 친구들이 공유한 덱을 볼 수 있어요. 나중에 프로필에서 바꿀 수 있어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.appRed)
                }

                PrimaryButton(
                    title: "시작하기",
                    disabled: nickname.trimmingCharacters(in: .whitespaces).isEmpty,
                    busy: busy
                ) {
                    Task { await complete() }
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground)
    }

    private func complete() async {
        busy = true
        errorMessage = nil
        defer { busy = false }
        do {
            try await DataService.createProfile(
                nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                schoolId: selectedSchool?.id
            )
            await appState.refreshProfile()
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

import SwiftUI

struct AuthView: View {
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false
    @State private var forgotEmail = ""
    @State private var resetEmailSent = false

    private var submitDisabled: Bool {
        email.trimmingCharacters(in: .whitespaces).isEmpty || password.count < 6
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.appPrimary)
                    Text("시험전야")
                        .font(.system(size: 36, weight: .heavy))
                    Text("시험 전날 밤, 가장 빠른 암기장")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 80)
                .padding(.bottom, 40)

                VStack(spacing: 12) {
                    RoundedField(placeholder: "이메일", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    RoundedField(placeholder: "비밀번호 (6자 이상)", text: $password, secure: true)
                        .textContentType(isSignUp ? .newPassword : .password)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color.appRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PrimaryButton(
                        title: isSignUp ? "회원가입" : "로그인",
                        disabled: submitDisabled,
                        busy: busy
                    ) {
                        Task { await submit() }
                    }
                    .padding(.top, 4)

                    HStack {
                        Button {
                            isSignUp.toggle()
                            errorMessage = nil
                        } label: {
                            Text(isSignUp ? "이미 계정이 있나요? 로그인" : "계정이 없나요? 회원가입")
                                .font(.subheadline.weight(.semibold))
                        }

                        Spacer()

                        if !isSignUp {
                            Button {
                                forgotEmail = email
                                showForgotPassword = true
                            } label: {
                                Text("비밀번호 찾기")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground)
        .alert("비밀번호 재설정", isPresented: $showForgotPassword) {
            TextField("가입 이메일", text: $forgotEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("전송") { Task { await sendReset() } }
            Button("취소", role: .cancel) { }
        } message: {
            Text("가입한 이메일로 비밀번호 재설정 링크를 보내드려요.")
        }
        .alert("이메일 전송됨", isPresented: $resetEmailSent) {
            Button("확인") { }
        } message: {
            Text("\(forgotEmail)로 재설정 링크를 보냈어요. 메일함을 확인해주세요.")
        }
    }

    private func submit() async {
        busy = true
        errorMessage = nil
        defer { busy = false }
        do {
            if isSignUp {
                try await SB.client.auth.signUp(email: email, password: password)
            } else {
                try await SB.client.auth.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }

    private func sendReset() async {
        guard !forgotEmail.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try await SB.client.auth.resetPasswordForEmail(forgotEmail)
            resetEmailSent = true
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }
}

import SwiftUI

@main
struct ExamEveApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .tint(.appPrimary)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.phase {
            case .loading:
                VStack(spacing: 16) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.appPrimary)
                    Text("시험전야").font(.largeTitle.bold())
                    ProgressView()
                }
            case .error(let message):
                VStack(spacing: 16) {
                    Text("문제가 발생했어요").font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("다시 시도") {
                        Task { await appState.refreshProfile() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            case .signedOut:
                AuthView()
            case .needsOnboarding:
                OnboardingView()
            case .ready:
                MainTabView()
            }
        }
        .task { appState.start() }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("학습함", systemImage: "rectangle.stack.fill") }
            CommunityView()
                .tabItem { Label("공유", systemImage: "person.2.fill") }
            CalendarView()
                .tabItem { Label("달력", systemImage: "calendar") }
            ProfileView()
                .tabItem { Label("프로필", systemImage: "person.crop.circle.fill") }
        }
    }
}

import Foundation
import Supabase

@MainActor
final class AppState: ObservableObject {
    enum Phase: Equatable {
        case loading
        case signedOut
        case needsOnboarding
        case ready
        case error(String)
    }

    @Published var phase: Phase = .loading
    @Published var profile: Profile?

    private var authTask: Task<Void, Never>?

    func start() {
        guard authTask == nil else { return }
        authTask = Task {
            for await (event, session) in SB.client.auth.authStateChanges {
                switch event {
                case .initialSession, .signedIn:
                    if session == nil {
                        phase = .signedOut
                    } else if profile == nil {
                        await refreshProfile()
                    }
                case .signedOut:
                    profile = nil
                    phase = .signedOut
                default:
                    break
                }
            }
        }
    }

    func refreshProfile() async {
        guard let uid = DataService.uid else {
            phase = .signedOut
            return
        }
        do {
            if let fetched = try await DataService.fetchProfile(userId: uid) {
                profile = fetched
                phase = .ready
            } else {
                phase = .needsOnboarding
            }
        } catch {
            phase = .error(koreanMessage(for: error))
        }
    }

    func signOut() async {
        try? await SB.client.auth.signOut()
    }
}

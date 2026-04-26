import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var hasSeenOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding") }
    }
    @Published var isAuthenticated: Bool = UserDefaults.standard.bool(forKey: "isAuthenticated") {
        didSet { UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated") }
    }
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var profileSyncWarningMessage: String? = nil
    @Published var showSignUp: Bool = false
    @Published var displayName: String = ""
    @Published var email: String = ""
    
    private var currentNonce: String?
    private var pendingProfileSync: AuthenticatedUserProfile?
    private let authService: AuthServiceProtocol
    private let userRepository: UserRepositoryProtocol

    init(authService: AuthServiceProtocol? = nil, userRepository: UserRepositoryProtocol? = nil) {
        self.authService = authService ?? FirebaseAuthService()
        self.userRepository = userRepository ?? FirebaseUserRepository()
        syncCurrentUser()
        RunLinkerLogger.info("AuthViewModel initialized. hasSeenOnboarding=\(hasSeenOnboarding) isAuthenticated=\(isAuthenticated) currentUser=\(self.authService.currentUser?.id ?? "<nil>")")
    }
    
    func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) {
            hasSeenOnboarding = true
        }
    }
    
    // MARK: - Email/Password Login
    func login(email: String, password: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = String(localized: "auth.error.email_password_required")
            return
        }
        
        isLoading = true
        errorMessage = nil
        RunLinkerLogger.info("Login flow started. email=\(RunLinkerLogger.maskedEmail(trimmedEmail))")
        
        do {
            let user = try await authService.signIn(email: trimmedEmail, password: password)
            let profile = makeAuthenticatedUserProfile(
                from: user,
                authProvider: .email
            )
            await completeAuthenticationAfterProfileSyncAttempt(profile)
        } catch {
            errorMessage = userFacingMessage(for: error)
            isLoading = false
        }
    }
    
    // MARK: - Email/Password Sign Up
    func signUp(name: String, email: String, password: String, confirmPassword: String) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = String(localized: "auth.error.all_fields_required")
            return
        }
        
        guard isValidEmail(trimmedEmail) else {
            errorMessage = String(localized: "auth.error.invalid_email_format")
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = String(localized: "auth.error.password_min_length")
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = String(localized: "auth.error.password_mismatch")
            return
        }
        
        isLoading = true
        errorMessage = nil
        RunLinkerLogger.info("Sign-up flow started. email=\(RunLinkerLogger.maskedEmail(trimmedEmail)) displayName=\(trimmedName)")
        
        do {
            let user = try await authService.createUser(
                email: trimmedEmail,
                password: password,
                displayName: trimmedName
            )
            let profile = makeAuthenticatedUserProfile(
                from: user,
                authProvider: .email,
                displayNameOverride: trimmedName
            )
            await completeAuthenticationAfterProfileSyncAttempt(profile)
        } catch {
            RunLinkerLogger.error("Sign-up flow failed before app entry.", error: error)
            failAuthenticationFlow(with: error)
        }
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        guard let clientID = googleClientID else {
            errorMessage = String(localized: "auth.error.google_config_missing")
            isLoading = false
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        guard let rootViewController = rootViewController else {
            errorMessage = String(localized: "auth.error.google_present_failed")
            isLoading = false
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = String(localized: "auth.error.google_token_missing")
                isLoading = false
                return
            }
            
            let user = try await authService.signInWithGoogle(
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let profile = makeAuthenticatedUserProfile(
                from: user,
                authProvider: .google,
                displayNameOverride: result.user.profile?.name
            )
            await completeAuthenticationAfterProfileSyncAttempt(profile)
        } catch {
            failAuthenticationFlow(with: error)
        }
    }
    
    // MARK: - Apple Sign-In
    func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        errorMessage = nil
        isLoading = true
    }
    
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        Task {
            await finishAppleSignIn(result)
        }
    }
    
    private func finishAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = String(localized: "auth.error.apple_credential_unreadable")
                isLoading = false
                return
            }
            
            guard let nonce = currentNonce else {
                errorMessage = String(localized: "auth.error.apple_nonce_missing")
                isLoading = false
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = String(localized: "auth.error.apple_token_missing")
                isLoading = false
                return
            }
            
            do {
                let user = try await authService.signInWithApple(
                    idToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )
                let fullName = appleIDCredential.fullName
                let appleDisplayName = [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                let profile = makeAuthenticatedUserProfile(
                    from: user,
                    authProvider: .apple,
                    displayNameOverride: appleDisplayName.isEmpty ? nil : appleDisplayName
                )
                await completeAuthenticationAfterProfileSyncAttempt(profile)
            } catch {
                failAuthenticationFlow(with: error)
            }
            
        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                errorMessage = nil
            } else {
                errorMessage = userFacingMessage(for: error)
            }
            isLoading = false
        }
    }
    
    // MARK: - Logout
    func logout() {
        do {
            try authService.signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            isAuthenticated = false
            showSignUp = false
            displayName = ""
            email = ""
            profileSyncWarningMessage = nil
            pendingProfileSync = nil
        }
    }

    func retryProfileSync() async {
        guard let profile = pendingProfileSync else {
            RunLinkerLogger.info("Profile sync retry skipped. No pending profile.")
            profileSyncWarningMessage = nil
            return
        }

        do {
            RunLinkerLogger.info("Profile sync retry started. uid=\(profile.id)")
            try await userRepository.upsertAuthenticatedUser(profile)
            pendingProfileSync = nil
            profileSyncWarningMessage = nil
            RunLinkerLogger.info("Profile sync retry succeeded. uid=\(profile.id)")
        } catch {
            RunLinkerLogger.error("Profile sync retry failed. uid=\(profile.id)", error: error)
            profileSyncWarningMessage = userFacingRepositoryMessage(for: error)
        }
    }

    func syncCurrentUserProfileToFirestore() async {
        guard let user = authService.currentUser else {
            RunLinkerLogger.error("Manual profile sync skipped. Firebase Auth currentUser is nil.")
            profileSyncWarningMessage = String(localized: "auth.error.user_not_found")
            return
        }

        let profile = makeAuthenticatedUserProfile(
            from: user,
            authProvider: .email
        )

        do {
            RunLinkerLogger.info("Manual profile sync started. uid=\(profile.id)")
            try await userRepository.upsertAuthenticatedUser(profile)
            pendingProfileSync = nil
            profileSyncWarningMessage = nil
            RunLinkerLogger.info("Manual profile sync succeeded. uid=\(profile.id)")
        } catch {
            pendingProfileSync = profile
            profileSyncWarningMessage = userFacingRepositoryMessage(for: error)
            RunLinkerLogger.error("Manual profile sync failed. uid=\(profile.id)", error: error)
        }
    }
    
    // MARK: - Restore Previous Sign-In
    func restorePreviousSignIn() {
        syncCurrentUser()
        isAuthenticated = authService.currentUser != nil
    }
    
    private func completeAuthentication() {
        syncCurrentUser()
        withAnimation(.easeInOut(duration: 0.4)) {
            isAuthenticated = true
            showSignUp = false
            isLoading = false
        }
    }

    private func completeAuthenticationAfterProfileSyncAttempt(_ profile: AuthenticatedUserProfile) async {
        do {
            print("🔐 [Auth] Profile sync starting — uid=\(profile.id)")
            RunLinkerLogger.info("Profile sync started after auth success. uid=\(profile.id)")
            try await userRepository.upsertAuthenticatedUser(profile)
            pendingProfileSync = nil
            profileSyncWarningMessage = nil
            print("✅ [Auth] Profile sync succeeded — uid=\(profile.id)")
            RunLinkerLogger.info("Profile sync succeeded after auth success. uid=\(profile.id)")
        } catch {
            print("❌ [Auth] Profile sync FAILED — uid=\(profile.id) error=\(error)")
            print("❌ [Auth] Error details: \(String(describing: error))")
            RunLinkerLogger.error("Profile sync failed after auth success. App entry will continue. uid=\(profile.id)", error: error)
            pendingProfileSync = profile
            profileSyncWarningMessage = userFacingRepositoryMessage(for: error)
        }

        print("🔐 [Auth] Auth flow completed. Entering app. uid=\(profile.id) syncFailed=\(pendingProfileSync != nil)")
        RunLinkerLogger.info("Auth flow completed. App entry allowed. uid=\(profile.id) profileSyncPending=\(pendingProfileSync != nil)")
        completeAuthentication()
    }
    
    private func syncCurrentUser() {
        let user = authService.currentUser
        displayName = user?.displayName ?? ""
        email = user?.email ?? ""
    }
    
    private func failAuthenticationFlow(with error: Error) {
        try? authService.signOut()
        GIDSignIn.sharedInstance.signOut()
        syncCurrentUser()
        errorMessage = userFacingMessage(for: error)
        isLoading = false
        isAuthenticated = false
    }
    
    private func makeAuthenticatedUserProfile(
        from user: AuthServiceUser,
        authProvider: AuthenticationProvider,
        displayNameOverride: String? = nil
    ) -> AuthenticatedUserProfile {
        let resolvedDisplayName = displayNameOverride ?? user.displayName.ifNotEmpty ?? user.email.components(separatedBy: "@").first ?? "Runner"
        return AuthenticatedUserProfile(
            id: user.id,
            authProvider: authProvider,
            email: user.email,
            displayName: resolvedDisplayName,
            photoURL: user.photoURL,
            createdAt: user.createdAt
        )
    }
    
    private var googleClientID: String? {
        if let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty {
            return clientID
        }
        return Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String
    }
    
    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func userFacingMessage(for error: Error) -> String {
        if let authorizationError = error as? ASAuthorizationError {
            switch authorizationError.code {
            case .canceled:
                return String(localized: "auth.error.login_cancelled")
            case .failed:
                return String(localized: "auth.error.apple_failed")
            case .invalidResponse:
                return String(localized: "auth.error.apple_invalid_response")
            case .notHandled:
                return String(localized: "auth.error.apple_not_handled")
            case .notInteractive:
                return String(localized: "auth.error.apple_not_interactive")
            case .matchedExcludedCredential:
                return String(localized: "auth.error.apple_excluded_credential")
            case .credentialImport, .credentialExport:
                return String(localized: "auth.error.apple_credential_processing")
            case .preferSignInWithApple:
                return String(localized: "auth.error.apple_preferred")
            case .deviceNotConfiguredForPasskeyCreation:
                return String(localized: "auth.error.apple_device_not_configured")
            case .unknown:
                return String(localized: "auth.error.apple_unknown")
            @unknown default:
                return String(localized: "auth.error.apple_generic")
            }
        }
        
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain else {
            return userFacingRepositoryMessage(for: error)
        }
        
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return String(localized: "auth.error.invalid_email")
        case AuthErrorCode.wrongPassword.rawValue:
            return String(localized: "auth.error.wrong_password")
        case AuthErrorCode.userNotFound.rawValue:
            return String(localized: "auth.error.user_not_found")
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return String(localized: "auth.error.email_already_in_use")
        case AuthErrorCode.weakPassword.rawValue:
            return String(localized: "auth.error.weak_password")
        case AuthErrorCode.networkError.rawValue:
            return String(localized: "auth.error.network")
        case AuthErrorCode.credentialAlreadyInUse.rawValue:
            return String(localized: "auth.error.credential_already_in_use")
        case AuthErrorCode.accountExistsWithDifferentCredential.rawValue:
            return String(localized: "auth.error.account_exists_different_credential")
        case AuthErrorCode.invalidCredential.rawValue:
            return String(localized: "auth.error.invalid_credential")
        default:
            return error.localizedDescription
        }
    }

    private func userFacingRepositoryMessage(for error: Error) -> String {
        if error is FirestoreWriteTimeoutError {
            return String(localized: "auth.error.firestore_write_timeout")
        }

        let message = error.localizedDescription
        let lowercasedMessage = message.lowercased()

        if lowercasedMessage.contains("database (default) does not exist") {
            return String(localized: "auth.error.firestore_database_missing")
        }

        if lowercasedMessage.contains("missing or insufficient permissions")
            || lowercasedMessage.contains("permission-denied") {
            return String(localized: "auth.error.firestore_permission_denied")
        }

        if lowercasedMessage.contains("app check") {
            return String(localized: "auth.error.app_check_failed")
        }

        return message
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

private extension String {
    var ifNotEmpty: String? {
        isEmpty ? nil : self
    }
}

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
    @Published var showSignUp: Bool = false
    
    private var currentNonce: String?
    
    func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) {
            hasSeenOnboarding = true
        }
    }
    
    // MARK: - Email/Password Login
    func login(email: String, password: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "이메일과 비밀번호를 입력해주세요."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
            withAnimation(.easeInOut(duration: 0.4)) {
                isAuthenticated = true
                isLoading = false
            }
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
            errorMessage = "모든 필드를 입력해주세요."
            return
        }
        
        guard isValidEmail(trimmedEmail) else {
            errorMessage = "올바른 이메일 형식을 입력해주세요."
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "비밀번호는 6자 이상이어야 합니다."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "비밀번호 확인이 일치하지 않습니다."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = trimmedName
            try await changeRequest.commitChanges()
            
            withAnimation(.easeInOut(duration: 0.4)) {
                isAuthenticated = true
                isLoading = false
            }
        } catch {
            errorMessage = userFacingMessage(for: error)
            isLoading = false
        }
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        guard let clientID = googleClientID else {
            errorMessage = "Google 로그인 설정이 누락되었습니다. GoogleService-Info.plist와 URL Scheme를 확인해주세요."
            isLoading = false
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        guard let rootViewController = rootViewController else {
            errorMessage = "Google 로그인 화면을 열 수 없습니다."
            isLoading = false
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google 인증 토큰을 가져올 수 없습니다."
                isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let _ = try await Auth.auth().signIn(with: credential)
            
            withAnimation(.easeInOut(duration: 0.4)) {
                isAuthenticated = true
                isLoading = false
            }
        } catch {
            errorMessage = userFacingMessage(for: error)
            isLoading = false
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
                errorMessage = "Apple 인증 정보를 읽지 못했습니다."
                isLoading = false
                return
            }
            
            guard let nonce = currentNonce else {
                errorMessage = "Apple 로그인 요청 상태가 유실되었습니다. 다시 시도해주세요."
                isLoading = false
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Apple 인증 토큰을 가져오지 못했습니다."
                isLoading = false
                return
            }
            
            do {
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )
                
                let _ = try await Auth.auth().signIn(with: credential)
                
                withAnimation(.easeInOut(duration: 0.4)) {
                    isAuthenticated = true
                    isLoading = false
                }
            } catch {
                errorMessage = userFacingMessage(for: error)
                isLoading = false
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
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            isAuthenticated = false
        }
    }
    
    // MARK: - Restore Previous Sign-In
    func restorePreviousSignIn() {
        isAuthenticated = Auth.auth().currentUser != nil
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
                return "로그인이 취소되었습니다."
            case .failed:
                return "Apple 로그인에 실패했습니다. 잠시 후 다시 시도해주세요."
            case .invalidResponse:
                return "Apple 인증 응답이 올바르지 않습니다."
            case .notHandled:
                return "Apple 로그인 요청을 처리하지 못했습니다."
            case .notInteractive:
                return "현재 상태에서는 Apple 로그인을 진행할 수 없습니다."
            case .matchedExcludedCredential:
                return "이 기기에서 사용할 수 없는 Apple 자격 증명입니다."
            case .credentialImport, .credentialExport:
                return "Apple 자격 증명 처리 중 오류가 발생했습니다."
            case .preferSignInWithApple:
                return "이 계정은 Apple 로그인을 사용하는 것이 권장됩니다."
            case .deviceNotConfiguredForPasskeyCreation:
                return "이 기기에서는 필요한 Apple 인증 설정이 완료되지 않았습니다."
            case .unknown:
                return "Apple 로그인 중 알 수 없는 오류가 발생했습니다."
            @unknown default:
                return "Apple 로그인 중 오류가 발생했습니다."
            }
        }
        
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain else {
            return error.localizedDescription
        }
        
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "이메일 형식이 올바르지 않습니다."
        case AuthErrorCode.wrongPassword.rawValue:
            return "비밀번호가 올바르지 않습니다."
        case AuthErrorCode.userNotFound.rawValue:
            return "가입되지 않은 이메일입니다."
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "이미 가입된 이메일입니다."
        case AuthErrorCode.weakPassword.rawValue:
            return "비밀번호 강도가 너무 약합니다."
        case AuthErrorCode.networkError.rawValue:
            return "네트워크 상태를 확인한 뒤 다시 시도해주세요."
        case AuthErrorCode.credentialAlreadyInUse.rawValue:
            return "이미 다른 계정에 연결된 로그인 수단입니다."
        case AuthErrorCode.accountExistsWithDifferentCredential.rawValue:
            return "동일한 이메일로 다른 로그인 방식이 이미 등록되어 있습니다."
        case AuthErrorCode.invalidCredential.rawValue:
            return "인증 정보가 유효하지 않습니다. 다시 시도해주세요."
        default:
            return error.localizedDescription
        }
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

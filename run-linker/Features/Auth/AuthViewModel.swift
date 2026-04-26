import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn

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
    
    func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) {
            hasSeenOnboarding = true
        }
    }
    
    // MARK: - Email/Password Login
    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "이메일과 비밀번호를 입력해주세요."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await Auth.auth().signIn(withEmail: email, password: password)
            withAnimation(.easeInOut(duration: 0.4)) {
                isAuthenticated = true
                isLoading = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Email/Password Sign Up
    func signUp(name: String, email: String, password: String) async {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "모든 필드를 입력해주세요."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            withAnimation(.easeInOut(duration: 0.4)) {
                isAuthenticated = true
                isLoading = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
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
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Apple Sign-In (placeholder)
    func signInWithApple() {
        // TODO: Implement Apple Sign-In with ASAuthorizationController
        print("Apple Sign-In tapped - implementation pending")
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
        if Auth.auth().currentUser != nil {
            isAuthenticated = true
        }
    }
}

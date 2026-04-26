import SwiftUI
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        #if DEBUG
        Firestore.enableLogging(true)
        #endif
        FirebaseApp.configure()
        if let options = FirebaseApp.app()?.options {
            RunLinkerLogger.info("Firebase configured. projectID=\(options.projectID ?? "<nil>") googleAppID=\(options.googleAppID) bundleID=\(Bundle.main.bundleIdentifier ?? "<nil>")")
        }
        return true
    }
}

@main
struct RunLinkerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authVM = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(authVM)
                .task {
                    authVM.restorePreviousSignIn()
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .overlay(alignment: .top) {
                    if let warning = authVM.profileSyncWarningMessage {
                        ProfileSyncWarningBanner(
                            message: warning,
                            retryAction: { Task { await authVM.retryProfileSync() } },
                            dismissAction: { authVM.profileSyncWarningMessage = nil }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut, value: authVM.profileSyncWarningMessage)
                    }
                }
        }
    }
}

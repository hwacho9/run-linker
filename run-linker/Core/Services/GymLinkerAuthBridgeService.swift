import CryptoKit
import Foundation
import Security

enum IntegrationFeatureFlags {
    static var isGymLinkerIntegrationEnabled: Bool {
        Bundle.main.object(forInfoDictionaryKey: "GymLinkerIntegrationEnabled") as? Bool ?? false
    }
}

struct GymLinkerExchangeProfile: Decodable {
    let uid: String
    let email: String
    let emailVerified: Bool
    let displayName: String
    let photoURL: String
}

struct GymLinkerExchangeResult: Decodable {
    let customToken: String
    let profile: GymLinkerExchangeProfile
}

protocol GymLinkerAuthBridgeServiceProtocol {
    func makeAuthorizationURL() throws -> URL
    func canHandleCallback(_ url: URL) -> Bool
    func exchangeCallback(_ url: URL) async throws -> GymLinkerExchangeResult
}

final class GymLinkerAuthBridgeService: GymLinkerAuthBridgeServiceProtocol {
    private enum Constants {
        static let gymLinkerScheme = "gymlinker"
        static let gymLinkerHost = "runlinker-auth"
        static let gymLinkerPath = "/authorize"
        static let callbackScheme = "runlinker"
        static let callbackHost = "gymlinker-auth"
        static let callbackPath = "/callback"
        static let stateKey = "gymlinkerAuthBridge.pendingState"
        static let stateCreatedAtKey = "gymlinkerAuthBridge.pendingStateCreatedAt"
        static let codeVerifierKey = "gymlinkerAuthBridge.pendingCodeVerifier"
        static let maximumStateAge: TimeInterval = 10 * 60
        static let defaultExchangeURL = "https://asia-northeast1-runlinker-d8b2e.cloudfunctions.net/exchangeGymLinkerAuthorization"
    }

    private struct ErrorResponse: Decodable {
        let error: String
    }

    private let session: URLSession
    private let defaults: UserDefaults

    init(session: URLSession = .shared, defaults: UserDefaults = .standard) {
        self.session = session
        self.defaults = defaults
    }

    func makeAuthorizationURL() throws -> URL {
        let state = try Self.randomBase64URL(byteCount: 32)
        let codeVerifier = try Self.randomBase64URL(byteCount: 32)
        let codeChallenge = Self.pkceChallenge(for: codeVerifier)
        defaults.set(state, forKey: Constants.stateKey)
        defaults.set(Date().timeIntervalSince1970, forKey: Constants.stateCreatedAtKey)
        defaults.set(codeVerifier, forKey: Constants.codeVerifierKey)

        var components = URLComponents()
        components.scheme = Constants.gymLinkerScheme
        components.host = Constants.gymLinkerHost
        components.path = Constants.gymLinkerPath
        components.queryItems = [
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        guard let url = components.url else {
            throw GymLinkerAuthBridgeError.invalidAuthorizationURL
        }
        return url
    }

    func canHandleCallback(_ url: URL) -> Bool {
        url.scheme == Constants.callbackScheme &&
            url.host == Constants.callbackHost &&
            url.path == Constants.callbackPath
    }

    func exchangeCallback(_ url: URL) async throws -> GymLinkerExchangeResult {
        guard canHandleCallback(url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw GymLinkerAuthBridgeError.invalidCallback
        }

        let items = components.queryItems ?? []
        let returnedState = items.first(where: { $0.name == "state" })?.value
        guard let expectedState = defaults.string(forKey: Constants.stateKey),
              let returnedState,
              Self.constantTimeEquals(expectedState, returnedState) else {
            clearPendingState()
            throw GymLinkerAuthBridgeError.stateMismatch
        }

        let createdAt = defaults.double(forKey: Constants.stateCreatedAtKey)
        guard createdAt > 0,
              Date().timeIntervalSince1970 - createdAt <= Constants.maximumStateAge else {
            clearPendingState()
            throw GymLinkerAuthBridgeError.authorizationExpired
        }

        if let errorCode = items.first(where: { $0.name == "error" })?.value {
            clearPendingState()
            throw GymLinkerAuthBridgeError.authorizationRejected(errorCode)
        }

        guard let code = items.first(where: { $0.name == "code" })?.value,
              !code.isEmpty else {
            clearPendingState()
            throw GymLinkerAuthBridgeError.missingAuthorizationCode
        }
        guard let codeVerifier = defaults.string(forKey: Constants.codeVerifierKey) else {
            clearPendingState()
            throw GymLinkerAuthBridgeError.missingCodeVerifier
        }

        let result = try await exchange(code: code, state: returnedState, codeVerifier: codeVerifier)
        clearPendingState()
        return result
    }

    private func exchange(code: String, state: String, codeVerifier: String) async throws -> GymLinkerExchangeResult {
        guard let url = exchangeURL else {
            throw GymLinkerAuthBridgeError.missingExchangeConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code,
            "state": state,
            "codeVerifier": codeVerifier
        ])

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GymLinkerAuthBridgeError.invalidServerResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let serverError = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw GymLinkerAuthBridgeError.exchangeFailed(serverError?.error ?? "http-\(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(GymLinkerExchangeResult.self, from: data)
        } catch {
            throw GymLinkerAuthBridgeError.invalidServerResponse
        }
    }

    private var exchangeURL: URL? {
        let configured = Bundle.main.object(forInfoDictionaryKey: "GymLinkerAuthorizationExchangeURL") as? String
        return URL(string: configured?.isEmpty == false ? configured! : Constants.defaultExchangeURL)
    }

    private func clearPendingState() {
        defaults.removeObject(forKey: Constants.stateKey)
        defaults.removeObject(forKey: Constants.stateCreatedAtKey)
        defaults.removeObject(forKey: Constants.codeVerifierKey)
    }

    private static func randomBase64URL(byteCount: Int) throws -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw GymLinkerAuthBridgeError.randomGenerationFailed
        }
        return Data(bytes).base64URLEncodedString()
    }

    private static func pkceChallenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncodedString()
    }

    private static func constantTimeEquals(_ lhs: String, _ rhs: String) -> Bool {
        let left = Array(lhs.utf8)
        let right = Array(rhs.utf8)
        guard left.count == right.count else { return false }
        return zip(left, right).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}

enum GymLinkerAuthBridgeError: LocalizedError {
    case invalidAuthorizationURL
    case invalidCallback
    case stateMismatch
    case authorizationExpired
    case missingAuthorizationCode
    case missingCodeVerifier
    case randomGenerationFailed
    case missingExchangeConfiguration
    case invalidServerResponse
    case authorizationRejected(String)
    case exchangeFailed(String)

    var errorDescription: String? {
        switch self {
        case .stateMismatch:
            String(localized: "auth.error.gymlinker_state_mismatch")
        case .authorizationExpired:
            String(localized: "auth.error.gymlinker_authorization_expired")
        case .authorizationRejected(let code):
            String.localizedStringWithFormat(
                String(localized: "auth.error.gymlinker_authorization_rejected"),
                code
            )
        case .exchangeFailed(let code):
            String.localizedStringWithFormat(
                String(localized: "auth.error.gymlinker_exchange_failed"),
                code
            )
        case .invalidAuthorizationURL, .invalidCallback, .missingAuthorizationCode,
             .missingCodeVerifier, .randomGenerationFailed,
             .missingExchangeConfiguration, .invalidServerResponse:
            String(localized: "auth.error.gymlinker_generic")
        }
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

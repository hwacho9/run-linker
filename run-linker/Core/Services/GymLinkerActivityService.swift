import FirebaseAuth
import Foundation

struct LinkedFitnessActivity: Decodable, Identifiable {
    struct Summary: Decodable {
        let exerciseCount: Int?
        let setCount: Int?
        let totalVolumeKg: Double?
        let mainPart: String?
    }

    let id: String
    let type: String
    let sourceApp: String
    let startedAt: Date
    let durationSec: Int
    let title: String
    let summary: Summary
    let schemaVersion: Int
}

protocol GymLinkerActivityServiceProtocol {
    func fetchActivities(since: Date, limit: Int) async throws -> [LinkedFitnessActivity]
}

final class GymLinkerActivityService: GymLinkerActivityServiceProtocol {
    private struct Response: Decodable {
        let activities: [LinkedFitnessActivity]
    }

    private struct ErrorResponse: Decodable {
        let error: String
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchActivities(since: Date, limit: Int) async throws -> [LinkedFitnessActivity] {
        guard let user = Auth.auth().currentUser else {
            throw GymLinkerActivityServiceError.unauthenticated
        }
        guard let endpointURL else {
            throw GymLinkerActivityServiceError.missingConfiguration
        }

        let idToken = try await user.getIDToken()
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "since": ISO8601DateFormatter().string(from: since),
            "limit": min(max(limit, 1), 100)
        ])

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GymLinkerActivityServiceError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let serverError = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw GymLinkerActivityServiceError.server(
                serverError?.error ?? "http-\(httpResponse.statusCode)"
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data).activities
    }

    private var endpointURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "GymLinkerActivitiesURL") as? String else {
            return nil
        }
        return URL(string: value)
    }
}

enum GymLinkerActivityServiceError: LocalizedError {
    case unauthenticated
    case missingConfiguration
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            String(localized: "auth.error.user_not_found")
        case .missingConfiguration, .invalidResponse:
            String(localized: "activity.gymlinker.load_failed")
        case .server(let code):
            "\(String(localized: "activity.gymlinker.load_failed")) (\(code))"
        }
    }
}

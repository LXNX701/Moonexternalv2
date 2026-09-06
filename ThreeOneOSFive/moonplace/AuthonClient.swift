import Foundation

enum AuthonClient {
    private static var apiBase: URL {
        URL(string: MoonConfig.authonAPIURL)!
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    struct Response: Decodable {
        let success: Bool
        let message: String?
        let accessToken: String?
        let refreshToken: String?
        let sessionId: String?
        let user: UserInfo?
    }

    struct UserInfo: Decodable {
        let id: String?
        let username: String?
        let email: String?
        let displayName: String?
    }

    enum AuthonError: LocalizedError {
        case notConfigured
        case server(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Configura las credenciales de Authon en MoonConfig"
            case .server(let msg):
                return msg
            }
        }
    }

    static func initialize() async throws -> String {
        guard !MoonConfig.authonPublicKey.isEmpty,
              !MoonConfig.authonSecretKey.isEmpty else {
            throw AuthonError.notConfigured
        }
        return UUID().uuidString
    }

    static func register(username: String, password: String, license: String) async throws -> Response {
        let parameters: [String: Any] = [
            "projectId": MoonConfig.authonAppName,
            "email": username,
            "password": password,
            "displayName": username,
            "license": license
        ]
        return try await post("/v1/auth/signup", parameters: parameters)
    }

    static func login(username: String, password: String) async throws -> Response {
        let parameters: [String: Any] = [
            "projectId": MoonConfig.authonAppName,
            "email": username,
            "password": password
        ]
        return try await post("/v1/auth/signin", parameters: parameters)
    }

    static func logout(sessionId: String) async throws -> Bool {
        let parameters: [String: Any] = ["sessionId": sessionId]
        let response = try await post("/v1/auth/signout", parameters: parameters)
        return response.success
    }

    private static func post(_ path: String, parameters: [String: Any]) async throws -> Response {
        let url = apiBase.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(MoonConfig.authonPublicKey)", forHTTPHeaderField: "Authorization")

        let jsonData = try JSONSerialization.data(withJSONObject: parameters)
        request.httpBody = jsonData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AuthonError.server("Authon HTTP \(statusCode)")
        }

        if let raw = String(data: data, encoding: .utf8) {
            print("📡 Authon raw: \(raw)")
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "sin datos"
            throw AuthonError.server("Respuesta inválida: \(error.localizedDescription) - Raw: \(raw)")
        }
    }
}
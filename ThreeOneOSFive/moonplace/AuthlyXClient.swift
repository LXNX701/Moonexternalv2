import Foundation

enum AuthlyXClient {
    // URL CORRECTA de AuthlyX (versión v2)
    private static var apiBase: URL {
        URL(string: "https://authly.cc/api/v2")!
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    struct Response: Decodable {
        let success: Bool
        let message: String?
        let sessionid: String?
        let info: UserInfo?
    }

    struct UserInfo: Decodable {
        let username: String?
        let ip: String?
        let hwid: String?
        let createdate: String?
        let lastlogin: String?
        let subscriptions: String?
    }

    enum AuthlyXError: LocalizedError {
        case notConfigured
        case server(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Configura las credenciales de AuthlyX en MoonConfig"
            case .server(let msg):
                return msg
            }
        }
    }

    static func initialize() async throws -> String {
        guard !MoonConfig.authlyxAppName.isEmpty,
              !MoonConfig.authlyxOwnerId.isEmpty,
              !MoonConfig.authlyxSecret.isEmpty else {
            throw AuthlyXError.notConfigured
        }

        let response = try await post([
            "type": "init",
            "name": MoonConfig.authlyxAppName,
            "ownerid": MoonConfig.authlyxOwnerId,
            "secret": MoonConfig.authlyxSecret,
            "ver": MoonConfig.authlyxVersion
        ])

        guard response.success, let sessionID = response.sessionid else {
            throw AuthlyXError.server(response.message ?? "No se pudo inicializar la sesión")
        }
        return sessionID
    }

    static func register(
        sessionID: String,
        username: String,
        password: String,
        license: String
    ) async throws -> Response {
        try await post([
            "type": "register",
            "name": MoonConfig.authlyxAppName,
            "ownerid": MoonConfig.authlyxOwnerId,
            "ver": MoonConfig.authlyxVersion,
            "sessionid": sessionID,
            "username": username,
            "pass": password,
            "key": license
        ])
    }

    static func login(
        sessionID: String,
        username: String,
        password: String
    ) async throws -> Response {
        try await post([
            "type": "login",
            "name": MoonConfig.authlyxAppName,
            "ownerid": MoonConfig.authlyxOwnerId,
            "ver": MoonConfig.authlyxVersion,
            "sessionid": sessionID,
            "username": username,
            "pass": password
        ])
    }

    static func logout(sessionID: String) async throws -> Bool {
        let response = try await post([
            "type": "logout",
            "sessionid": sessionID
        ])
        return response.success
    }

    private static func post(_ parameters: [String: String]) async throws -> Response {
        print("🌐 Conectando a AuthlyX: \(apiBase.absoluteString)")

        var request = URLRequest(url: apiBase)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = parameters
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AuthlyXError.server("AuthlyX HTTP \(statusCode)")
        }

        if let raw = String(data: data, encoding: .utf8) {
            print("📡 AuthlyX raw: \(raw)")
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "sin datos"
            throw AuthlyXError.server("Respuesta inválida: \(error.localizedDescription) - Raw: \(raw)")
        }
    }
}

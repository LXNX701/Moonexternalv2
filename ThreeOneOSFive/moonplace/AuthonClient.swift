import Foundation

/// Cliente para la API de Authon.cc adaptado a username + license
enum AuthonClient {
    private static var apiBase: URL {
        URL(string: MoonConfig.authonAPIURL)!
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    // MARK: - Estructuras de respuesta

    struct Response: Decodable {
        let success: Bool
        let message: String?
        let accessToken: String?
        let refreshToken: String?
        let expiresIn: Int?
        let sessionId: String?
        let user: UserInfo?
    }

    struct UserInfo: Decodable {
        let id: String?
        let username: String?
        let email: String?
        let displayName: String?
        let createdAt: String?
    }

    enum AuthonError: LocalizedError {
        case notConfigured
        case invalidResponse
        case server(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Configura las credenciales de Authon en MoonConfig"
            case .invalidResponse:
                return "Respuesta inválida de Authon"
            case .server(let msg):
                return msg
            }
        }
    }

    // MARK: - Inicialización (obtener sessionId)

    static func initialize() async throws -> String {
        guard !MoonConfig.authonPublicKey.isEmpty,
              !MoonConfig.authonSecretKey.isEmpty else {
            throw AuthonError.notConfigured
        }

        // Authon no tiene un endpoint init explícito, usamos un ping o simplemente devolvemos un sessionId temporal
        // En su lugar, podemos obtener un sessionId del login/register.
        // Como necesitamos un sessionId para las llamadas, usamos el accessToken como sessionId.
        // O podemos generar un UUID y usarlo como sessionId local.
        // Para simplificar, usamos un UUID que se regenera en cada inicialización.
        return UUID().uuidString
    }

    // MARK: - Registro con username + license

    static func register(
        username: String,
        password: String,
        license: String
    ) async throws -> Response {
        // Endpoint: /v1/auth/signup
        // Usamos email = username (Authon puede aceptar email o username)
        // Enviamos la license como un campo adicional (si Authon lo permite)
        let parameters: [String: Any] = [
            "projectId": MoonConfig.authonAppName,
            "email": username,  // Usamos username como email (Authon puede aceptar username)
            "password": password,
            "displayName": username,
            "license": license  // Campo extra para la key
        ]

        return try await post("/v1/auth/signup", parameters: parameters)
    }

    // MARK: - Login con username + password

    static func login(
        username: String,
        password: String
    ) async throws -> Response {
        let parameters: [String: Any] = [
            "projectId": MoonConfig.authonAppName,
            "email": username,  // Usamos username como email
            "password": password
        ]
        return try await post("/v1/auth/signin", parameters: parameters)
    }

    // MARK: - Refresh token (opcional)

    static func refreshToken(refreshToken: String) async throws -> Response {
        let parameters: [String: Any] = [
            "refreshToken": refreshToken
        ]
        return try await post("/v1/auth/token/refresh", parameters: parameters)
    }

    // MARK: - Logout

    static func logout(sessionId: String) async throws -> Bool {
        let parameters: [String: Any] = [
            "sessionId": sessionId
        ]
        let response = try await post("/v1/auth/signout", parameters: parameters)
        return response.success
    }

    // MARK: - Petición HTTP genérica

    private static func post(_ path: String, parameters: [String: Any]) async throws -> Response {
        let url = apiBase.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Autorización usando public key (para client)
        request.setValue("Bearer \(MoonConfig.authonPublicKey)", forHTTPHeaderField: "Authorization")

        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        request.httpBody = jsonData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AuthonError.server("Authon HTTP \(statusCode)")
        }

        // Depuración: imprimir la respuesta cruda
        if let raw = String(data: data, encoding: .utf8) {
            print("📡 Authon raw response: \(raw)")
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "sin datos"
            throw AuthonError.server("Respuesta inválida: \(error.localizedDescription) - Raw: \(raw)")
        }
    }
}
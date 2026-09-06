import SwiftUI
import Combine

class MoonAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var username: String?
    @Published var justWelcomed = false

    private var sessionID: String?
    private let keychainService = "MoonAuth"

    init() {
        autoLogin()
    }

    func autoLogin() {
        guard let storedUsername = KeychainHelper.get(service: keychainService, account: "username"),
              let storedPassword = KeychainHelper.get(service: keychainService, account: "password") else {
            return
        }

        Task {
            do {
                _ = try await AuthonClient.initialize()
                let response = try await AuthonClient.login(username: storedUsername, password: storedPassword)
                if response.success, let accessToken = response.accessToken {
                    // Guardar tokens si es necesario
                    self.sessionID = accessToken
                    await MainActor.run {
                        self.username = storedUsername
                        self.isAuthenticated = true
                        self.justWelcomed = true
                    }
                } else {
                    throw AuthonClient.AuthonError.server(response.message ?? "Auto-login failed")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func submit(username: String, password: String, license: String?, isRegister: Bool) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await AuthonClient.initialize()

                let response: AuthonClient.Response
                if isRegister {
                    guard let license = license, !license.isEmpty else {
                        throw AuthonClient.AuthonError.server("License key requerida para registro")
                    }
                    response = try await AuthonClient.register(
                        username: username,
                        password: password,
                        license: license
                    )
                } else {
                    response = try await AuthonClient.login(
                        username: username,
                        password: password
                    )
                }

                guard response.success else {
                    throw AuthonClient.AuthonError.server(response.message ?? "Error desconocido")
                }

                // Guardar credenciales en Keychain (usuario y contraseña)
                KeychainHelper.save(service: keychainService, account: "username", value: username)
                KeychainHelper.save(service: keychainService, account: "password", value: password)

                // Guardar tokens si los hay
                if let accessToken = response.accessToken {
                    KeychainHelper.save(service: keychainService, account: "accessToken", value: accessToken)
                }
                if let refreshToken = response.refreshToken {
                    KeychainHelper.save(service: keychainService, account: "refreshToken", value: refreshToken)
                }

                await MainActor.run {
                    self.username = username
                    self.isLoading = false
                    self.isAuthenticated = true
                    self.justWelcomed = true
                }

            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func logout() {
        // Opcional: llamar a logout de Authon
        Task {
            if let sessionId = sessionID {
                _ = try? await AuthonClient.logout(sessionId: sessionId)
            }
        }
        // Limpiar Keychain
        KeychainHelper.delete(service: keychainService, account: "username")
        KeychainHelper.delete(service: keychainService, account: "password")
        KeychainHelper.delete(service: keychainService, account: "accessToken")
        KeychainHelper.delete(service: keychainService, account: "refreshToken")
        isAuthenticated = false
        sessionID = nil
        username = nil
        justWelcomed = false
    }
}
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
                let session = try await AuthlyXClient.initialize()
                self.sessionID = session
                let response = try await AuthlyXClient.login(sessionID: session, username: storedUsername, password: storedPassword)
                if response.success {
                    await MainActor.run {
                        self.username = storedUsername
                        self.isAuthenticated = true
                        self.justWelcomed = true
                    }
                } else {
                    throw AuthlyXClient.AuthlyXError.server(response.message ?? "Auto-login failed")
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
                let session = try await AuthlyXClient.initialize()
                self.sessionID = session

                let response: AuthlyXClient.Response
                if isRegister {
                    guard let license = license, !license.isEmpty else {
                        throw AuthlyXClient.AuthlyXError.server("License key requerida para registro")
                    }
                    response = try await AuthlyXClient.register(
                        sessionID: session,
                        username: username,
                        password: password,
                        license: license
                    )
                } else {
                    response = try await AuthlyXClient.login(
                        sessionID: session,
                        username: username,
                        password: password
                    )
                }

                guard response.success else {
                    throw AuthlyXClient.AuthlyXError.server(response.message ?? "Error desconocido")
                }

                // Guardar credenciales en Keychain
                KeychainHelper.save(service: keychainService, account: "username", value: username)
                KeychainHelper.save(service: keychainService, account: "password", value: password)

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
        Task {
            if let sessionId = sessionID {
                _ = try? await AuthlyXClient.logout(sessionID: sessionId)
            }
        }
        KeychainHelper.delete(service: keychainService, account: "username")
        KeychainHelper.delete(service: keychainService, account: "password")
        isAuthenticated = false
        sessionID = nil
        username = nil
        justWelcomed = false
    }
}
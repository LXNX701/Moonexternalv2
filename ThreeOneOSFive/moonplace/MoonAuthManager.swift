import SwiftUI
import Combine

// Importar el SDK de AuthlyX
import AuthlyX

class MoonAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var username: String?
    @Published var justWelcomed = false

    private let keychainService = "MoonAuth"
    private let authlyX: AuthlyX

    init() {
        // Inicializar con tus credenciales de AuthlyX
        authlyX = AuthlyX(
            ownerId: "530bfb579331",
            appName: "Moonexternal",
            version: "1.0.0",
            secret: "AoSZF4szatA7uxPgVIqdQoyu7ISgaAqkxHjZNdX2"
        )
        // Opcional: desactivar logs en producción
        // authlyX.debug = false
        autoLogin()
    }

    func autoLogin() {
        guard let storedUsername = KeychainHelper.get(service: keychainService, account: "username"),
              let storedPassword = KeychainHelper.get(service: keychainService, account: "password") else {
            return
        }

        Task {
            do {
                let response = try await authlyX.login(username: storedUsername, password: storedPassword)
                if response.success {
                    await MainActor.run {
                        self.username = storedUsername
                        self.isAuthenticated = true
                        self.justWelcomed = true
                    }
                } else {
                    throw NSError(domain: "AuthlyX", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "Auto-login failed"])
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
                let response: AuthlyX.Response
                if isRegister {
                    guard let license = license, !license.isEmpty else {
                        throw NSError(domain: "AuthlyX", code: -1, userInfo: [NSLocalizedDescriptionKey: "License key requerida para registro"])
                    }
                    response = try await authlyX.register(username: username, password: password, license: license)
                } else {
                    response = try await authlyX.login(username: username, password: password)
                }

                guard response.success else {
                    throw NSError(domain: "AuthlyX", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "Error desconocido"])
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
            _ = try? await authlyX.logout()
        }
        KeychainHelper.delete(service: keychainService, account: "username")
        KeychainHelper.delete(service: keychainService, account: "password")
        isAuthenticated = false
        username = nil
        justWelcomed = false
    }
}
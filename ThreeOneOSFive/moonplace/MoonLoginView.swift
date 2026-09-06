import SwiftUI

struct MoonLoginView: View {
    @ObservedObject var auth: MoonAuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var license = ""
    @State private var isRegister = false

    var body: some View {
        ZStack {
            MoonParticleBackground()
                .overlay(
                    LinearGradient.moonBackgroundGradient.opacity(0.4)
                )

            VStack(spacing: 24) {
                // Logo y título
                VStack(spacing: 8) {
                    Image("MoonLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(color: .moonGlow, radius: 20)

                    Text("MOONZAZA")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(LinearGradient.moonGradient)
                    + Text(" x ")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)
                    + Text("Cheat")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.moonSecondary)

                    Text(isRegister ? "Create your account" : "Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Tarjeta de login
                VStack(spacing: 16) {
                    // Picker Login/Register
                    Picker("", selection: $isRegister) {
                        Text("Login").tag(false)
                        Text("Register").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .tint(.moonPrimary)

                    // Campos
                    MoonTextField(icon: "person", placeholder: "Username", text: $username)
                    MoonTextField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)

                    if isRegister {
                        MoonTextField(icon: "key", placeholder: "License Key", text: $license)
                    }

                    // Mensaje de error
                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.moonSecondary)
                            .multilineTextAlignment(.center)
                            .padding(8)
                            .background(Color.moonSecondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Botón
                    Button {
                        auth.submit(
                            username: username,
                            password: password,
                            license: isRegister ? license : nil,
                            isRegister: isRegister
                        )
                    } label: {
                        HStack {
                            if auth.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(auth.isLoading ? "Loading..." : (isRegister ? "Create Account" : "Sign In"))
                                .font(.headline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(MoonButtonStyle())
                    .disabled(auth.isLoading || username.isEmpty || password.isEmpty)
                    .opacity((auth.isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1)
                }
                .padding(24)
                .background(
                    Color.moonCard.opacity(0.8)
                        .background(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.moonBorder, lineWidth: 1)
                )
                .shadow(color: .moonGlow, radius: 20)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 40)
        }
        .preferredColorScheme(.dark)
    }
}

struct MoonTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding(14)
        .background(Color.moonBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.moonBorder, lineWidth: 0.5)
        )
    }
}
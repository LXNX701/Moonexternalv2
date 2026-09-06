import SwiftUI

struct MoonParticleBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.moonBackground, Color.moonPrimary.opacity(0.6)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay(
            // Puedes agregar partículas simples con Canvas si quieres, pero por ahora es un gradiente
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.1))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
}
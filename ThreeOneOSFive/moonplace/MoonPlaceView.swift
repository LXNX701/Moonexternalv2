import SwiftUI
import UniformTypeIdentifiers

struct MoonPlaceView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var auth: MoonAuthManager

    @StateObject private var store = PatchProjectStore()
    @State private var section: MoonSection = .moonV2
    @State private var showWelcomeBadge = true

    enum MoonSection: String, CaseIterable, Identifiable {
        case moonV1 = "🌙 MoonV1"
        case moonV2 = "⚡ MoonV2"
        var id: String { rawValue }
    }

    static let bundledMoonV2Patches: [(resource: String, name: String)] = [
        ("MOON_FFTH_ANTENA_0", "FFTH - Antena 1"),
        ("MOON_FFTH_ANTENA_1", "FFTH - Antena 2"),
        ("MOON_FFTH_ANTENA_2", "FFTH - Antena 3"),
        ("MOON_FFTH_ANTENA_3", "FFTH - Antena 4"),
        ("MOON_FFTH_SIN_ANTENA_0", "FFTH - Sin antena 1"),
        ("MOON_FFTH_SIN_ANTENA_1", "FFTH - Sin antena 2"),
        ("MOON_FFTH_SIN_ANTENA_2", "FFTH - Sin antena 3"),
        ("MOON_FFTH_SIN_ANTENA_3", "FFTH - Sin antena 4"),
        ("MOON_FFMAX_ANTENA_0", "FFMAX - Antena 1"),
        ("MOON_FFMAX_ANTENA_1", "FFMAX - Antena 2"),
        ("MOON_FFMAX_ANTENA_2", "FFMAX - Antena 3"),
        ("MOON_FFMAX_ANTENA_3", "FFMAX - Antena 4"),
        ("MOON_FFMAX_SIN_ANTENA_0", "FFMAX - Sin antena 1"),
        ("MOON_FFMAX_SIN_ANTENA_1", "FFMAX - Sin antena 2"),
        ("MOON_FFMAX_SIN_ANTENA_2", "FFMAX - Sin antena 3"),
        ("MOON_FFMAX_SIN_ANTENA_3", "FFMAX - Sin antena 4"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MoonParticleBackground()
                    .overlay(
                        LinearGradient.moonBackgroundGradient.opacity(0.3)
                    )

                VStack(spacing: 0) {
                    ExploitStatusHeader(appState: appState)

                    Divider()
                        .background(Color.moonPrimary.opacity(0.3))

                    Picker("", selection: $section) {
                        ForEach(MoonSection.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .colorMultiply(.white)
                    .tint(.moonPrimary)

                    ScrollView {
                        switch section {
                        case .moonV1:
                            MoonV1Section(store: store)
                        case .moonV2:
                            MoonV2Section(store: store)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image("MoonLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 28)
                            .clipShape(Circle())

                        // Título con gradiente usando overlay (compatible iOS 16)
                        Text("MOONZAZA")
                            .font(.headline.weight(.bold))
                            .moonGradientText()
                        + Text(" x ")
                            .font(.headline)
                            .foregroundColor(.white)
                        + Text("Cheat")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.moonSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showWelcomeBadge = true
                        } label: {
                            Label("Welcome message", systemImage: "sparkles")
                        }
                        Divider()
                        Button(role: .destructive) {
                            auth.logout()
                        } label: {
                            Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.moonSecondary)
                        }
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundColor(.moonPrimary)
                    }
                }
            }
            .overlay(alignment: .top) {
                if showWelcomeBadge, let user = auth.username {
                    welcomeBadge(user)
                        .padding(.top, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .alert(item: $store.alert) { alert in
                Alert(
                    title: Text(alert.titleKey == "common.done" ? "✅ Done" : "❌ Failed")
                        .foregroundColor(alert.titleKey == "common.done" ? .green : .moonSecondary),
                    message: Text(alert.message(language: .english)),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                appState.detectSupport()
                if auth.justWelcomed {
                    auth.justWelcomed = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showWelcomeBadge = false }
                    }
                } else {
                    showWelcomeBadge = false
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(.moonPrimary)
    }

    private func welcomeBadge(_ user: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.stars.fill")
                .foregroundColor(.moonPrimary)
            Text("Welcome to MOONZAZA, \(user)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            Image(systemName: "sparkles")
                .foregroundColor(.moonSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.moonBorder, lineWidth: 1)
                )
        )
        .shadow(color: .moonGlow, radius: 10)
    }
}

// MARK: - Subviews (con colores compatibles)

private struct ExploitStatusHeader: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.4), lineWidth: 3)
                        .scaleEffect(appState.kernelExploitRunning ? 1.5 : 1)
                        .opacity(appState.kernelExploitRunning ? 1 : 0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: appState.kernelExploitRunning)
                )

            Text(statusLabel)
                .font(.caption.weight(.semibold))
                .foregroundColor(statusColor)

            Spacer()

            if !appState.exploitStatus.isSuccess && !appState.kernelExploitRunning {
                Button("🔓 Activate") {
                    appState.runKernelExploitIfNeeded()
                }
                .font(.caption.weight(.bold))
                .buttonStyle(MoonButtonStyle())
                .controlSize(.small)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            Color.moonCard.opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.moonBorder, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var statusColor: Color {
        if appState.kernelExploitRunning { return .yellow }
        if appState.exploitStatus.isSuccess { return .green }
        if case .failed = appState.exploitStatus { return .moonSecondary }
        return .gray
    }

    private var statusLabel: String {
        if appState.kernelExploitRunning { return "Activating full access..." }
        if appState.exploitStatus.isSuccess { return "✅ Full access active" }
        if case .failed = appState.exploitStatus { return "❌ Activation failed" }
        if case .unsupported(let reason) = appState.exploitStatus { return "⚠️ Not supported on \(reason)" }
        return "🔓 Tap Activate before applying patches"
    }
}

// MARK: - MoonV1 Section (sin cambios adicionales)

private struct MoonV1Section: View {
    @ObservedObject var store: PatchProjectStore
    @State private var showImporter = false

    var body: some View {
        VStack {
            if store.items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "moonphase.new.moon")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(.moonPrimary)

                    Text("🌙 MoonV1")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)

                    Text("Import your own .3105 patches created with 3105.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button {
                        showImporter = true
                    } label: {
                        Label("Import Patch", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(MoonButtonStyle())
                    .disabled(store.isBusy)
                }
                .padding(40)
                .moonCard()
                .padding(.horizontal, 20)
                .padding(.top, 20)
            } else {
                List {
                    ForEach(store.items) { item in
                        MoonPatchRow(item: item, store: store)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
        .refreshable { store.reload() }
        .sheet(isPresented: $showImporter) {
            FileDocumentPicker(
                allowedContentTypes: [UTType(filenameExtension: "3105") ?? .data, .data],
                copiesSelectedDocument: true,
                allowsMultipleSelection: false,
                onSelection: { result in
                    showImporter = false
                    if case .success(let urls) = result, let url = urls.first {
                        store.importPackage(at: url)
                    }
                },
                onCancel: { showImporter = false }
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - MoonV2 Section (sin cambios adicionales)

private struct MoonV2Section: View {
    @ObservedObject var store: PatchProjectStore
    @State private var family = "FFTH"
    @State private var antenna = "ANTENA"

    @AppStorage("moon.v2.installedPatches") private var installedPatchesRaw = ""

    private var installedSet: Set<String> {
        Set(installedPatchesRaw.split(separator: "\n").map(String.init))
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Picker("Familia", selection: $family) {
                    Text("FFTH").tag("FFTH")
                    Text("FFMAX").tag("FFMAX")
                }
                .pickerStyle(.segmented)
                .colorMultiply(.white)
                .tint(.moonPrimary)

                Picker("Antena", selection: $antenna) {
                    Text("Con antena").tag("ANTENA")
                    Text("Sin antena").tag("SIN_ANTENA")
                }
                .pickerStyle(.segmented)
                .colorMultiply(.white)
                .tint(.moonPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            List {
                ForEach(filteredEntries, id: \.resource) { entry in
                    bundledRow(entry)
                        .listRowBackground(Color.moonCard.opacity(0.5))
                }

                if !store.items.isEmpty {
                    Section("📦 Installed Patches") {
                        ForEach(store.items) { item in
                            MoonPatchRow(item: item, store: store)
                                .listRowBackground(Color.moonCard.opacity(0.5))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .refreshable { store.reload() }
    }

    private var filteredEntries: [(resource: String, name: String)] {
        MoonPlaceView.bundledMoonV2Patches.filter { entry in
            entry.resource.contains("_\(family)_") && entry.resource.contains("_\(antenna)_")
        }
    }

    @ViewBuilder
    private func bundledRow(_ entry: (resource: String, name: String)) -> some View {
        let isInstalled = installedSet.contains(entry.resource)

        HStack(spacing: 14) {
            Image(systemName: isInstalled ? "checkmark.circle.fill" : "shippingbox.fill")
                .font(.title3)
                .frame(width: 30)
                .foregroundColor(isInstalled ? .green : .moonPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                Text(isInstalled ? "✅ Installed" : "📥 Ready to install")
                    .font(.caption)
                    .foregroundColor(isInstalled ? .green : .gray)
            }

            Spacer()

            if store.isBusy {
                ProgressView()
                    .tint(.moonPrimary)
            } else if !isInstalled {
                Button("Install") {
                    install(entry)
                }
                .buttonStyle(MoonButtonStyle())
                .controlSize(.small)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding(.vertical, 6)
    }

    private func install(_ entry: (resource: String, name: String)) {
        guard let url = Bundle.main.url(
            forResource: entry.resource,
            withExtension: "3105"
        ) else {
            store.alert = PatchStoreAlert(
                titleKey: "common.failed",
                messageKey: "patch.error.unsupported_format"
            )
            return
        }
        markInstalled(entry.resource)
        store.importPackage(at: url)
    }

    private func markInstalled(_ resource: String) {
        var set = installedSet
        set.insert(resource)
        installedPatchesRaw = set.joined(separator: "\n")
    }
}

// MARK: - MoonPatchRow (sin cambios adicionales)

private struct MoonPatchRow: View {
    let item: PatchLibraryItem
    @ObservedObject var store: PatchProjectStore

    @State private var isWorking = false
    @State private var showApplyConfirm = false
    @State private var showRestoreConfirm = false
    @State private var resultAlert: PatchStoreAlert?

    private var receipt: PatchTransactionReceipt? {
        DevicePatchService.latestReceipt(projectID: item.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: item.isLocked ? "lock.doc.fill" : "doc.fill")
                    .font(.title3)
                    .frame(width: 30)
                    .foregroundColor(item.isLocked ? .gray : .moonPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.project?.name ?? "Locked patch")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)

                    if !item.isLocked {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(receipt != nil ? Color.green : Color.gray)
                                .frame(width: 6, height: 6)
                            Text(receipt != nil ? "Applied" : "Not applied")
                                .font(.caption)
                                .foregroundColor(receipt != nil ? .green : .gray)
                        }
                    }
                }

                Spacer()

                if isWorking {
                    ProgressView()
                        .tint(.moonPrimary)
                }
            }

            if item.isLocked {
                Text("🔒 Password protected. Unlock from the original 3105 Patches section.")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.leading, 44)
            } else {
                HStack(spacing: 12) {
                    Button {
                        showApplyConfirm = true
                    } label: {
                        Label("Apply", systemImage: "checkmark.shield.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MoonButtonStyle())
                    .disabled(isWorking || store.isBusy)

                    Button(role: .destructive) {
                        showRestoreConfirm = true
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .disabled(isWorking || store.isBusy || receipt == nil)
                }
                .controlSize(.small)
                .padding(.leading, 44)
            }
        }
        .padding(.vertical, 8)
        .confirmationDialog(
            "Apply this patch?",
            isPresented: $showApplyConfirm,
            titleVisibility: .visible
        ) {
            Button("Apply", action: apply)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Original files will be backed up automatically.")
        }
        .confirmationDialog(
            "Restore original files?",
            isPresented: $showRestoreConfirm,
            titleVisibility: .visible
        ) {
            Button("Restore Originals", role: .destructive, action: restore)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This undoes the patch and restores original files.")
        }
        .alert(item: $resultAlert) { alert in
            Alert(
                title: Text(alert.titleKey == "common.done" ? "✅ Done" : "❌ Failed")
                    .foregroundColor(alert.titleKey == "common.done" ? .green : .moonSecondary),
                message: Text(alert.message(language: .english)),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func apply() {
        guard let baseProject = item.project else { return }
        isWorking = true
        Task.detached(priority: .userInitiated) {
            do {
                let project = item.summary.schemaVersion >= 2
                    ? try PatchProjectLibrary.synchronizeWorkspace(item: item)
                    : baseProject
                _ = try DevicePatchService.apply(project: project)
                await MainActor.run {
                    store.reload()
                    isWorking = false
                    resultAlert = PatchStoreAlert(
                        titleKey: "common.done",
                        messageKey: "patch.applied_message"
                    )
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    isWorking = false
                    resultAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: error.localizationKey,
                        messageArgument: error.localizationArgument
                    )
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    resultAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: "patch.error.apply"
                    )
                }
            }
        }
    }

    private func restore() {
        guard let receipt else { return }
        isWorking = true
        Task.detached(priority: .userInitiated) {
            do {
                try DevicePatchService.restore(receipt: receipt)
                await MainActor.run {
                    store.reload()
                    isWorking = false
                    resultAlert = PatchStoreAlert(
                        titleKey: "common.done",
                        messageKey: "patch.restored_message"
                    )
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    isWorking = false
                    resultAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: error.localizationKey,
                        messageArgument: error.localizationArgument
                    )
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    resultAlert = PatchStoreAlert(
                        titleKey: "common.failed",
                        messageKey: "patch.error.restore"
                    )
                }
            }
        }
    }
}
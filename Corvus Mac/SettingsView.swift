//
//  SettingsView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var projectPathInput: String = ""
    @State private var pythonPathInput: String = ""
    @State private var saveStatus: String? = nil
    @State private var showChangelog: Bool = false
    
    var isSubmoduleActive: Bool {
        manager.corvusProjectPath.contains("CorvusEngine")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ayarlar ve Entegrasyonlar")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Görünüm teması, kullanıcı profili, çekirdek deposu, dosya yolları ve güncelleme merkezi")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // MARK: - Dark Mode Theme Selection Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Görünüm ve Tema (Dark Mode)")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Stüdyo için optimize edilmiş karanlık mod renk paletini belirleyin")
                                .font(.caption)
                                .foregroundColor(AppTheme.textMuted)
                        }
                        Spacer()
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(AppThemeMode.allCases) { mode in
                            themeSelectionCard(mode)
                        }
                    }
                }
                .corvusCard(padding: 20, radius: 16)
                
                // MARK: - Active User Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Aktif Kullanıcı Profili")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 16) {
                        userSelectionCard(.ufuk)
                        userSelectionCard(.yigit)
                    }
                    
                    Text("💡 Profil seçimi bildirim rotalarını, sohbet renginizi ve takvim güncellemelerini belirler.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textMuted)
                }
                .corvusCard(padding: 20, radius: 16)
                
                updateHubCard
                
                // MARK: - Render Cache Cleaner Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Render & Önbellek Yönetimi")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Masaüstü render çıktıları ve After Effects disk önbelleklerini temizleyin")
                                .font(.caption)
                                .foregroundColor(AppTheme.textMuted)
                        }
                        Spacer()
                        if manager.renderCacheTotalSizeBytes > 0 {
                            Text(ByteCountFormatter.string(fromByteCount: manager.renderCacheTotalSizeBytes, countStyle: .file))
                                .font(.subheadline.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.accentRose.opacity(0.18))
                                .foregroundColor(AppTheme.accentRose)
                                .clipShape(Capsule())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hedef Render Klasörü")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        HStack {
                            TextField("Klasör Yolu", text: $manager.renderCacheFolderPath)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Gözat...") {
                                chooseRenderCacheFolder()
                            }
                        }
                    }
                    
                    HStack {
                        if let s = manager.lastCleanedStatus {
                            Text(s)
                                .font(.caption.weight(.medium))
                                .foregroundColor(AppTheme.accentGreen)
                        } else {
                            Text("\(manager.renderCacheFileCount) öğe silinmeye aday")
                                .font(.caption)
                                .foregroundColor(AppTheme.textMuted)
                        }
                        
                        Spacer()
                        
                        Button {
                            manager.scanRenderCache()
                        } label: {
                            Label("Yenile", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            manager.clearRenderCache()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash.fill")
                                Text("Klasörü Temizle")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accentRose)
                        .disabled(manager.isCleaningRenderCache || manager.renderCacheItems.isEmpty)
                    }
                }
                .corvusCard(padding: 20, radius: 16)
                
                // MARK: - Paths Configuration Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dosya ve Komut Satırı Yolları")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Corvus Proje Dizini")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        HStack {
                            TextField("Dizin Yolu", text: $projectPathInput)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Gözat...") {
                                chooseFolder()
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Python3 Yolu (requests, rich, pillow yüklü olmalı)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("/opt/homebrew/bin/python3", text: $pythonPathInput)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        if let s = saveStatus {
                            Text(s)
                                .font(.caption.weight(.medium))
                                .foregroundColor(AppTheme.accentGreen)
                        }
                        
                        Spacer()
                        
                        Button("Varsayılana Sıfırla (CorvusEngine)") {
                            let best = CorvusManager.detectBestProjectPath()
                            projectPathInput = best
                            manager.corvusProjectPath = best
                            saveStatus = "✓ Varsayılan konuma sıfırlandı."
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Ayarları Kaydet") {
                            manager.corvusProjectPath = projectPathInput
                            manager.pythonExecutablePath = pythonPathInput
                            saveStatus = "✓ Ayarlar başarıyla güncellendi!"
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .corvusCard(padding: 20, radius: 16)
                
                // MARK: - Adobe & API Integrations Status
                VStack(alignment: .leading, spacing: 14) {
                    Text("Harici Entegrasyon Durumları")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    VStack(spacing: 10) {
                        integrationRow(
                            name: "Adobe After Effects (aerender)",
                            detail: manager.aerenderFound ? manager.aerenderPath : "aerender bulunamadı",
                            isOk: manager.aerenderFound
                        )
                        
                        integrationRow(
                            name: "Adobe Photoshop",
                            detail: manager.photoshopFound ? manager.photoshopAppName : "Photoshop uygulaması bulunamadı",
                            isOk: manager.photoshopFound
                        )
                        
                        integrationRow(
                            name: "API-Sports Anahtarı (api.txt)",
                            detail: manager.apiKeyFound ? "api.txt mevcut ve geçerli" : "api.txt proje dizininde bulunamadı",
                            isOk: manager.apiKeyFound
                        )
                    }
                }
                .corvusCard(padding: 20, radius: 16)
                
                // MARK: - About & Changelog
                VStack(alignment: .leading, spacing: 14) {
                    Text("Uygulama Bilgileri")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 16) {
                        Image("CorvusLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Corvus Mac v\(manager.appVersion) (CLI v\(manager.engineVersion) Çekirdeği)")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Geliştiriciler: Ufuk Çelen & Mustafa Yiğit Kızılel")
                                .font(.caption)
                                .foregroundColor(AppTheme.textMuted)
                        }
                        
                        Spacer()
                        
                        Button {
                            showChangelog = true
                        } label: {
                            Label("Sürüm Notları", systemImage: "doc.text")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .corvusCard(padding: 20, radius: 16)
            }
            .padding(24)
        }
        .background(AppTheme.bg)
        .onAppear {
            projectPathInput = manager.corvusProjectPath
            pythonPathInput = manager.pythonExecutablePath
        }
        .sheet(isPresented: $showChangelog) {
            ChangelogSheet()
        }
    }
    
        // MARK: - Software & Engine Update Hub
    private var updateHubCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            updateHubHeader
            Divider().overlay(AppTheme.border)
            if manager.isNewAppVersionAvailable {
                versionNoticeBanner
            }
            repoStatusRows
            updateActionRow
        }
        .corvusCard(padding: 20, radius: 16)
    }

    private var updateHubHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Yazılım ve Güncelleme Merkezi")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Uygulama ve CLI motorunu GitHub üzerinden güncel ve senkronize tutun")
                    .font(.caption)
                    .foregroundColor(AppTheme.textMuted)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Label("v\(manager.appVersion)", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.accentCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentCyan.opacity(0.15))
                    .overlay(Capsule().stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 1))
                    .clipShape(Capsule())
                
                Label("CLI v\(manager.engineVersion)", systemImage: "terminal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(AppTheme.accentGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentGreen.opacity(0.15))
                    .overlay(Capsule().stroke(AppTheme.accentGreen.opacity(0.3), lineWidth: 1))
                    .clipShape(Capsule())
            }
        }
    }

    private var versionNoticeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.title2)
                .foregroundColor(AppTheme.accentCyan)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Yeni Corvus Mac Sürümü Hazır (\(manager.latestAppTag ?? "v0.2.0"))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Şu an çalışan sürüm: v\(manager.appVersion). Otomatik güncelleme GitHub Release paketini indirip uygulamayı anında yenisiyle değiştirecektir.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button {
                Task {
                    await manager.checkForUpdates()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Şimdi Güncelle")
                }
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AppTheme.accentCyan)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(AppTheme.accentCyan.opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 1))
        .cornerRadius(10)
    }

    private var repoStatusRows: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.accentCyan)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Corvus Mac UI (SwiftUI Arayüzü)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(manager.latestAppCommit ?? "Depo: github.com/ufukcelen/corvusUI")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Link("GitHub", destination: URL(string: "https://github.com/ufukcelen/corvusUI")!)
                    .font(.caption)
                    .foregroundColor(AppTheme.accentCyan)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.surfaceElevated)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderSubtle, lineWidth: 1))
            )
            
            HStack(spacing: 12) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.accentGreen)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Corvus CLI Çekirdeği (Python Motoru)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(manager.latestCliCommit ?? "Depo: github.com/ufukcelen/Corvus (Git Submodule)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Link("GitHub", destination: URL(string: "https://github.com/ufukcelen/Corvus")!)
                    .font(.caption)
                    .foregroundColor(AppTheme.accentGreen)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.surfaceElevated)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.borderSubtle, lineWidth: 1))
            )
        }
    }

    private var updateActionRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let s = manager.submoduleUpdateStatus ?? manager.updateCheckResult {
                    Text(s)
                        .font(.caption.weight(.medium))
                        .foregroundColor(s.contains("✗") ? AppTheme.accentRose : AppTheme.accentGreen)
                } else {
                    Text("Depolar güncel. Yeni özellikler eklendiğinde doğrudan buradan güncelleyebilirsiniz.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textMuted)
                }
                
                if let last = manager.lastUpdateCheckDate {
                    Text("Son kontrol: \(last.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            
            Spacer()
            
            Button {
                Task {
                    await manager.checkForUpdates()
                }
            } label: {
                HStack(spacing: 6) {
                    if manager.isCheckingForUpdates {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(manager.isCheckingForUpdates ? "Denetleniyor..." : "Denetle")
                }
            }
            .buttonStyle(.bordered)
            .disabled(manager.isCheckingForUpdates || manager.isUpdatingSubmodule)
            
            Button {
                manager.updateAllComponents()
            } label: {
                HStack(spacing: 6) {
                    if manager.isUpdatingSubmodule {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(manager.isUpdatingSubmodule ? "Güncelleniyor..." : "Tümünü Güncelle (Git Pull)")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(manager.isUpdatingSubmodule || manager.isCheckingForUpdates)
        }
    }

// MARK: - Theme Selection Card
    private func themeSelectionCard(_ mode: AppThemeMode) -> some View {
        let isSelected = manager.appThemeMode == mode
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                manager.appThemeMode = mode
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? mode.accentPrimary.opacity(0.25) : AppTheme.surfaceElevated)
                        .frame(width: 38, height: 38)
                    Image(systemName: mode.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isSelected ? mode.accentPrimary : AppTheme.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(mode.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        if mode.hasGrain {
                            Text("DOKU")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(mode.accentPrimary.opacity(0.15))
                                .foregroundColor(mode.accentPrimary)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(mode.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                        .lineLimit(1)
                    
                    // Palette Preview Swatch Dots
                    HStack(spacing: 4) {
                        Circle().fill(mode.bg).frame(width: 8, height: 8).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        Circle().fill(mode.surface).frame(width: 8, height: 8)
                        Circle().fill(mode.accentPrimary).frame(width: 8, height: 8)
                        Circle().fill(mode.accentSecondary).frame(width: 8, height: 8)
                        if mode.hasGrain {
                            Circle().fill(mode.accentTertiary).frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(mode.accentPrimary)
                        .font(.title3)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: mode.defaultCornerRadius)
                    .fill(isSelected ? mode.accentPrimary.opacity(0.10) : AppTheme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: mode.defaultCornerRadius)
                    .stroke(isSelected ? mode.accentPrimary : AppTheme.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func userSelectionCard(_ u: CorvusUser) -> some View {
        let isSelected = manager.currentUser == u
        return Button {
            manager.currentUser = u
        } label: {
            HStack(spacing: 12) {
                Image(systemName: u.avatarSystemImage)
                    .font(.system(size: 28))
                    .foregroundColor(u.themeColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(u.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(u == .ufuk ? "1. Kullanıcı" : "2. Kullanıcı")
                        .font(.caption)
                        .foregroundColor(AppTheme.textMuted)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(u.themeColor)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? u.themeColor.opacity(0.12) : AppTheme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? u.themeColor : AppTheme.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func integrationRow(name: String, detail: String, isOk: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isOk ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isOk ? AppTheme.accentGreen : AppTheme.accentOrange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private func chooseRenderCacheFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Render Klasörünü Seç"
        if panel.runModal() == .OK, let url = panel.url {
            manager.renderCacheFolderPath = url.path
        }
    }
    
    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Klasörü Seç"
        
        if panel.runModal() == .OK, let url = panel.url {
            projectPathInput = url.path
        }
    }
}

// MARK: - Changelog Sheet
struct ChangelogSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let changelogs: [(version: String, date: String, items: [String])] = [
        ("v0.2.0", "Kasım 2026", [
            "Radio Mocas stüdyosuna 'Mocas Bey ve Radyosu' duyuru otomasyonu eklendi.",
            "mocasBey27.aep projesi ve mocasBeyComp kompozisyonu için saat güncelleme ve render akışı entegre edildi.",
            "Mocas Bey için YouTube yayın SEO metni üretimi (mocasBeySeo.txt) eklendi."
        ]),
        ("v0.1.8", "Kasım 2026", [
            "Adobe After Effects 2027 aerender desteği eklendi.",
            "AE 2026 ve 2027 kullanan ekip üyeleri için çapraz uyumlu otomatik render tespiti.",
            "Sol menü (sidebar) yeni temalara (Vintage Malikâne, Ortaçağ, Bizans, Gelecek) tam entegre edildi."
        ]),
        ("v1.5.0", "Ekim 2026", [
            "Yazılım ve Güncelleme Merkezi (Auto-Update Hub) eklendi.",
            "Şık Dark Mode stüdyo teması (Obsidian, OLED, Space) eklendi.",
            "Corvus Mac Native SwiftUI uygulaması entegre edildi.",
            "Canlı Maç ve Haftalık Program Photoshop thumbnail sihirbazları tamamlandı.",
            "Firebase RTDB Takvim ve Sohbet senkronizasyonu gerçek zamanlı hale getirildi.",
            "Optik Ağırlık algoritması ile yuvarlak ve dikey logoların Photoshop Smart Object içine otomatik dengeli yerleşimi sağlandı.",
            "Git Submodule mimarisi ile Corvus CLI çekirdeği otomatik entegre edildi."
        ]),
        ("v1.4.8", "Ekim 2026", [
            "Tellal/Corvus CLI banner ve rich arayüz geçişleri güncellendi.",
            "Ntfy anlık bildirim kanalları optimize edildi."
        ]),
        ("v1.4.7", "Eylül 2026", [
            "Albert ve Cem ile Filtresiz Memleket Havası After Effects render entegrasyonu tamamlandı."
        ]),
        ("v1.4.0", "Ağustos 2026", [
            "FC27 Kariyer duyuru motoru ve Tek Maçtan Yatanlar şablonları eklendi."
        ])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Corvus Sürüm Notları")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textMuted)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .overlay(AppTheme.border)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(changelogs, id: \.version) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(entry.version)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("(\(entry.date))")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(entry.items, id: \.self) { it in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .foregroundColor(AppTheme.accentCyan)
                                        Text(it)
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.surfaceElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 540, height: 480)
        .background(AppTheme.bg)
    }
}

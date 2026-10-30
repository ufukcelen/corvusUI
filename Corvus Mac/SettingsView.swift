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
                    Text("Kullanıcı profili, çekirdek deposu, dosya yolları ve harici araç durumları")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Active User Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Aktif Kullanıcı Profili")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        userSelectionCard(.ufuk)
                        userSelectionCard(.yigit)
                    }
                    
                    Text("💡 Profil seçimi bildirim rotalarını, sohbet renginizi ve takvim güncellemelerini belirler.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                // Git Submodule (Corvus Engine) Sync Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Corvus CLI Çekirdeği (Git Submodule)")
                                .font(.headline)
                            Text("Bağlı Depo: github.com/ufukcelen/Corvus")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isSubmoduleActive {
                            Label("Alt Modül Aktif", systemImage: "checkmark.seal.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.12))
                                .clipShape(Capsule())
                        } else {
                            Label("Özel Klasör", systemImage: "folder.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CLI motorunda yapılan güncellemeleri tek tıkla buraya çekebilirsiniz:")
                                .font(.subheadline)
                            
                            if let status = manager.submoduleUpdateStatus {
                                Text(status)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(status.contains("❌") ? .red : .green)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            manager.updateSubmoduleEngine()
                        } label: {
                            HStack(spacing: 6) {
                                if manager.isUpdatingSubmodule {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text(manager.isUpdatingSubmodule ? "Çekiliyor..." : "Çekirdeği Güncelle (Git Pull)")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(manager.isUpdatingSubmodule)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                // Paths Configuration Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dosya ve Komut Satırı Yolları")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Corvus Proje Dizini")
                            .font(.subheadline.weight(.medium))
                        
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
                        
                        TextField("/opt/homebrew/bin/python3", text: $pythonPathInput)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        if let s = saveStatus {
                            Text(s)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        Button("Varsayılana Sıfırla (CorvusEngine)") {
                            let best = CorvusManager.detectBestProjectPath()
                            projectPathInput = best
                            manager.corvusProjectPath = best
                            saveStatus = "✓ Submodule yoluna sıfırlandı."
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
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                // Adobe & API Integrations Status
                VStack(alignment: .leading, spacing: 14) {
                    Text("Harici Entegrasyon Durumları")
                        .font(.headline)
                    
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
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                // About & Changelog
                VStack(alignment: .leading, spacing: 14) {
                    Text("Uygulama Bilgileri")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        Image("CorvusLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Corvus Mac v0.1.0 (CLI v1.5.0 Çekirdeği)")
                                .font(.subheadline.weight(.bold))
                            Text("Geliştiriciler: Ufuk Çelen & Mustafa Yiğit Kızılel")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            projectPathInput = manager.corvusProjectPath
            pythonPathInput = manager.pythonExecutablePath
        }
        .sheet(isPresented: $showChangelog) {
            ChangelogSheet()
        }
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
                        .foregroundColor(.primary)
                    Text(u == .ufuk ? "1. Kullanıcı" : "2. Kullanıcı")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? u.themeColor.opacity(0.12) : Color(NSColor.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? u.themeColor : Color.primary.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func integrationRow(name: String, detail: String, isOk: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isOk ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isOk ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor))
        )
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
        ("v1.5.0", "Ekim 2026", [
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
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(changelogs, id: \.version) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(entry.version)
                                    .font(.headline)
                                Text("(\(entry.date))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(entry.items, id: \.self) { it in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .foregroundColor(.accentColor)
                                        Text(it)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 540, height: 480)
    }
}

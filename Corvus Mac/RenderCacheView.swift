//
//  RenderCacheView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 09.11.2026.
//

import SwiftUI
import AppKit

struct RenderCacheView: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var showConfirmAlert: Bool = false
    @State private var customFolderInput: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.accentRose.opacity(0.3), AppTheme.accentPurple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.accentRose.opacity(0.4), lineWidth: 1.5)
                            )
                        
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.accentRose)
                    }
                    .corvusGlow(color: AppTheme.accentRose, radius: 12, opacity: 0.3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Render & Önbellek Temizleme")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("After Effects aerender, Photoshop çıktıları ve geçici render önbelleklerini temizleyerek disk alanı kazanın.")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // MARK: - Folder Selection Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hedef Render Klasörü")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Temizlemek istediğiniz render çıktı klasörünü veya AE önbellek dizinini belirleyin")
                                .font(.caption)
                                .foregroundColor(AppTheme.textMuted)
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(AppTheme.accentCyan)
                        
                        TextField("Klasör Yolu", text: $customFolderInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if FileManager.default.fileExists(atPath: customFolderInput) {
                                    manager.renderCacheFolderPath = customFolderInput
                                }
                            }
                        
                        Button("Klasör Seç...") {
                            chooseRenderFolder()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accentCyan)
                        
                        if !manager.renderCacheFolderPath.isEmpty && FileManager.default.fileExists(atPath: manager.renderCacheFolderPath) {
                            Button {
                                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: manager.renderCacheFolderPath)
                            } label: {
                                Image(systemName: "arrow.up.forward.square")
                            }
                            .buttonStyle(.bordered)
                            .help("Finder'da Göster")
                        }
                    }
                    
                    // Quick Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hızlı Konumlar:")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textMuted)
                        
                        HStack(spacing: 10) {
                            presetButton(
                                title: "Masaüstü (Desktop)",
                                icon: "desktopcomputer",
                                path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path
                            )
                            
                            presetButton(
                                title: "After Effects Cache",
                                icon: "film.fill",
                                path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches/Adobe/After Effects").path
                            )
                            
                            presetButton(
                                title: "Filmler (Movies)",
                                icon: "video.fill",
                                path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies").path
                            )
                            
                            if !manager.corvusProjectPath.isEmpty {
                                presetButton(
                                    title: "Corvus Projesi",
                                    icon: "gearshape.2.fill",
                                    path: manager.corvusProjectPath
                                )
                            }
                        }
                    }
                }
                .corvusCard(padding: 20, radius: 16)
                
                // MARK: - Metrics Grid & Clean Action
                HStack(spacing: 16) {
                    // Toplam Boyut
                    metricCard(
                        title: "Önbellek Boyutu",
                        value: ByteCountFormatter.string(fromByteCount: manager.renderCacheTotalSizeBytes, countStyle: .file),
                        caption: manager.renderCacheTotalSizeBytes > 0 ? "Temizlemeye hazır" : "Klasör temiz",
                        icon: "internaldrive.fill",
                        color: manager.renderCacheTotalSizeBytes > 0 ? AppTheme.accentRose : AppTheme.accentGreen
                    )
                    
                    // Dosya Sayısı
                    metricCard(
                        title: "Bulunan Öğe",
                        value: "\(manager.renderCacheFileCount) Öğe",
                        caption: manager.isScanningRenderCache ? "Taranıyor..." : "Render çıktısı & önbellek",
                        icon: "doc.on.doc.fill",
                        color: AppTheme.accentCyan
                    )
                    
                    // Güvenlik Kalkanı
                    metricCard(
                        title: "Güvenlik Filtresi",
                        value: "Korumalı",
                        caption: isDesktopFolder ? "Masaüstünde yalnızca render ve videolar silinir" : "Sistem dizinleri korunur",
                        icon: "checkmark.shield.fill",
                        color: AppTheme.accentGreen
                    )
                }
                
                // MARK: - Clean Action Bar
                VStack(spacing: 14) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Otomatik Temizleme")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text(isDesktopFolder ?
                                 "Masaüstündeki tüm .mp4, .mov, FC27, memleket ve After Effects render dosyaları kalıcı silinir." :
                                 "Seçili klasörün içindeki tüm geçici render ve önbellek dosyaları silinir.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showConfirmAlert = true
                        } label: {
                            HStack(spacing: 8) {
                                if manager.isCleaningRenderCache {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "flame.fill")
                                }
                                Text(manager.isCleaningRenderCache ? "Temizleniyor..." : "Klasörü Otomatik Temizle")
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accentRose)
                        .disabled(manager.isCleaningRenderCache || manager.renderCacheItems.isEmpty)
                        .corvusGlow(color: AppTheme.accentRose, radius: manager.renderCacheItems.isEmpty ? 0 : 10, opacity: 0.35)
                    }
                    
                    if let status = manager.lastCleanedStatus {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.accentGreen)
                            Text(status)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.accentGreen)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.accentGreen.opacity(0.12))
                        .cornerRadius(10)
                    }
                }
                .corvusCard(padding: 20, radius: 16)
                
                // MARK: - Files Preview List
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Klasördeki Dosyalar ve Önbellekler")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Silinmeye aday öğelerin listesi (\(manager.renderCacheItems.count) adet)")
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
                        .disabled(manager.isScanningRenderCache)
                    }
                    
                    if manager.isScanningRenderCache {
                        HStack {
                            Spacer()
                            ProgressView("Klasör taranıyor...")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                        }
                        .padding(.vertical, 30)
                    } else if manager.renderCacheItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 36))
                                .foregroundColor(AppTheme.accentGreen)
                            Text("Klasör Tertemiz!")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Seçilen konumda temizlenecek render çıktısı veya geçici dosya bulunamadı.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(manager.renderCacheItems) { item in
                                cacheItemRow(item)
                            }
                        }
                    }
                }
                .corvusCard(padding: 20, radius: 16)
            }
            .padding(24)
        }
        .onAppear {
            customFolderInput = manager.renderCacheFolderPath
            manager.scanRenderCache()
        }
        .alert("Render Önbelleğini Temizle", isPresented: $showConfirmAlert) {
            Button("Vazgeç", role: .cancel) { }
            Button("Evet, Temizle", role: .destructive) {
                manager.clearRenderCache()
            }
        } message: {
            Text("Seçili klasördeki (\(manager.renderCacheFolderPath)) render ve önbellek öğeleri kalıcı olarak silinecektir.\n\nToplam silinecek boyut: \(ByteCountFormatter.string(fromByteCount: manager.renderCacheTotalSizeBytes, countStyle: .file))\n\nDevam etmek istiyor musunuz?")
        }
    }
    
    // MARK: - Helper Views
    private var isDesktopFolder: Bool {
        let desk = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").path
        return manager.renderCacheFolderPath == desk
    }
    
    private func metricCard(title: String, value: String, caption: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.textMuted)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(caption)
                    .font(.caption2)
                    .foregroundColor(color)
                    .lineLimit(1)
            }
            Spacer()
        }
        .corvusCard(padding: 16, radius: 14)
    }
    
    private func presetButton(title: String, icon: String, path: String) -> some View {
        Button {
            customFolderInput = path
            manager.renderCacheFolderPath = path
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(manager.renderCacheFolderPath == path ? AppTheme.accentCyan.opacity(0.2) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(manager.renderCacheFolderPath == path ? AppTheme.accentCyan : Color.secondary.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .foregroundColor(manager.renderCacheFolderPath == path ? AppTheme.accentCyan : AppTheme.textPrimary)
    }
    
    private func cacheItemRow(_ item: RenderCacheItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 16))
                .foregroundColor(item.isDirectory ? AppTheme.accentCyan : AppTheme.accentPurple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                if let mod = item.modDate {
                    Text("Değiştirilme: \(mod.formatted(date: .numeric, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            
            Spacer()
            
            Text(item.formattedSize)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.textSecondary)
            
            Button {
                NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: manager.renderCacheFolderPath)
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textMuted)
            }
            .buttonStyle(.plain)
            .help("Finder'da Göster")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.surfaceElevated.opacity(0.5))
        .cornerRadius(8)
    }
    
    private func chooseRenderFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Render Klasörünü Seç"
        
        if panel.runModal() == .OK, let url = panel.url {
            customFolderInput = url.path
            manager.renderCacheFolderPath = url.path
        }
    }
}

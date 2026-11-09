//
//  ContentView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = CorvusManager.shared
    @State private var selectedTab: String? = "dashboard"
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
                .background(AppTheme.sidebarBg)
        } detail: {
            detailContent
                .background(AppTheme.bg.ignoresSafeArea())
        }
        .frame(minWidth: 960, minHeight: 640)
        .overlay {
            if manager.isAutoUpdating {
                ZStack {
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(AppTheme.accentCyan)
                        
                        VStack(spacing: 8) {
                            Text("Corvus Mac Güncelleniyor")
                                .font(.title3.weight(.bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(manager.autoUpdateStatus ?? "Yeni sürüm indiriliyor ve kuruluyor...")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 360)
                        }
                    }
                    .padding(32)
                    .background(AppTheme.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 1.5)
                    )
                    .cornerRadius(16)
                    .corvusGlow(color: AppTheme.accentCyan, radius: 24, opacity: 0.3)
                    .shadow(radius: 30)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if manager.isRunningTask {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(manager.currentTaskTitle ?? "İşlem Yürütülüyor...")
                            .font(.caption.weight(.medium))
                            .foregroundColor(AppTheme.accentCyan)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.accentCyan.opacity(0.12))
                    .overlay(
                        Capsule().stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .corvusGlow(color: AppTheme.accentCyan, radius: 6)
                }
                
                // Theme Quick Switcher
                Menu {
                    Section("Karanlık Mod Temaları") {
                        ForEach(AppThemeMode.allCases) { mode in
                            Button {
                                manager.appThemeMode = mode
                            } label: {
                                HStack {
                                    Label(mode.title, systemImage: mode.icon)
                                    if manager.appThemeMode == mode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: manager.appThemeMode.icon)
                        .foregroundColor(.primary)
                }
                .help("Tema Seçimi: \(manager.appThemeMode.title)")
                
                Button {
                    Task { await manager.syncAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Canlı Verileri Eşitle")
            }
        }
    }
    
    // MARK: - Sidebar
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // App Branding
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accentCyan.opacity(0.3), AppTheme.accentPurple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    
                    Image("CorvusLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .corvusGlow(color: AppTheme.accentCyan, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text("Corvus")
                            .font(.headline.weight(.bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Circle()
                            .fill(AppTheme.accentGreen)
                            .frame(width: 6, height: 6)
                    }
                    Text("Otomasyon Stüdyosu")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .overlay(AppTheme.border)
            
            // Navigation List
            List(selection: $selectedTab) {
                Section("Genel") {
                    NavigationLink(value: "dashboard") {
                        Label("Genel Bakış", systemImage: "square.grid.2x2.fill")
                    }
                    
                    NavigationLink(value: "calendar") {
                        HStack {
                            Label("Takvim & Yayınlar", systemImage: "calendar")
                            Spacer()
                            if !manager.calendarItems.isEmpty {
                                Text("\(manager.calendarItems.count)")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.accentCyan.opacity(0.15))
                                    .foregroundColor(AppTheme.accentCyan)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    NavigationLink(value: "chat") {
                        HStack {
                            Label("Ekip Sohbeti", systemImage: "bubble.left.and.bubble.right.fill")
                            Spacer()
                            if !manager.chatMessages.isEmpty {
                                Text("\(manager.chatMessages.count)")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .foregroundColor(.secondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    NavigationLink(value: "notification") {
                        Label("Bildirim Gönder", systemImage: "paperplane.fill")
                    }
                }
                
                Section("Stüdyolar") {
                    NavigationLink(value: "uykusuz_tosba") {
                        Label("Uykusuz Tosba", systemImage: "tortoise.fill")
                    }
                    
                    NavigationLink(value: "radio_mocas") {
                        Label("Radio Mocas", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    
                    NavigationLink(value: "photoshop") {
                        Label("Photoshop Thumb", systemImage: "photo.stack.fill")
                    }
                }
                
                Section("Sistem") {
                    NavigationLink(value: "console") {
                        HStack {
                            Label("Konsol & Çıktılar", systemImage: "terminal.fill")
                            Spacer()
                            if manager.isRunningTask {
                                Circle()
                                    .fill(AppTheme.accentCyan)
                                    .frame(width: 8, height: 8)
                                    .corvusGlow(color: AppTheme.accentCyan, radius: 4)
                            }
                        }
                    }
                    
                    NavigationLink(value: "render_cache") {
                        HStack {
                            Label("Render Cache", systemImage: "trash.fill")
                            Spacer()
                            if manager.renderCacheTotalSizeBytes > 0 {
                                Text(ByteCountFormatter.string(fromByteCount: manager.renderCacheTotalSizeBytes, countStyle: .file))
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.accentRose.opacity(0.18))
                                    .foregroundColor(AppTheme.accentRose)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    NavigationLink(value: "settings") {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                    }
                }
            }
            .listStyle(.sidebar)
            
            Divider()
                .overlay(AppTheme.border)
            
            // Bottom Active User Widget
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(manager.currentUser.themeColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: manager.currentUser.avatarSystemImage)
                        .font(.callout)
                        .foregroundColor(manager.currentUser.themeColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.currentUser.name)
                        .font(.caption.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(manager.currentUser == .ufuk ? "1. Kullanıcı" : "2. Kullanıcı")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted)
                }
                
                Spacer()
                
                Button {
                    manager.currentUser = manager.currentUser.otherUser
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(6)
                        .background(AppTheme.surfaceElevated)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Kullanıcıyı \(manager.currentUser.otherUser.name) olarak değiştir")
            }
            .padding(12)
            .background(AppTheme.surface.opacity(0.85))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(AppTheme.border),
                alignment: .top
            )
        }
    }
    
    // MARK: - Detail
    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case "dashboard":
            DashboardView(selectedTab: $selectedTab)
        case "calendar":
            CalendarView()
        case "chat":
            ChatView()
        case "notification":
            NotificationView()
        case "uykusuz_tosba":
            UykusuzTosbaView()
        case "radio_mocas":
            RadioMocasView()
        case "photoshop":
            ThumbnailStudioView()
        case "console":
            ConsoleView()
        case "render_cache":
            RenderCacheView()
        case "settings":
            SettingsView()
        default:
            DashboardView(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    ContentView()
}

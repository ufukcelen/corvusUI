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
        let theme = manager.appThemeMode
        
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            detailContent
                .background(
                    CorvusBackdropView(theme: theme)
                )
        }
        .tint(theme.accentPrimary)
        .frame(minWidth: 960, minHeight: 640)
        .overlay {
            if manager.isAutoUpdating {
                ZStack {
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(theme.accentPrimary)
                        
                        VStack(spacing: 8) {
                            Text("Corvus Mac Güncelleniyor")
                                .font(.title3.weight(.bold))
                                .foregroundColor(theme.textPrimary)
                            
                            Text(manager.autoUpdateStatus ?? "Yeni sürüm indiriliyor ve kuruluyor...")
                                .font(.subheadline)
                                .foregroundColor(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 360)
                        }
                    }
                    .padding(32)
                    .background(theme.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1.5)
                    )
                    .cornerRadius(16)
                    .corvusGlow(color: theme.accentPrimary, radius: 24, opacity: 0.3)
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
                            .foregroundColor(theme.accentPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.accentPrimary.opacity(0.12))
                    .overlay(
                        Capsule().stroke(theme.accentPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .corvusGlow(color: theme.accentPrimary, radius: 6)
                }
                
                // Theme Quick Switcher
                Menu {
                    Section("Karanlık Mod Temaları") {
                        ForEach(AppThemeMode.allCases) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    manager.appThemeMode = mode
                                }
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
                        .foregroundColor(theme.accentPrimary)
                }
                .help("Tema Seçimi: \(manager.appThemeMode.title)")
                
                Button {
                    Task { await manager.syncAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(theme.textSecondary)
                }
                .help("Canlı Verileri Eşitle")
            }
        }
    }
    
    // MARK: - Sidebar
    private var sidebarContent: some View {
        let theme = manager.appThemeMode
        return VStack(spacing: 0) {
            // App Branding
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [theme.accentPrimary.opacity(0.35), theme.accentSecondary.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.cardBorderColor, lineWidth: 1)
                        )
                    
                    Image("CorvusLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .corvusGlow(color: theme.accentPrimary, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text("Corvus")
                            .font(.headline.weight(.bold))
                            .foregroundColor(theme.textPrimary)
                        
                        Circle()
                            .fill(theme.accentTertiary)
                            .frame(width: 6, height: 6)
                    }
                    Text("Otomasyon Stüdyosu")
                        .font(.caption2)
                        .foregroundColor(theme.textMuted)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .overlay(theme.cardBorderColor)
            
            // Custom Navigation Items
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    sidebarSection("Genel", theme: theme) {
                        sidebarItem(id: "dashboard", title: "Genel Bakış", icon: "square.grid.2x2.fill", theme: theme)
                        sidebarItem(id: "calendar", title: "Takvim & Yayınlar", icon: "calendar",
                                    badge: !manager.calendarItems.isEmpty ? "\(manager.calendarItems.count)" : nil,
                                    theme: theme)
                        sidebarItem(id: "chat", title: "Ekip Sohbeti", icon: "bubble.left.and.bubble.right.fill",
                                    badge: !manager.chatMessages.isEmpty ? "\(manager.chatMessages.count)" : nil,
                                    theme: theme)
                        sidebarItem(id: "notification", title: "Bildirim Gönder", icon: "paperplane.fill", theme: theme)
                    }
                    
                    sidebarSection("Stüdyolar", theme: theme) {
                        sidebarItem(id: "uykusuz_tosba", title: "Uykusuz Tosba", icon: "tortoise.fill", theme: theme)
                        sidebarItem(id: "radio_mocas", title: "Radio Mocas", icon: "antenna.radiowaves.left.and.right", theme: theme)
                        sidebarItem(id: "photoshop", title: "Photoshop Thumb", icon: "photo.stack.fill", theme: theme)
                    }
                    
                    sidebarSection("Sistem", theme: theme) {
                        sidebarItem(id: "console", title: "Konsol & Çıktılar", icon: "terminal.fill",
                                    isPulse: manager.isRunningTask, theme: theme)
                        sidebarItem(id: "render_cache", title: "Render Cache", icon: "trash.fill",
                                    badge: manager.renderCacheTotalSizeBytes > 0 ? ByteCountFormatter.string(fromByteCount: manager.renderCacheTotalSizeBytes, countStyle: .file) : nil,
                                    badgeColor: AppTheme.accentRose,
                                    theme: theme)
                        sidebarItem(id: "settings", title: "Ayarlar", icon: "gearshape.fill", theme: theme)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
            }
            
            Divider()
                .overlay(theme.cardBorderColor)
            
            // Bottom Active User Widget
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(manager.currentUser.themeColor.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: manager.currentUser.avatarSystemImage)
                        .font(.callout)
                        .foregroundColor(manager.currentUser.themeColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.currentUser.name)
                        .font(.caption.weight(.bold))
                        .foregroundColor(theme.textPrimary)
                    Text(manager.currentUser == .ufuk ? "1. Kullanıcı" : "2. Kullanıcı")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textMuted)
                }
                
                Spacer()
                
                Button {
                    manager.currentUser = manager.currentUser.otherUser
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .padding(6)
                        .background(theme.surfaceElevated)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(theme.cardBorderColor, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Kullanıcıyı \(manager.currentUser.otherUser.name) olarak değiştir")
            }
            .padding(12)
            .background(theme.surface.opacity(0.70))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                theme.sidebarBg
                if theme.hasGrain {
                    ThemeGrainOverlay(opacity: theme.grainOpacity)
                }
            }
            .ignoresSafeArea()
        )
    }
    
    private func sidebarSection<Content: View>(_ title: String, theme: AppThemeMode, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(theme.textMuted)
                .padding(.horizontal, 10)
                .padding(.top, 4)
                .padding(.bottom, 2)
            
            content()
        }
    }
    
    private func sidebarItem(
        id: String,
        title: String,
        icon: String,
        badge: String? = nil,
        badgeColor: Color? = nil,
        isPulse: Bool = false,
        theme: AppThemeMode
    ) -> some View {
        SidebarNavItemView(
            id: id,
            title: title,
            icon: icon,
            badge: badge,
            badgeColor: badgeColor,
            isPulse: isPulse,
            isSelected: selectedTab == id,
            theme: theme
        ) {
            withAnimation(.easeInOut(duration: 0.16)) {
                selectedTab = id
            }
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

// MARK: - Thematic Sidebar Navigation Item View
struct SidebarNavItemView: View {
    let id: String
    let title: String
    let icon: String
    var badge: String? = nil
    var badgeColor: Color? = nil
    var isPulse: Bool = false
    let isSelected: Bool
    let theme: AppThemeMode
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: max(6, theme.defaultCornerRadius - 4))
                        .fill(isSelected ? theme.accentPrimary.opacity(0.20) : (isHovered ? theme.surfaceHover : Color.clear))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(isSelected ? theme.accentPrimary : (isHovered ? theme.textPrimary : theme.accentPrimary.opacity(0.80)))
                }
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? theme.textPrimary : (isHovered ? theme.textPrimary : theme.textSecondary))
                
                Spacer()
                
                if isPulse {
                    StatusPulseDot(status: true, customColor: theme.accentPrimary, size: 7)
                }
                
                if let badge = badge, !badge.isEmpty {
                    let bColor = badgeColor ?? theme.accentPrimary
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(bColor.opacity(isSelected ? 0.30 : 0.16))
                        .foregroundColor(bColor)
                        .overlay(
                            Capsule()
                                .stroke(bColor.opacity(0.35), lineWidth: 0.8)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: theme.defaultCornerRadius)
                    .fill(isSelected ? theme.accentPrimary.opacity(0.18) : (isHovered ? theme.surfaceHover.opacity(0.60) : Color.clear))
            )
            .overlay(
                sidebarItemBorder(for: theme, isSelected: isSelected)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
    
    @ViewBuilder
    private func sidebarItemBorder(for theme: AppThemeMode, isSelected: Bool) -> some View {
        if isSelected {
            switch theme {
            case .futuristic:
                RoundedRectangle(cornerRadius: theme.defaultCornerRadius)
                    .stroke(theme.accentPrimary, lineWidth: 1.2)
                    .corvusGlow(color: theme.accentPrimary, radius: 6, opacity: 0.45)
            case .byzantine, .vintageManor:
                ZStack {
                    RoundedRectangle(cornerRadius: theme.defaultCornerRadius)
                        .stroke(theme.accentPrimary.opacity(0.65), lineWidth: 1.2)
                    RoundedRectangle(cornerRadius: max(2, theme.defaultCornerRadius - 2))
                        .stroke(theme.accentPrimary.opacity(0.25), lineWidth: 0.6)
                        .padding(2)
                }
            case .medieval:
                RoundedRectangle(cornerRadius: theme.defaultCornerRadius)
                    .stroke(theme.accentPrimary.opacity(0.55), lineWidth: 1.2)
            default:
                RoundedRectangle(cornerRadius: theme.defaultCornerRadius)
                    .stroke(theme.accentPrimary.opacity(0.40), lineWidth: 1)
            }
        } else if isHovered {
            RoundedRectangle(cornerRadius: theme.defaultCornerRadius)
                .stroke(theme.cardBorderColor.opacity(0.45), lineWidth: 0.8)
        } else {
            EmptyView()
        }
    }
}

//
//  DashboardView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager = CorvusManager.shared
    @Binding var selectedTab: String?
    @State private var quickMessageText: String = ""
    @State private var showAddBroadcastSheet: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                headerBanner
                
                // System Status Cards
                systemStatusGrid
                
                // Quick Actions
                quickActionSection
                
                // Live Feeds Split: Calendar & Chat
                HStack(alignment: .top, spacing: 20) {
                    miniCalendarCard
                    miniChatCard
                }
            }
            .padding(24)
        }
        .background(AppTheme.bg)
        .sheet(isPresented: $showAddBroadcastSheet) {
            AddBroadcastSheet()
        }
    }
    
    // MARK: - Header Banner
    private var headerBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [manager.currentUser.themeColor.opacity(0.35), AppTheme.accentCyan.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                
                Image("CorvusLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .corvusGlow(color: manager.currentUser.themeColor, radius: 10, opacity: 0.3)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Corvus Otomasyon Stüdyosu")
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("v1.5.0")
                        .font(.caption2.weight(.heavy))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.accentCyan.opacity(0.15))
                        .foregroundColor(AppTheme.accentCyan)
                        .overlay(
                            Capsule().stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 6) {
                    Text("Aktif Kullanıcı:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: manager.currentUser.avatarSystemImage)
                        Text(manager.currentUser.name)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(manager.currentUser.themeColor)
                    
                    Text("•")
                        .foregroundColor(AppTheme.textMuted)
                    
                    if manager.isSyncing {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Senkronize ediliyor...")
                            .font(.caption)
                            .foregroundColor(AppTheme.textMuted)
                    } else if let date = manager.lastSyncDate {
                        Text("Son eşitleme: \(date, style: .time)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }
            
            Spacer()
            
            // User Switcher Button
            Menu {
                ForEach(CorvusUser.allCases) { u in
                    Button {
                        manager.currentUser = u
                    } label: {
                        HStack {
                            Text(u.name)
                            if manager.currentUser == u {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                    Text("Kullanıcı Değiştir")
                }
                .font(.callout.weight(.medium))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .menuStyle(.borderlessButton)
            
            // Manual Refresh
            Button {
                Task { await manager.syncAll() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(8)
                    .background(AppTheme.surfaceElevated)
                    .overlay(
                        Circle().stroke(AppTheme.border, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Firebase ve Ntfy'den yenile")
        }
        .corvusCard(padding: 18, radius: 16)
    }
    
    // MARK: - Status Grid
    private var systemStatusGrid: some View {
        HStack(spacing: 12) {
            statusBadge(
                title: "Firebase RTDB",
                subtitle: "Canlı Veritabanı",
                icon: "externaldrive.connected.to.line.below.fill",
                status: true,
                color: AppTheme.accentGreen
            )
            
            statusBadge(
                title: "After Effects",
                subtitle: manager.aerenderFound ? "aerender Hazır" : "Yüklü Değil",
                icon: "film.fill",
                status: manager.aerenderFound,
                color: manager.aerenderFound ? AppTheme.accentCyan : AppTheme.accentOrange
            )
            
            statusBadge(
                title: "Photoshop",
                subtitle: manager.photoshopFound ? manager.photoshopAppName : "Yüklü Değil",
                icon: "paintpalette.fill",
                status: manager.photoshopFound,
                color: manager.photoshopFound ? AppTheme.accentPurple : AppTheme.accentOrange
            )
            
            statusBadge(
                title: "API-Sports",
                subtitle: manager.apiKeyFound ? "api.txt Aktif" : "api.txt Eksik",
                icon: "key.fill",
                status: manager.apiKeyFound,
                color: manager.apiKeyFound ? AppTheme.accentCyan : AppTheme.accentRose
            )
        }
    }
    
    private func statusBadge(title: String, subtitle: String, icon: String, status: Bool, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.16))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            .corvusGlow(color: color, radius: 4, opacity: 0.25)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Circle()
                .fill(status ? AppTheme.accentGreen : AppTheme.accentRose)
                .frame(width: 8, height: 8)
                .corvusGlow(color: status ? AppTheme.accentGreen : AppTheme.accentRose, radius: 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı Başlat")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: 12) {
                quickActionButton(
                    title: "Yayın Ekle",
                    subtitle: "Takvime yeni yayın gir",
                    icon: "calendar.badge.plus",
                    color: AppTheme.accentBlue
                ) {
                    showAddBroadcastSheet = true
                }
                
                quickActionButton(
                    title: "Haftalık Program",
                    subtitle: "Render ve Thumbnail",
                    icon: "calendar.badge.clock",
                    color: AppTheme.accentPurple
                ) {
                    selectedTab = "uykusuz_tosba"
                }
                
                quickActionButton(
                    title: "Canlı Maç Sohbeti",
                    subtitle: "API maç listesi & render",
                    icon: "tv.fill",
                    color: AppTheme.accentGreen
                ) {
                    selectedTab = "uykusuz_tosba"
                }
                
                quickActionButton(
                    title: "Memleket Thumbnail",
                    subtitle: "Bölüm no ve renk sihirbazı",
                    icon: "photo.on.rectangle.angled",
                    color: AppTheme.accentOrange
                ) {
                    selectedTab = "photoshop"
                }
            }
        }
    }
    
    private func quickActionButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                .corvusGlow(color: color, radius: 4, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(AppTheme.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Mini Calendar Card
    private var miniCalendarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Gelecek Yayınlar", systemImage: "calendar")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button {
                    selectedTab = "calendar"
                } label: {
                    Text("Tümünü Gör")
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppTheme.accentCyan)
                }
                .buttonStyle(.plain)
            }
            
            if manager.calendarItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Text("Henüz planlanmış yayın yok.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    Button {
                        showAddBroadcastSheet = true
                    } label: {
                        Text("+ İlk Yayını Ekle")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                VStack(spacing: 8) {
                    ForEach(manager.calendarItems.prefix(5)) { item in
                        HStack(spacing: 10) {
                            Text("\(item.index)-)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(AppTheme.textMuted)
                                .frame(width: 24, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .strikethrough(item.isCancelled)
                                
                                HStack(spacing: 6) {
                                    if !item.day.isEmpty {
                                        Text(item.day)
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                    if !item.time.isEmpty {
                                        Text("• \(item.time)")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundColor(AppTheme.accentCyan)
                                    }
                                    if let info = item.info {
                                        Text("(\(info))")
                                            .font(.caption2)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if item.isCancelled {
                                Text("İptal")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.accentRose.opacity(0.18))
                                    .foregroundColor(AppTheme.accentRose)
                                    .clipShape(Capsule())
                            } else if item.isDone {
                                Text("Yapıldı")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.accentGreen.opacity(0.18))
                                    .foregroundColor(AppTheme.accentGreen)
                                    .clipShape(Capsule())
                            } else {
                                Text("Planlandı")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.accentBlue.opacity(0.18))
                                    .foregroundColor(AppTheme.accentBlue)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.surfaceElevated.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .corvusCard(padding: 16, radius: 14)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Mini Chat Card
    private var miniChatCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Ekip Sohbeti", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button {
                    selectedTab = "chat"
                } label: {
                    Text("Sohbete Git")
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppTheme.accentCyan)
                }
                .buttonStyle(.plain)
            }
            
            if manager.chatMessages.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textMuted.opacity(0.6))
                    Text("Henüz sohbet mesajı yok.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                VStack(spacing: 8) {
                    ForEach(manager.chatMessages.suffix(4)) { msg in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(msg.senderColor)
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(msg.sender)
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(msg.senderColor)
                                Text(msg.content)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textPrimary)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.surfaceElevated.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                    }
                }
            }
            
            // Quick reply input
            HStack {
                TextField("Hızlı mesaj gönder...", text: $quickMessageText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        sendQuickMessage()
                    }
                
                Button {
                    sendQuickMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(quickMessageText.trimmingCharacters(in: .whitespaces).isEmpty)
                .controlSize(.small)
            }
        }
        .corvusCard(padding: 16, radius: 14)
        .frame(maxWidth: .infinity)
    }
    
    private func sendQuickMessage() {
        let t = quickMessageText
        quickMessageText = ""
        Task {
            await manager.sendMessage(t)
        }
    }
}

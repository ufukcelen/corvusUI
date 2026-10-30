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
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showAddBroadcastSheet) {
            AddBroadcastSheet()
        }
    }
    
    // MARK: - Header Banner
    private var headerBanner: some View {
        HStack(spacing: 16) {
            Image("CorvusLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: manager.currentUser.themeColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Corvus Otomasyon Stüdyosu")
                        .font(.title2.weight(.bold))
                    
                    Text("v1.5.0")
                        .font(.caption2.weight(.heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 6) {
                    Text("Aktif Kullanıcı:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: manager.currentUser.avatarSystemImage)
                        Text(manager.currentUser.name)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(manager.currentUser.themeColor)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    if manager.isSyncing {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Senkronize ediliyor...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let date = manager.lastSyncDate {
                        Text("Son eşitleme: \(date, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .menuStyle(.borderlessButton)
            
            // Manual Refresh
            Button {
                Task { await manager.syncAll() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.body)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Firebase ve Ntfy'den yenile")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Status Grid
    private var systemStatusGrid: some View {
        HStack(spacing: 12) {
            statusBadge(
                title: "Firebase RTDB",
                subtitle: "Canlı Veritabanı",
                icon: "externaldrive.connected.to.line.below.fill",
                status: true,
                color: .green
            )
            
            statusBadge(
                title: "After Effects",
                subtitle: manager.aerenderFound ? "aerender Hazır" : "Yüklü Değil",
                icon: "film.fill",
                status: manager.aerenderFound,
                color: manager.aerenderFound ? .blue : .orange
            )
            
            statusBadge(
                title: "Photoshop",
                subtitle: manager.photoshopFound ? manager.photoshopAppName : "Yüklü Değil",
                icon: "paintpalette.fill",
                status: manager.photoshopFound,
                color: manager.photoshopFound ? .indigo : .orange
            )
            
            statusBadge(
                title: "API-Sports",
                subtitle: manager.apiKeyFound ? "api.txt Aktif" : "api.txt Eksik",
                icon: "key.fill",
                status: manager.apiKeyFound,
                color: manager.apiKeyFound ? .teal : .red
            )
        }
    }
    
    private func statusBadge(title: String, subtitle: String, icon: String, status: Bool, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Circle()
                .fill(status ? Color.green : Color.red)
                .frame(width: 8, height: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı Başlat")
                .font(.headline)
            
            HStack(spacing: 12) {
                quickActionButton(
                    title: "Yayın Ekle",
                    subtitle: "Takvime yeni yayın gir",
                    icon: "calendar.badge.plus",
                    color: .blue
                ) {
                    showAddBroadcastSheet = true
                }
                
                quickActionButton(
                    title: "Haftalık Program",
                    subtitle: "Render ve Thumbnail",
                    icon: "calendar.badge.clock",
                    color: .purple
                ) {
                    selectedTab = "uykusuz_tosba"
                }
                
                quickActionButton(
                    title: "Canlı Maç Sohbeti",
                    subtitle: "API maç listesi & render",
                    icon: "tv.fill",
                    color: .green
                ) {
                    selectedTab = "uykusuz_tosba"
                }
                
                quickActionButton(
                    title: "Memleket Thumbnail",
                    subtitle: "Bölüm no ve renk sihirbazı",
                    icon: "photo.on.rectangle.angled",
                    color: .orange
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
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.04), lineWidth: 1)
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
                Spacer()
                Button {
                    selectedTab = "calendar"
                } label: {
                    Text("Tümünü Gör")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            
            if manager.calendarItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Henüz planlanmış yayın yok.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                                .foregroundColor(.secondary)
                                .frame(width: 24, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.weight(.medium))
                                    .strikethrough(item.isCancelled)
                                
                                HStack(spacing: 6) {
                                    if !item.day.isEmpty {
                                        Text(item.day)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    if !item.time.isEmpty {
                                        Text("• \(item.time)")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundColor(.primary)
                                    }
                                    if let info = item.info {
                                        Text("(\(info))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if item.isCancelled {
                                Text("İptal")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.15))
                                    .foregroundColor(.red)
                                    .clipShape(Capsule())
                            } else if item.isDone {
                                Text("Yapıldı")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                            } else {
                                Text("Planlandı")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.windowBackgroundColor).opacity(0.6))
                        )
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Mini Chat Card
    private var miniChatCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Ekip Sohbeti", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.headline)
                Spacer()
                Button {
                    selectedTab = "chat"
                } label: {
                    Text("Sohbete Git")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            
            if manager.chatMessages.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Henüz sohbet mesajı yok.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.windowBackgroundColor).opacity(0.6))
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
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                )
        )
    }
    
    private func sendQuickMessage() {
        let t = quickMessageText
        quickMessageText = ""
        Task {
            await manager.sendMessage(t)
        }
    }
}

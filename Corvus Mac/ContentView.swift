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
        } detail: {
            detailContent
        }
        .frame(minWidth: 960, minHeight: 640)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if manager.isRunningTask {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(manager.currentTaskTitle ?? "İşlem Yürütülüyor...")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                
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
                Image("CorvusLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Corvus")
                        .font(.headline.weight(.bold))
                    Text("Otomasyon Stüdyosu")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
            
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
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundColor(.accentColor)
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
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
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
            
            // Bottom Active User Widget
            HStack(spacing: 10) {
                Image(systemName: manager.currentUser.avatarSystemImage)
                    .font(.title3)
                    .foregroundColor(manager.currentUser.themeColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.currentUser.name)
                        .font(.caption.weight(.bold))
                    Text(manager.currentUser == .ufuk ? "1. Kullanıcı" : "2. Kullanıcı")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    manager.currentUser = manager.currentUser.otherUser
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Kullanıcıyı \(manager.currentUser.otherUser.name) olarak değiştir")
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
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

//
//  ConsoleView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI

struct ConsoleView: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var autoScroll = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Konsol & Canlı Çıktılar")
                            .font(.title2.weight(.bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        if manager.isRunningTask {
                            ProgressView()
                                .controlSize(.small)
                            Text("Çalışıyor: \(manager.currentTaskTitle ?? "")")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppTheme.accentCyan)
                        } else {
                            Text("Boşta")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppTheme.surfaceElevated)
                                .foregroundColor(AppTheme.textMuted)
                                .overlay(
                                    Capsule().stroke(AppTheme.border, lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                    }
                    Text("After Effects aerender, Photoshop JSX ve Python otomasyon süreçlerinin anlık konsol logları.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Toggle("Otomatik Kaydır", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                if manager.isRunningTask {
                    Button(role: .destructive) {
                        manager.terminateActiveTask()
                    } label: {
                        Label("Süreci Durdur", systemImage: "stop.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentRose)
                }
                
                Button {
                    manager.clearConsole()
                } label: {
                    Label("Temizle", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(AppTheme.surface)
            
            Divider()
                .overlay(AppTheme.border)
            
            // Terminal Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if manager.consoleLogs.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "terminal")
                                    .font(.system(size: 44))
                                    .foregroundColor(AppTheme.textMuted.opacity(0.4))
                                Text("Henüz çalışan bir komut çıktısı yok.")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                        } else {
                            ForEach(manager.consoleLogs) { log in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("[\(log.timeString)]")
                                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                                        .foregroundColor(AppTheme.textMuted)
                                    
                                    Text(log.text)
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .foregroundColor(
                                            log.isError ? AppTheme.accentRose :
                                            (log.isProgress ? AppTheme.accentCyan :
                                             (log.text.contains("✓") ? AppTheme.accentGreen : AppTheme.textPrimary))
                                        )
                                        .textSelection(.enabled)
                                    
                                    Spacer()
                                }
                                .id(log.id)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(AppTheme.bg)
                .onChange(of: manager.consoleLogs.count) { _, _ in
                    if autoScroll, let last = manager.consoleLogs.last?.id {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
        .background(AppTheme.bg)
    }
}

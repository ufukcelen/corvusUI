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
                        
                        if manager.isRunningTask {
                            ProgressView()
                                .controlSize(.small)
                            Text("Çalışıyor: \(manager.currentTaskTitle ?? "")")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.blue)
                        } else {
                            Text("Boşta")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .foregroundColor(.secondary)
                                .clipShape(Capsule())
                        }
                    }
                    Text("After Effects aerender, Photoshop JSX ve Python otomasyon süreçlerinin anlık konsol logları.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("Otomatik Kaydır", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                
                if manager.isRunningTask {
                    Button(role: .destructive) {
                        manager.terminateActiveTask()
                    } label: {
                        Label("Süreci Durdur", systemImage: "stop.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                
                Button {
                    manager.clearConsole()
                } label: {
                    Label("Temizle", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Terminal Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if manager.consoleLogs.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "terminal")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary.opacity(0.4))
                                Text("Henüz çalışan bir komut çıktısı yok.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                        } else {
                            ForEach(manager.consoleLogs) { log in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("[\(log.timeString)]")
                                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                                        .foregroundColor(.secondary.opacity(0.8))
                                    
                                    Text(log.text)
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .foregroundColor(log.isError ? .red : (log.isProgress ? .yellow : .primary))
                                        .textSelection(.enabled)
                                    
                                    Spacer()
                                }
                                .id(log.id)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color(nsColor: NSColor.textBackgroundColor).opacity(0.85))
                .onChange(of: manager.consoleLogs.count) { _, _ in
                    if autoScroll, let last = manager.consoleLogs.last?.id {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }
}

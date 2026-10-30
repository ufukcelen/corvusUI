//
//  NotificationView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI

struct NotificationView: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var messageText: String = ""
    @State private var priority: Int = 4
    @State private var sendStatus: String?
    @State private var isSending = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Anlık Bildirim Merkezi")
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Ntfy üzerinden \(manager.currentUser.otherUser.name)'in bilgisayarına doğrudan masaüstü ve sesli bildirim gönder.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Active route card
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GÖNDEREN")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(AppTheme.textMuted)
                        HStack(spacing: 6) {
                            Image(systemName: manager.currentUser.avatarSystemImage)
                            Text(manager.currentUser.name)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(manager.currentUser.themeColor)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(AppTheme.textMuted)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ALICI")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(AppTheme.textMuted)
                        HStack(spacing: 6) {
                            Image(systemName: manager.currentUser.otherUser.avatarSystemImage)
                            Text(manager.currentUser.otherUser.name)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(manager.currentUser.otherUser.themeColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("KANAL (TOPIC)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(AppTheme.textMuted)
                        Text(manager.currentUser.sendNotificationTopic)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
                
                // Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bildirim Detayları")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Öncelik Derecesi")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Picker("Öncelik", selection: $priority) {
                            Text("Düşük (1)").tag(1)
                            Text("Normal (3)").tag(3)
                            Text("Yüksek (4) - Sesli").tag(4)
                            Text("Acil (5) - Maksimum").tag(5)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mesaj Metni")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextEditor(text: $messageText)
                            .font(.body)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(AppTheme.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            )
                    }
                    
                    // Quick templates
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hızlı Şablonlar")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppTheme.textMuted)
                        
                        HStack(spacing: 8) {
                            quickTemplateButton("Haftalık program hazırlandı, kontrol et!")
                            quickTemplateButton("Maç duyurusu hazır, yayına girebilirsin.")
                            quickTemplateButton("Takvim güncellendi.")
                        }
                    }
                    
                    HStack {
                        if let status = sendStatus {
                            Text(status)
                                .font(.caption.weight(.medium))
                                .foregroundColor(status.contains("✓") ? AppTheme.accentGreen : AppTheme.accentRose)
                        }
                        
                        Spacer()
                        
                        Button {
                            sendNotification()
                        } label: {
                            HStack(spacing: 8) {
                                if isSending {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                                Text("Bildirimi Gönder")
                            }
                            .frame(minWidth: 160)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                        .controlSize(.regular)
                    }
                }
                .corvusCard(padding: 20, radius: 14)
            }
            .padding(24)
        }
        .background(AppTheme.bg)
    }
    
    private func quickTemplateButton(_ text: String) -> some View {
        Button {
            messageText = text
        } label: {
            Text(text)
                .font(.caption2)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
    
    private func sendNotification() {
        let msg = messageText
        isSending = true
        sendStatus = nil
        
        Task {
            let ok = await manager.sendNotification(message: msg, priority: priority)
            isSending = false
            if ok {
                sendStatus = "✓ Bildirim başarıyla gönderildi!"
                messageText = ""
            } else {
                sendStatus = "✗ Bildirim gönderilirken hata oluştu."
            }
        }
    }
}

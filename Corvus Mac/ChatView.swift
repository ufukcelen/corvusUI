//
//  ChatView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var inputText: String = ""
    @State private var showClearConfirmation = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader
            
            Divider()
                .overlay(AppTheme.border)
            
            // Messages Scroll
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(manager.chatMessages) { msg in
                            messageBubble(for: msg)
                                .id(msg.id)
                        }
                    }
                    .padding(20)
                }
                .background(AppTheme.bg)
                .onChange(of: manager.chatMessages.count) { _, _ in
                    if let lastId = manager.chatMessages.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastId = manager.chatMessages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            
            Divider()
                .overlay(AppTheme.border)
            
            // Input bar
            chatInputBar
        }
        .background(AppTheme.bg)
        .confirmationDialog("Sohbeti temizlemek istediğine emin misin?", isPresented: $showClearConfirmation) {
            Button("Evet, Sohbeti Temizle", role: .destructive) {
                Task { await manager.clearChat() }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu işlem Firebase RTDB ve yerel chat.txt içeriğini sıfırlayacaktır.")
        }
    }
    
    // MARK: - Header
    private var chatHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(manager.currentUser.themeColor.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(manager.currentUser.themeColor)
                    .font(.system(size: 18))
            }
            .corvusGlow(color: manager.currentUser.themeColor, radius: 6, opacity: 0.25)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Canlı Ekip Sohbeti")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    StatusPulseDot(status: true, size: 8)
                }
                
                Text("Ufuk Çelen & Mustafa Yiğit Kızılel & Cem Yıldırım")
                    .font(.caption)
                    .foregroundColor(AppTheme.textMuted)
            }
            
            Spacer()
            
            // User indicator
            HStack(spacing: 6) {
                Text("Mesaj atan:")
                    .font(.caption)
                    .foregroundColor(AppTheme.textMuted)
                
                Text(manager.currentUser.name)
                    .font(.caption.weight(.bold))
                    .foregroundColor(manager.currentUser.themeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(manager.currentUser.themeColor.opacity(0.15))
                    .overlay(
                        Capsule().stroke(manager.currentUser.themeColor.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }
            
            // Actions
            Menu {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Sohbeti Temizle (/temizle)", systemImage: "trash")
                }
                
                Button {
                    Task { await manager.syncChat() }
                } label: {
                    Label("Yenile", systemImage: "arrow.clockwise")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(16)
        .background(AppTheme.surface)
    }
    
    // MARK: - Message Bubble
    private func messageBubble(for msg: ChatMessage) -> some View {
        let isMe = msg.sender.lowercased().contains(manager.currentUser.name.lowercased())
        
        return HStack {
            if isMe { Spacer(minLength: 60) }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(msg.sender)
                        .font(.caption.weight(.bold))
                        .foregroundColor(msg.senderColor)
                }
                
                Text(msg.content)
                    .font(.body)
                    .foregroundColor(isMe ? .white : AppTheme.textPrimary)
                    .textSelection(.enabled)
                
                Text(msg.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(isMe ? .white.opacity(0.7) : AppTheme.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isMe ? AnyShapeStyle(manager.currentUser.themeColor.gradient) : AnyShapeStyle(AppTheme.surfaceElevated))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isMe ? Color.clear : AppTheme.border, lineWidth: 1)
            )
            .corvusGlow(color: isMe ? manager.currentUser.themeColor : Color.clear, radius: 4, opacity: 0.15)
            
            if !isMe { Spacer(minLength: 60) }
        }
    }
    
    // MARK: - Input Bar
    private var chatInputBar: some View {
        HStack(spacing: 12) {
            TextField("Bir mesaj yaz... (Enter gönderir)", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit {
                    submitMessage()
                }
            
            Button {
                submitMessage()
            } label: {
                Label("Gönder", systemImage: "paperplane.fill")
                    .font(.callout.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(AppTheme.surface)
    }
    
    private func submitMessage() {
        let text = inputText
        inputText = ""
        Task {
            await manager.sendMessage(text)
        }
    }
}

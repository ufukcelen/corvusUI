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
            .background(Color(NSColor.textBackgroundColor).opacity(0.3))
            
            Divider()
            
            // Input bar
            chatInputBar
        }
        .background(Color(NSColor.windowBackgroundColor))
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
                    .fill(manager.currentUser.themeColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(manager.currentUser.themeColor)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Canlı Ekip Sohbeti")
                        .font(.headline)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
                
                Text("Ufuk Çelen & Mustafa Yiğit Kızılel & Cem Yıldırım")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // User indicator
            HStack(spacing: 6) {
                Text("Mesaj atan:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(manager.currentUser.name)
                    .font(.caption.weight(.bold))
                    .foregroundColor(manager.currentUser.themeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(manager.currentUser.themeColor.opacity(0.12))
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
            }
            .menuStyle(.borderlessButton)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
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
                    .foregroundColor(isMe ? .white : .primary)
                    .textSelection(.enabled)
                
                Text(msg.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(isMe ? .white.opacity(0.7) : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isMe ? AnyShapeStyle(manager.currentUser.themeColor.gradient) : AnyShapeStyle(Color(NSColor.controlBackgroundColor)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isMe ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
            )
            
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
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func submitMessage() {
        let text = inputText
        inputText = ""
        Task {
            await manager.sendMessage(text)
        }
    }
}

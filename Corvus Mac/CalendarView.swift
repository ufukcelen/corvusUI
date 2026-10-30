//
//  CalendarView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var showAddSheet = false
    @State private var filterStatus: String = "Tümü"
    @State private var showClearAllConfirmation = false
    
    var filteredItems: [CalendarItem] {
        switch filterStatus {
        case "Bekleyen":
            return manager.calendarItems.filter { !$0.isDone && !$0.isCancelled }
        case "Tamamlanan (✅)":
            return manager.calendarItems.filter { $0.isDone }
        case "İptal (❌)":
            return manager.calendarItems.filter { $0.isCancelled }
        default:
            return manager.calendarItems
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Gelecek Yayınlar & Takvim")
                            .font(.title2.weight(.bold))
                        
                        Text("\(manager.calendarItems.count) Yayın")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                    }
                    Text("Firebase Realtime Database ve Ntfy ile senkronize canlı yayın takvimi.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Filter picker
                Picker("Filtre", selection: $filterStatus) {
                    Text("Tümü").tag("Tümü")
                    Text("Bekleyen").tag("Bekleyen")
                    Text("Tamamlanan (✅)").tag("Tamamlanan (✅)")
                    Text("İptal (❌)").tag("İptal (❌)")
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
                
                // Add Broadcast Button
                Button {
                    showAddSheet = true
                } label: {
                    Label("Yayın Ekle", systemImage: "plus")
                        .font(.callout.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                
                // More actions menu
                Menu {
                    Button(role: .destructive) {
                        showClearAllConfirmation = true
                    } label: {
                        Label("Tüm Yayınları Temizle", systemImage: "trash")
                    }
                    
                    Button {
                        Task { await manager.syncCalendar() }
                    } label: {
                        Label("Yenile", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .menuStyle(.borderlessButton)
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            if manager.calendarItems.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredItems) { item in
                        calendarRow(for: item)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.inset)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showAddSheet) {
            AddBroadcastSheet()
        }
        .confirmationDialog("Tüm yayınları silmek istediğine emin misin?", isPresented: $showClearAllConfirmation) {
            Button("Evet, Hepsini Sil", role: .destructive) {
                Task { await manager.clearAllBroadcasts() }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu işlem Firebase RTDB ve yerel takvim dosyasındaki tüm kayıtları silecektir.")
        }
    }
    
    // MARK: - Row View
    private func calendarRow(for item: CalendarItem) -> some View {
        HStack(spacing: 16) {
            // Index badge
            Text("\(item.index)")
                .font(.callout.weight(.bold))
                .foregroundColor(.secondary)
                .frame(width: 28, height: 28)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(Circle())
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(programColor(for: item.title).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: programIcon(for: item.title))
                    .font(.system(size: 20))
                    .foregroundColor(programColor(for: item.title))
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .strikethrough(item.isCancelled)
                    
                    if item.isCancelled {
                        Text("İPTAL EDİLDİ")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                    } else if item.isDone {
                        Text("DUYURULAR YAPILDI")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 12) {
                    if !item.day.isEmpty {
                        Label(item.day, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !item.time.isEmpty {
                        Label(item.time, systemImage: "clock")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    
                    if let info = item.info, !info.isEmpty {
                        Label(info, systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                // Done toggle
                Button {
                    Task { await manager.toggleDone(item: item) }
                } label: {
                    Label(item.isDone ? "Yapıldı" : "Tamamla", systemImage: item.isDone ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(item.isDone ? .green : .secondary)
                .help("Duyurular Yapıldı olarak işaretle")
                
                // Cancel toggle
                Button {
                    Task { await manager.cancelBroadcast(item: item) }
                } label: {
                    Label(item.isCancelled ? "Aktifleştir" : "İptal Et", systemImage: item.isCancelled ? "arrow.uturn.backward" : "xmark.circle")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(item.isCancelled ? .orange : .red)
                .help("Yayını iptal et / geri al")
                
                // Delete
                Button {
                    Task { await manager.deleteBroadcast(item: item) }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Yayını sil")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helpers
    private func programColor(for title: String) -> Color {
        if title.contains("Haftalık") { return .purple }
        if title.contains("Canlı Maç") { return .green }
        if title.contains("Maç Sonu") { return .teal }
        if title.contains("Tek Maç") { return .blue }
        if title.contains("FC27") { return .indigo }
        if title.contains("Memleket") { return .orange }
        if title.contains("Albert") { return .yellow }
        return .cyan
    }
    
    private func programIcon(for title: String) -> String {
        if title.contains("Haftalık") { return "calendar.badge.clock" }
        if title.contains("Canlı Maç") { return "tv.fill" }
        if title.contains("Maç Sonu") { return "sportscourt.fill" }
        if title.contains("Tek Maç") { return "ticket.fill" }
        if title.contains("FC27") { return "gamecontroller.fill" }
        if title.contains("Memleket") { return "waveform" }
        if title.contains("Albert") { return "mic.fill" }
        return "play.rectangle.fill"
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Kayıtlı Yayın Bulunamadı")
                .font(.title3.weight(.semibold))
            
            Text("Yeni bir yayın ekleyerek takvimi doldurabilirsin.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                showAddSheet = true
            } label: {
                Label("Yeni Yayın Ekle", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Add Broadcast Sheet
struct AddBroadcastSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager = CorvusManager.shared
    
    @State private var selectedProgram: String = "Haftalık Program"
    @State private var customProgramName: String = ""
    @State private var selectedDay: String = ""
    @State private var timeString: String = "21:00"
    @State private var infoNote: String = ""
    
    var dynamicDays: [(label: String, value: String)] {
        manager.getDynamicNext7Days()
    }
    
    var effectiveProgram: String {
        if selectedProgram == "Özel..." {
            return customProgramName.trimmingCharacters(in: .whitespaces)
        }
        return selectedProgram
    }
    
    var isFormValid: Bool {
        !effectiveProgram.isEmpty && !selectedDay.isEmpty && !timeString.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Yeni Yayın Planla")
                    .font(.title2.weight(.bold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Program selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Program Türü")
                    .font(.headline)
                
                Picker("Program", selection: $selectedProgram) {
                    ForEach(ProgramChoice.allPrograms) { p in
                        Text(p.title).tag(p.title)
                    }
                    Divider()
                    Text("Özel...").tag("Özel...")
                }
                .pickerStyle(.menu)
                .onChange(of: selectedProgram) { _, newValue in
                    if let match = ProgramChoice.allPrograms.first(where: { $0.title == newValue }) {
                        timeString = match.defaultTime
                    }
                }
                
                if selectedProgram == "Özel..." {
                    TextField("Özel Program Adı", text: $customProgramName)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // Day selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Yayın Günü (Önümüzdeki 7 Gün)")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(dynamicDays, id: \.value) { item in
                        Button {
                            selectedDay = item.value
                        } label: {
                            Text(item.label)
                                .font(.caption.weight(selectedDay == item.value ? .bold : .regular))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedDay == item.value ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(selectedDay == item.value ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Time selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Yayın Saati (HH:MM)")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    TextField("21:00", text: $timeString)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    
                    // Quick time buttons
                    ForEach(["19:00", "20:00", "21:00", "22:00", "23:00"], id: \.self) { t in
                        Button {
                            timeString = t
                        } label: {
                            Text(t)
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            
            // Optional info note
            VStack(alignment: .leading, spacing: 8) {
                Text("Bilgi Notu (İsteğe bağlı)")
                    .font(.headline)
                
                TextField("Örn: Derbi Özel / Konuklu Yayın", text: $infoNote)
                    .textFieldStyle(.roundedBorder)
            }
            
            Spacer()
            
            // Action Buttons
            HStack {
                Button("İptal") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Takvime Ekle") {
                    Task {
                        await manager.addBroadcast(
                            program: effectiveProgram,
                            day: selectedDay,
                            time: timeString,
                            info: infoNote.isEmpty ? nil : infoNote
                        )
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 580, height: 480)
        .onAppear {
            if let first = dynamicDays.first {
                selectedDay = first.value
            }
        }
    }
}

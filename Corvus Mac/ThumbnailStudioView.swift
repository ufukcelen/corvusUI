//
//  ThumbnailStudioView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI

struct ThumbnailStudioView: View {
    @ObservedObject var manager = CorvusManager.shared
    
    @State private var memleketEpisodeNo: String = ""
    @State private var canliMacId: String = ""
    @State private var canliMacDate: String = ""
    
    // Dynamic Match Selector State
    @State private var isLoadingMatches = false
    @State private var matches: [MatchItem] = []
    @State private var selectedMatch: MatchItem? = nil
    @State private var selectedLeagueId: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.accentPurple.opacity(0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 26))
                            .foregroundColor(AppTheme.accentPurple)
                    }
                    .corvusGlow(color: AppTheme.accentPurple, radius: 8, opacity: 0.25)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Photoshop Thumbnail Merkezi")
                            .font(.title2.weight(.bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Adobe Photoshop JSX otomasyonu ve CorvusCloud ile YouTube kapak görselleri üretimi.")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Photoshop Status Badge
                    HStack(spacing: 8) {
                        StatusPulseDot(status: manager.photoshopFound, size: 8)
                        
                        Text(manager.photoshopFound ? manager.photoshopAppName : "Photoshop Bulunamadı")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.surfaceElevated)
                    .overlay(
                        Capsule().stroke(AppTheme.border, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .corvusCard(padding: 20, radius: 16)
                
                // Templates Grid
                VStack(spacing: 20) {
                    // 1. Memleket
                    thumbnailCard(
                        title: "1. Filtresiz Memleket Havası",
                        templateName: "memleketYatay.psd (CorvusCloud)",
                        outputName: "memleket{no}.jpg",
                        icon: "waveform",
                        color: AppTheme.accentOrange,
                        description: "Kapak görselinde bölüm numarasını (#..) günceller, rastgele dinamik renk kombinasyonu üretir ve masaüstünü kirletmeden sadece nihai JPG görselini kaydeder."
                    ) {
                        HStack(spacing: 12) {
                            TextField("Bölüm No (Örn: 24)", text: $memleketEpisodeNo)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 160)
                            
                            Button {
                                let args = ["memleket_thumbnail", "--bolum", memleketEpisodeNo]
                                manager.runBridgeTask(arguments: args, title: "Memleket Thumbnail #\(memleketEpisodeNo)")
                            } label: {
                                Label("Oluştur", systemImage: "sparkles")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(memleketEpisodeNo.trimmingCharacters(in: .whitespaces).isEmpty || manager.isRunningTask)
                        }
                    }
                    
                    // 2. Canlı Maç (Akıllı Maç Seçimli)
                    thumbnailCard(
                        title: "2. Canlı Maç Sohbetleri",
                        templateName: "canlimac.psd (CorvusCloud)",
                        outputName: "canlimacyatay.jpg",
                        icon: "tv.fill",
                        color: AppTheme.accentGreen,
                        description: "Tarihe göre maçları listeler. Takımı seçtiğinizde Maç ID otomatik atanır, turnuva logosu ve takım armaları Smart Object içine yerleştirilir."
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            // Date & League row
                            HStack(spacing: 12) {
                                TextField("Tarih (YYYY-MM-DD)", text: $canliMacDate)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 150)
                                
                                Picker("Lig / Turnuva", selection: $selectedLeagueId) {
                                    Text("Hepsi (5 Lig)").tag("")
                                    Text("Süper Lig").tag("203")
                                    Text("Şampiyonlar Ligi").tag("2")
                                    Text("Europa Ligi").tag("3")
                                    Text("Konferans Ligi").tag("848")
                                    Text("Uluslar Ligi").tag("5")
                                }
                                .frame(width: 170)
                                
                                Button {
                                    loadMatches()
                                } label: {
                                    if isLoadingMatches {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Label("Maçları Getir", systemImage: "arrow.clockwise")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(isLoadingMatches || manager.isRunningTask)
                            }
                            
                            // Matches horizontal scroll or list
                            if isLoadingMatches {
                                HStack(spacing: 8) {
                                    ProgressView().controlSize(.small)
                                    Text("Karşılaşmalar API'den çekiliyor...").font(.caption).foregroundColor(AppTheme.textSecondary)
                                }
                                .padding(.vertical, 4)
                            } else if !matches.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(matches) { m in
                                            matchChipView(m)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            
                            // Selected match summary & action
                            HStack(spacing: 14) {
                                if let sel = selectedMatch {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.accentGreen)
                                        Text("\(sel.home) vs \(sel.away) (\(sel.leagueName))")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.accentGreen.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    TextField("Manuel Maç ID", text: $canliMacId)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 130)
                                }
                                
                                Button {
                                    let activeId = selectedMatch != nil ? "\(selectedMatch!.id)" : canliMacId
                                    let args = ["canli_thumbnail", "--mac_id", activeId, "--tarih", canliMacDate]
                                    let title = selectedMatch != nil ? "Canlı Maç Thumbnail: \(selectedMatch!.home) vs \(selectedMatch!.away)" : "Canlı Maç Thumbnail: \(activeId)"
                                    manager.runBridgeTask(arguments: args, title: title)
                                } label: {
                                    Label("Kapağı Oluştur", systemImage: "sparkles")
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled((selectedMatch == nil && canliMacId.trimmingCharacters(in: .whitespaces).isEmpty) || manager.isRunningTask)
                            }
                        }
                    }
                    
                    // 3. Haftalık Program
                    thumbnailCard(
                        title: "3. Haftalık Program",
                        templateName: "haftalık.psd",
                        outputName: "haftalik_program.jpg",
                        icon: "calendar.badge.clock",
                        color: AppTheme.accentPurple,
                        description: "haftalık.psd şablonunu açar ve en yüksek 12 kalitesinde Masaüstüne kaydeder."
                    ) {
                        Button {
                            manager.runBridgeTask(arguments: ["haftalik_thumbnail"], title: "Haftalık Program Thumbnail")
                        } label: {
                            Label("Tek Tıkla Oluştur", systemImage: "sparkles")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(manager.isRunningTask)
                    }
                }
            }
            .padding(24)
        }
        .background(AppTheme.bg)
        .onAppear {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            canliMacDate = f.string(from: Date())
            loadMatches()
        }
    }
    
    // MARK: - Match Chip
    private func matchChipView(_ m: MatchItem) -> some View {
        let isSelected = selectedMatch?.id == m.id
        return Button {
            selectedMatch = m
            canliMacId = "\(m.id)"
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(m.home) - \(m.away)")
                        .font(.caption.weight(isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? AppTheme.accentGreen : AppTheme.textPrimary)
                    HStack(spacing: 4) {
                        Text(m.leagueName)
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textMuted)
                        if !m.timeStr.isEmpty {
                            Text("• \(m.timeStr)")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.accentOrange)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppTheme.accentGreen.opacity(0.18) : AppTheme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? AppTheme.accentGreen : AppTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Load Matches via Bridge
    private func loadMatches() {
        isLoadingMatches = true
        matches = []
        selectedMatch = nil
        
        let bridgeCandidates = [
            Bundle.main.path(forResource: "corvus_bridge", ofType: "py"),
            (manager.corvusProjectPath as NSString).appendingPathComponent("corvus_bridge.py"),
            (manager.corvusProjectPath as NSString).deletingLastPathComponent.appending("/Corvus Mac/corvus_bridge.py"),
            "/Users/ufukcelen/Desktop/Dev/CorvusUI/Corvus Mac/Corvus Mac/corvus_bridge.py"
        ]
        
        let bridgeScript = bridgeCandidates.compactMap { $0 }.first { FileManager.default.fileExists(atPath: $0) }
            ?? "/Users/ufukcelen/Desktop/Dev/CorvusUI/Corvus Mac/Corvus Mac/corvus_bridge.py"
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: manager.pythonExecutablePath)
        
        var args = [bridgeScript, "--dir", manager.corvusProjectPath, "get_matches", "--tarih", canliMacDate]
        if !selectedLeagueId.isEmpty {
            args.append(contentsOf: ["--league", selectedLeagueId])
        }
        proc.arguments = args
        
        let pipe = Pipe()
        proc.standardOutput = pipe
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? proc.run()
            proc.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let rawString = String(data: data, encoding: .utf8) {
                if let openBracket = rawString.firstIndex(of: "["),
                   let closeBracket = rawString.lastIndex(of: "]"),
                   openBracket <= closeBracket {
                    let jsonSub = String(rawString[openBracket...closeBracket])
                    if let jsonData = jsonSub.data(using: .utf8),
                       let list = try? JSONDecoder().decode([MatchItem].self, from: jsonData) {
                        DispatchQueue.main.async {
                            self.matches = list
                            self.isLoadingMatches = false
                        }
                        return
                    }
                }
            }
            DispatchQueue.main.async {
                self.isLoadingMatches = false
            }
        }
    }
    
    private func thumbnailCard<Content: View>(
        title: String,
        templateName: String,
        outputName: String,
        icon: String,
        color: Color,
        description: String,
        @ViewBuilder controls: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                .corvusGlow(color: color, radius: 4, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    HStack(spacing: 8) {
                        Text("Şablon: \(templateName)")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(AppTheme.textMuted)
                        Text("•")
                            .foregroundColor(AppTheme.textMuted)
                        Text("Çıktı: ~/Desktop/\(outputName)")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            Divider()
                .overlay(AppTheme.border)
            
            controls()
        }
        .corvusCard(padding: 20, radius: 14)
    }
}

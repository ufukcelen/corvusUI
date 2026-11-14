//
//  UykusuzTosbaView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI

struct UykusuzTosbaView: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var selectedSubProgram: String = "haftalik"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Sub-nav
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uykusuz Tosba Stüdyosu")
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Futbol, Canlı Maç, FC27 Kariyer ve Tek Maçtan Yatanlar duyuru otomasyonları.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(AppTheme.surface)
            
            // Program Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    subProgramTab(id: "haftalik", title: "Haftalık Program", icon: "calendar.badge.clock")
                    subProgramTab(id: "canli_mac", title: "Canlı Maç Sohbetleri", icon: "tv.fill")
                    subProgramTab(id: "mac_sonu", title: "Maç Sonu", icon: "sportscourt.fill")
                    subProgramTab(id: "canli_thumb", title: "Maç Thumbnail", icon: "photo.stack")
                    subProgramTab(id: "tek_mac", title: "Tek Maçtan Yatanlar", icon: "ticket.fill")
                    subProgramTab(id: "fc_kariyer", title: "FC27 Kariyer", icon: "gamecontroller.fill")
                    subProgramTab(id: "tosba_lojistik", title: "Tosba Lojistik", icon: "truck.box.fill")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .background(AppTheme.surface.opacity(0.6))
            
            Divider()
                .overlay(AppTheme.border)
            
            // Subprogram Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedSubProgram {
                    case "haftalik":
                        HaftalikProgramCard()
                    case "canli_mac":
                        CanliMacProgramCard(isMacSonu: false)
                    case "mac_sonu":
                        CanliMacProgramCard(isMacSonu: true)
                    case "canli_thumb":
                        CanliThumbStandaloneCard()
                    case "tek_mac":
                        TekMacCard()
                    case "fc_kariyer":
                        FcKariyerCard()
                    case "tosba_lojistik":
                        TosbaLojistikCard()
                    default:
                        EmptyView()
                    }
                }
                .padding(24)
            }
        }
        .background(AppTheme.bg)
    }
    
    private func subProgramTab(id: String, title: String, icon: String) -> some View {
        Button {
            selectedSubProgram = id
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.callout.weight(selectedSubProgram == id ? .semibold : .regular))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selectedSubProgram == id ? AppTheme.accentCyan : AppTheme.surfaceElevated)
            .foregroundColor(selectedSubProgram == id ? .black : AppTheme.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedSubProgram == id ? AppTheme.accentCyan : AppTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 1. Haftalık Program Card
struct HaftalikProgramCard: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var broadcastHour: String = "21:00"
    @State private var runRender: Bool = true
    @State private var runThumbnail: Bool = true
    @State private var kadirVar: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accentPurple.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentPurple)
                }
                .corvusGlow(color: AppTheme.accentPurple, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Haftalık Program Duyuru Sihirbazı")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Süper Lig çerçeve ve arka planlarını yükler, After Effects ile Haftalik_Program_Duyurusu.mp4 render eder ve SEO dosyası üretir.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Divider()
                .overlay(AppTheme.border)
            
            // Parameters
            VStack(alignment: .leading, spacing: 14) {
                Text("Parametreler")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yayın Saati (HH:MM)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("21:00", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Otomasyon Seçenekleri")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        HStack(spacing: 16) {
                            Toggle("After Effects Render Başlat", isOn: $runRender)
                            Toggle("Photoshop Thumbnail (haftalık.psd) Üret", isOn: $runThumbnail)
                        }
                    }
                }
            }
            
            // Action button
            HStack {
                Spacer()
                Button {
                    var args = ["haftalik_program", "--saat", broadcastHour]
                    if runRender { args.append("--render") }
                    if runThumbnail { args.append("--thumbnail") }
                    
                    manager.runBridgeTask(arguments: args, title: "Haftalık Program Hazırlığı (\(broadcastHour))")
                } label: {
                    Label("Haftalık Programı Başlat", systemImage: "play.fill")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(manager.isRunningTask)
            }
        }
        .corvusCard(padding: 24, radius: 16)
    }
}

// MARK: - 2 & 3. Canlı Maç & Maç Sonu Card
struct CanliMacProgramCard: View {
    let isMacSonu: Bool
    @ObservedObject var manager = CorvusManager.shared
    
    @State private var matchDate: String = ""
    @State private var selectedLeagueId: String = ""
    @State private var matches: [MatchItem] = []
    @State private var isLoadingMatches = false
    @State private var selectedMatch: MatchItem? = nil
    @State private var broadcastHour: String = ""
    @State private var runRender: Bool = true
    @State private var runThumbnail: Bool = true
    @State private var kadirVar: Bool = true
    
    var themeAccent: Color {
        isMacSonu ? AppTheme.accentCyan : AppTheme.accentGreen
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeAccent.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: isMacSonu ? "sportscourt.fill" : "tv.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeAccent)
                }
                .corvusGlow(color: themeAccent, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isMacSonu ? "Maç Sonu Sohbeti" : "Canlı Maç Sohbetleri")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("API-Sports üzerinden karşılaşma verilerini ve logoları çeker, optik ağırlık hesaplar ve AE duyuru videosu üretir.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Divider()
                .overlay(AppTheme.border)
            
            // Step 1: Date & League
            VStack(alignment: .leading, spacing: 12) {
                Text("1. Tarih ve Turnuva Seçimi")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack(spacing: 14) {
                    TextField("YYYY-MM-DD (Örn: 2026-10-30)", text: $matchDate)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                    
                    Picker("Lig / Turnuva", selection: $selectedLeagueId) {
                        Text("Hepsi (5 Lig)").tag("")
                        Text("Süper Lig").tag("203")
                        Text("Şampiyonlar Ligi").tag("2")
                        Text("Europa Ligi").tag("3")
                        Text("Konferans Ligi").tag("848")
                        Text("Uluslar Ligi").tag("5")
                    }
                    .frame(width: 180)
                    
                    Button {
                        loadMatches()
                    } label: {
                        HStack(spacing: 6) {
                            if isLoadingMatches {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text("Maçları Getir")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoadingMatches || matchDate.isEmpty)
                }
            }
            
            // Step 2: Match list
            if !matches.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("2. Karşılaşma Seçin (\(matches.count) Maç Bulundu)")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(matches) { m in
                                matchRow(m)
                            }
                        }
                    }
                    .frame(maxHeight: 220)
                }
            }
            
            // Step 3: Execution Settings
            if let sel = selectedMatch {
                VStack(alignment: .leading, spacing: 14) {
                    Text("3. Seçilen Karşılaşma ve Ayarlar")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 16) {
                        Text("\(sel.home) vs \(sel.away) (\(sel.leagueName))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(themeAccent)
                        
                        TextField("Yayın Saati", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Toggle("AE Render", isOn: $runRender)
                        Toggle("Photoshop Thumbnail", isOn: $runThumbnail)
                        
                        Divider().frame(height: 18)
                        
                        Toggle(isOn: $kadirVar) {
                            HStack(spacing: 4) {
                                Image(systemName: kadirVar ? "person.2.fill" : "person.fill")
                                    .foregroundColor(kadirVar ? AppTheme.accentGreen : AppTheme.accentOrange)
                                Text(kadirVar ? "Kadir Var" : "Kadir Yok (cy)")
                                    .fontWeight(.medium)
                            }
                        }
                        .toggleStyle(.button)
                        .tint(kadirVar ? AppTheme.accentGreen.opacity(0.3) : AppTheme.accentOrange.opacity(0.3))
                    }
                    
                    HStack {
                        Spacer()
                        Button {
                            var args = [
                                "canli_mac",
                                "--tarih", matchDate,
                                "--mac_id", "\(sel.id)",
                                "--saat", broadcastHour
                            ]
                            if isMacSonu { args.append("--mac_sonu") }
                            if runRender { args.append("--render") }
                            if runThumbnail { args.append("--thumbnail") }
                            if !kadirVar { args.append("--kadir-yok") }
                            
                            let title = "\(isMacSonu ? "Maç Sonu" : "Canlı Maç"): \(sel.home) - \(sel.away)"
                            manager.runBridgeTask(arguments: args, title: title)
                        } label: {
                            Label("Otomasyonu Başlat", systemImage: "play.fill")
                                .font(.callout.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(manager.isRunningTask)
                    }
                }
            }
        }
        .corvusCard(padding: 24, radius: 16)
        .onAppear {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            matchDate = formatter.string(from: Date())
            loadMatches()
        }
    }
    
    private func matchRow(_ m: MatchItem) -> some View {
        let isSelected = selectedMatch?.id == m.id
        return Button {
            selectedMatch = m
            broadcastHour = m.timeStr
        } label: {
            HStack(spacing: 14) {
                Text(m.timeStr)
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppTheme.textMuted)
                    .frame(width: 48, alignment: .leading)
                
                HStack(spacing: 8) {
                    Text(m.home)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                    Text("vs")
                        .foregroundColor(AppTheme.textMuted)
                    Text(m.away)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Spacer()
                
                Text(m.leagueName)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.surfaceElevated)
                    .clipShape(Capsule())
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeAccent)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? themeAccent.opacity(0.18) : AppTheme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? themeAccent : AppTheme.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
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
        
        var args = [bridgeScript, "--dir", manager.corvusProjectPath, "get_matches", "--tarih", matchDate]
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
                       let parsed = try? JSONDecoder().decode([MatchItem].self, from: jsonData) {
                        DispatchQueue.main.async {
                            self.matches = parsed
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
}

// MARK: - 4. Canlı Maç Standalone Thumbnail Card
struct CanliThumbStandaloneCard: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var matchId: String = ""
    @State private var matchDate: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accentCyan.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: "photo.stack")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentCyan)
                }
                .corvusGlow(color: AppTheme.accentCyan, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Canlı Maç Thumbnail Stüdyosu (Hızlı Üretim)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Sadece Photoshop PSD şablonuna logo ve isimleri yerleştirip PNG çıktı üretir, AE render yapmaz.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Divider()
                .overlay(AppTheme.border)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Maç ID (API-Sports)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.textSecondary)
                    TextField("Örn: 123456", text: $matchId)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tarih (YYYY-MM-DD)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.textSecondary)
                    TextField("2026-10-30", text: $matchDate)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                }
            }
            
            HStack {
                Spacer()
                Button {
                    let args = ["canli_thumbnail", "--mac_id", matchId, "--tarih", matchDate]
                    manager.runBridgeTask(arguments: args, title: "Canlı Maç Thumbnail (ID: \(matchId))")
                } label: {
                    Label("Thumbnail Oluştur", systemImage: "sparkles")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(matchId.isEmpty || manager.isRunningTask)
            }
        }
        .corvusCard(padding: 24, radius: 16)
        .onAppear {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            matchDate = f.string(from: Date())
        }
    }
}

// MARK: - 5. Tek Maçtan Yatanlar Card
struct TekMacCard: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var broadcastHour: String = "21:00"
    @State private var kayhanVar: Bool = true
    @State private var teamTags: String = "Fenerbahçe, Galatasaray, Beşiktaş"
    @State private var runRender: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accentBlue.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentBlue)
                }
                .corvusGlow(color: AppTheme.accentBlue, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tek Maçtan Yatanlar Duyuru Otomasyonu")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("tmy.json dosyasını günceller, rastgele tmyGorsel seçer, hashtag'leri üretir ve After Effects tmySahne render eder.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Divider()
                .overlay(AppTheme.border)
            
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yayın Saati")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        TextField("21:00", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kayhan Durumu")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Toggle("Kayhan Var (Hashtag #kayhan)", isOn: $kayhanVar)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Render")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Toggle("AE Render Başlat", isOn: $runRender)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bahsedilecek Takım Etiketleri (Virgülle ayırın)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.textSecondary)
                    TextField("Fenerbahçe, Galatasaray, Trabzonspor", text: $teamTags)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            HStack {
                Spacer()
                Button {
                    var args = [
                        "tek_mac",
                        "--saat", broadcastHour,
                        "--kayhan", kayhanVar ? "1" : "0",
                        "--etiketler", teamTags
                    ]
                    if runRender { args.append("--render") }
                    manager.runBridgeTask(arguments: args, title: "Tek Maçtan Yatanlar (\(broadcastHour))")
                } label: {
                    Label("Duyuruyu Başlat", systemImage: "play.fill")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(manager.isRunningTask)
            }
        }
        .corvusCard(padding: 24, radius: 16)
    }
}

// MARK: - 6. FC27 Kariyer Card
struct FcKariyerCard: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var teamName: String = "Feyenoord"
    @State private var runRender: Bool = true
    @State private var isZamanli: Bool = false
    @State private var broadcastTime: String = "22:45"
    
    let popularTeams = ["Feyenoord", "Ajax", "PSV", "Roma", "Lazio", "Dortmund", "Porto", "Benfica"]
    let quickTimes = ["20:00", "20:30", "21:00", "22:00", "22:45", "23:00"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.accentPurple.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentPurple)
                }
                .corvusGlow(color: AppTheme.accentPurple, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("FC27 Kariyer Duyuru Otomasyonu")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(isZamanli
                        ? "Zamanlı yayın: fc27saat.json dosyasını günceller, fc27zaman comp renderını alır ve fc27buaksam.txt metnini üretir."
                        : "Canlı yayın: Takım logosunu indirip 203x195 boyutlandırır ve fc27sahne After Effects renderını yürütür.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Divider()
                .overlay(AppTheme.border)
            
            // Mod Seçimi
            VStack(alignment: .leading, spacing: 10) {
                Text("Duyuru Modu")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Picker("Duyuru Modu", selection: $isZamanli) {
                    Text("🔴 Şimdi Yayında (Canlı)").tag(false)
                    Text("⏰ Yayın Saati Ver (Bu Akşam)").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                Text("Kariyer Takımı")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack(spacing: 12) {
                    TextField("Takım Adı (Örn: Feyenoord)", text: $teamName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                    
                    Toggle("AE Render Başlat", isOn: $runRender)
                }
                
                // Popular suggestions chips
                HStack(spacing: 8) {
                    Text("Öneriler:")
                        .font(.caption)
                        .foregroundColor(AppTheme.textMuted)
                    
                    ForEach(popularTeams, id: \.self) { t in
                        Button {
                            teamName = t
                        } label: {
                            Text(t)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(teamName == t ? AppTheme.accentPurple : AppTheme.surfaceElevated)
                                .foregroundColor(teamName == t ? .white : AppTheme.textPrimary)
                                .overlay(
                                    Capsule().stroke(teamName == t ? AppTheme.accentPurple : AppTheme.border, lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if isZamanli {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Yayın Saati")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 12) {
                        TextField("Yayın Saati (Örn: 22:45)", text: $broadcastTime)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 160)
                        
                        Text("Hızlı Seçim:")
                            .font(.caption)
                            .foregroundColor(AppTheme.textMuted)
                        
                        ForEach(quickTimes, id: \.self) { time in
                            Button {
                                broadcastTime = time
                            } label: {
                                Text(time)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(broadcastTime == time ? AppTheme.accentAmber : AppTheme.surfaceElevated)
                                    .foregroundColor(broadcastTime == time ? .black : AppTheme.textPrimary)
                                    .overlay(
                                        Capsule().stroke(broadcastTime == time ? AppTheme.accentAmber : AppTheme.border, lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            HStack {
                Spacer()
                Button {
                    var args = ["fc_kariyer", "--takim", teamName]
                    if isZamanli {
                        let cleanTime = broadcastTime.trimmingCharacters(in: .whitespaces)
                        if !cleanTime.isEmpty {
                            args.append(contentsOf: ["--saat", cleanTime])
                        }
                    }
                    if runRender { args.append("--render") }
                    let titleMode = isZamanli ? "Zamanlı (\(broadcastTime))" : "Şimdi Yayında"
                    manager.runBridgeTask(arguments: args, title: "FC27 Kariyer: \(teamName) [\(titleMode)]")
                } label: {
                    Label(isZamanli ? "Zamanlı Duyuruyu Başlat" : "Duyuruyu Başlat", systemImage: "play.fill")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(teamName.trimmingCharacters(in: .whitespaces).isEmpty || (isZamanli && broadcastTime.trimmingCharacters(in: .whitespaces).isEmpty) || manager.isRunningTask)
            }
        }
        .corvusCard(padding: 24, radius: 16)
    }
}

// MARK: - 7. Tosba Lojistik Card
struct TosbaLojistikCard: View {
    @ObservedObject var manager = CorvusManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentCyan.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 38))
                    .foregroundColor(AppTheme.accentCyan)
            }
            .corvusGlow(color: AppTheme.accentCyan, radius: 10, opacity: 0.2)
            
            VStack(spacing: 8) {
                Text("Tosba Lojistik Otomasyonu")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Euro Truck Simulator 2 ve ortak konvoy yayınları için yakında eklenecektir.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Text("Geliştirme Aşamasında")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.surfaceElevated)
                .foregroundColor(AppTheme.textMuted)
                .overlay(
                    Capsule().stroke(AppTheme.border, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .corvusCard(padding: 40, radius: 16)
    }
}

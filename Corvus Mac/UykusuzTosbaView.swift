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
                    Text("Futbol, Canlı Maç, FC27 Kariyer ve Tek Maçtan Yatanlar duyuru otomasyonları.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            
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
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
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
        .background(Color(NSColor.windowBackgroundColor))
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
            .background(selectedSubProgram == id ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .foregroundColor(selectedSubProgram == id ? .white : .primary)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Haftalık Program Duyuru Sihirbazı")
                        .font(.title3.weight(.bold))
                    Text("Süper Lig çerçeve ve arka planlarını yükler, After Effects ile Haftalik_Program_Duyurusu.mp4 render eder ve SEO dosyası üretir.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Parameters
            VStack(alignment: .leading, spacing: 14) {
                Text("Parametreler")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yayın Saati (HH:MM)")
                            .font(.subheadline.weight(.medium))
                        
                        TextField("21:00", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Otomasyon Seçenekleri")
                            .font(.subheadline.weight(.medium))
                        
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill((isMacSonu ? Color.teal : Color.green).opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: isMacSonu ? "sportscourt.fill" : "tv.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isMacSonu ? .teal : .green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isMacSonu ? "Maç Sonu Sohbeti" : "Canlı Maç Sohbetleri")
                        .font(.title3.weight(.bold))
                    Text("API-Sports üzerinden karşılaşma verilerini ve logoları çeker, optik ağırlık hesaplar ve AE duyuru videosu üretir.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Step 1: Date & League
            VStack(alignment: .leading, spacing: 12) {
                Text("1. Tarih ve Turnuva Seçimi")
                    .font(.headline)
                
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
                    
                    HStack(spacing: 16) {
                        Text("\(sel.home) vs \(sel.away) (\(sel.leagueName))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.accentColor)
                        
                        TextField("Yayın Saati", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Toggle("AE Render", isOn: $runRender)
                        Toggle("Photoshop Thumbnail", isOn: $runThumbnail)
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
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
                    .foregroundColor(.secondary)
                    .frame(width: 48, alignment: .leading)
                
                HStack(spacing: 8) {
                    Text(m.home)
                        .fontWeight(.semibold)
                    Text("vs")
                        .foregroundColor(.secondary)
                    Text(m.away)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text(m.leagueName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Capsule())
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(NSColor.windowBackgroundColor).opacity(0.6))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func loadMatches() {
        isLoadingMatches = true
        matches = []
        selectedMatch = nil
        
        let bridgeScript = "/Users/ufukcelen/Desktop/Dev/CorvusUI/Corvus Mac/Corvus Mac/corvus_bridge.py"
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
            if let decoded = try? JSONDecoder().decode([MatchItem].self, from: data) {
                DispatchQueue.main.async {
                    self.matches = decoded
                    self.isLoadingMatches = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoadingMatches = false
                }
            }
        }
    }
}

// MARK: - 4. Canlı Thumb Standalone Card
struct CanliThumbStandaloneCard: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var matchId: String = ""
    @State private var matchDate: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "photo.stack")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Canlı Maç Thumbnail Sihirbazı (Photoshop)")
                        .font(.title3.weight(.bold))
                    Text("canlimac.psd şablonunu açar, turnuva katmanını açar ve logoları optik ağırlıklarına göre Smart Object içine yerleştirir.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {
                Text("Parametreler")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    TextField("Tarih (YYYY-MM-DD)", text: $matchDate)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                    
                    TextField("Maç ID (API-Sports)", text: $matchId)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
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
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tek Maçtan Yatanlar Duyuru Otomasyonu")
                        .font(.title3.weight(.bold))
                    Text("tmy.json dosyasını günceller, rastgele tmyGorsel seçer, hashtag'leri üretir ve After Effects tmySahne render eder.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yayın Saati")
                            .font(.subheadline.weight(.medium))
                        TextField("21:00", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kayhan Durumu")
                            .font(.subheadline.weight(.medium))
                        Toggle("Kayhan Var (Hashtag #kayhan)", isOn: $kayhanVar)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Render")
                            .font(.subheadline.weight(.medium))
                        Toggle("AE Render Başlat", isOn: $runRender)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bahsedilecek Takım Etiketleri (Virgülle ayırın)")
                        .font(.subheadline.weight(.medium))
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - 6. FC27 Kariyer Card
struct FcKariyerCard: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var teamName: String = "Feyenoord"
    @State private var runRender: Bool = true
    
    let popularTeams = ["Feyenoord", "Ajax", "PSV", "Roma", "Lazio", "Dortmund", "Porto", "Benfica"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.indigo)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("FC27 Kariyer Duyuru Otomasyonu")
                        .font(.title3.weight(.bold))
                    Text("kariyer_takim.json üzerinden takım logosunu indirip 203x195 boyutlandırır ve fc27sahne After Effects renderını yürütür.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Kariyer Takımı")
                        .font(.subheadline.weight(.medium))
                    TextField("Takım Adı (Örn: Feyenoord)", text: $teamName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 320)
                }
                
                // Quick suggestions
                HStack(spacing: 8) {
                    Text("Popüler:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(popularTeams, id: \.self) { t in
                        Button {
                            teamName = t
                        } label: {
                            Text(t)
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                
                Toggle("AE Render Başlat (fc27Duyuru.mp4)", isOn: $runRender)
            }
            
            HStack {
                Spacer()
                Button {
                    var args = ["fc_kariyer", "--takim", teamName]
                    if runRender { args.append("--render") }
                    manager.runBridgeTask(arguments: args, title: "FC27 Kariyer: \(teamName)")
                } label: {
                    Label("Kariyer Duyurusunu Başlat", systemImage: "play.fill")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(teamName.trimmingCharacters(in: .whitespaces).isEmpty || manager.isRunningTask)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - 7. Tosba Lojistik Card
struct TosbaLojistikCard: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "truck.box.fill")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Tosba Lojistik (Euro Truck Simulator 2)")
                .font(.title2.weight(.bold))
            
            Text("Bu duyuru otomasyonu corvus.py altyapısında şu anda yapım aşamasındadır.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("🚧 YAPIM AŞAMASINDA")
                .font(.caption.weight(.heavy))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.15))
                .foregroundColor(.orange)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

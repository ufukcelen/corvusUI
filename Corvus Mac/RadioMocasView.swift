//
//  RadioMocasView.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI

struct RadioMocasView: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var selectedSubProgram: String = "memleket_duyuru"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Radio Mocas Stüdyosu")
                        .font(.title2.weight(.bold))
                    Text("Filtresiz Memleket Havası, Albert ve Cem, Mocas Bey ve Aklımdaki Filmler otomasyonları.")
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
                    subProgramTab(id: "memleket_duyuru", title: "Filtresiz Memleket Havası", icon: "waveform")
                    subProgramTab(id: "memleket_thumb", title: "Memleket Thumbnail", icon: "photo.badge.plus")
                    subProgramTab(id: "albert_cem", title: "Albert ve Cem", icon: "mic.fill")
                    subProgramTab(id: "mocas_bey", title: "Mocas Bey ve Radyosu", icon: "radio.fill")
                    subProgramTab(id: "aklimdaki_filmler", title: "Aklımdaki Filmler", icon: "film.fill")
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
                    case "memleket_duyuru":
                        MemleketDuyuruCard()
                    case "memleket_thumb":
                        MemleketThumbCard()
                    case "albert_cem":
                        AlbertCemCard()
                    case "mocas_bey":
                        RadioUnderConstructionCard(title: "Mocas Bey ve Radyosu", icon: "radio.fill")
                    case "aklimdaki_filmler":
                        RadioUnderConstructionCard(title: "Aklımdaki Filmler", icon: "film.fill")
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

// MARK: - 1. Filtresiz Memleket Havası Duyuru
struct MemleketDuyuruCard: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var broadcastHour: String = "22:00"
    @State private var runRender: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "waveform")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filtresiz Memleket Havası Duyuru Otomasyonu")
                        .font(.title3.weight(.bold))
                    Text("mem.json dosyasını saat ile günceller, rastgele memGorsel seçer ve After Effects memSahne renderını başlatır.")
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
                        TextField("22:00", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Render")
                            .font(.subheadline.weight(.medium))
                        Toggle("AE Render Başlat (FMH_*.mp4)", isOn: $runRender)
                    }
                }
            }
            
            HStack {
                Spacer()
                Button {
                    var args = ["memleket_duyuru", "--saat", broadcastHour]
                    if runRender { args.append("--render") }
                    manager.runBridgeTask(arguments: args, title: "Filtresiz Memleket Havası (\(broadcastHour))")
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

// MARK: - 2. Memleket Thumbnail Card
struct MemleketThumbCard: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var episodeNumber: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memleket Thumbnail Oluşturucu (Photoshop)")
                        .font(.title3.weight(.bold))
                    Text("memleketYatay.psd şablonunu açar, bolumno katmanına # girer, renk1 ve renk2 tonlarına rastgele Hue değerleri atar ve Masaüstüne kaydeder.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bölüm Numarası")
                        .font(.subheadline.weight(.medium))
                    TextField("Örn: 24 veya #24", text: $episodeNumber)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                }
            }
            
            HStack {
                Spacer()
                Button {
                    let args = ["memleket_thumbnail", "--bolum", episodeNumber]
                    manager.runBridgeTask(arguments: args, title: "Memleket Thumbnail: #\(episodeNumber.replacingOccurrences(of: "#", with: ""))")
                } label: {
                    Label("Thumbnail Üret", systemImage: "sparkles")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(episodeNumber.trimmingCharacters(in: .whitespaces).isEmpty || manager.isRunningTask)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - 3. Albert ve Cem Card
struct AlbertCemCard: View {
    @ObservedObject var manager = CorvusManager.shared
    @State private var broadcastHour: String = "23:00"
    @State private var runRender: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Albert ve Cem Duyuru Otomasyonu")
                        .font(.title3.weight(.bold))
                    Text("albert.json dosyasını saat ile günceller, After Effects albertSahne renderını başlatır ve albertSeo.txt oluşturur.")
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
                        TextField("23:00", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Render")
                            .font(.subheadline.weight(.medium))
                        Toggle("AE Render Başlat (albert_*.mp4)", isOn: $runRender)
                    }
                }
            }
            
            HStack {
                Spacer()
                Button {
                    var args = ["albert_ve_cem", "--saat", broadcastHour]
                    if runRender { args.append("--render") }
                    manager.runBridgeTask(arguments: args, title: "Albert ve Cem (\(broadcastHour))")
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

// MARK: - Construction Card
struct RadioUnderConstructionCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text(title)
                .font(.title2.weight(.bold))
            
            Text("Bu program otomasyonu corvus.py altyapısında şu anda yapım aşamasındadır.")
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

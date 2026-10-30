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
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Filtresiz Memleket Havası, Albert ve Cem, Mocas Bey ve Aklımdaki Filmler otomasyonları.")
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
                    subProgramTab(id: "memleket_duyuru", title: "Filtresiz Memleket Havası", icon: "waveform")
                    subProgramTab(id: "memleket_thumb", title: "Memleket Thumbnail", icon: "photo.badge.plus")
                    subProgramTab(id: "albert_cem", title: "Albert ve Cem", icon: "mic.fill")
                    subProgramTab(id: "mocas_bey", title: "Mocas Bey ve Radyosu", icon: "radio.fill")
                    subProgramTab(id: "aklimdaki_filmler", title: "Aklımdaki Filmler", icon: "film.fill")
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
            .background(selectedSubProgram == id ? AppTheme.accentOrange : AppTheme.surfaceElevated)
            .foregroundColor(selectedSubProgram == id ? .black : AppTheme.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedSubProgram == id ? AppTheme.accentOrange : AppTheme.border, lineWidth: 1)
            )
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
                        .fill(AppTheme.accentOrange.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: "waveform")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentOrange)
                }
                .corvusGlow(color: AppTheme.accentOrange, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filtresiz Memleket Havası Duyuru Otomasyonu")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("mem.json dosyasını saat ile günceller, rastgele memGorsel seçer ve After Effects memSahne renderını başlatır.")
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
                        TextField("22:00", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Render")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
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
        .corvusCard(padding: 24, radius: 16)
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
                        .fill(AppTheme.accentOrange.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentOrange)
                }
                .corvusGlow(color: AppTheme.accentOrange, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memleket Thumbnail Oluşturucu (Photoshop)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("memleketYatay.psd şablonunu açar, bolumno katmanına # girer, renk1 ve renk2 tonlarına rastgele Hue değerleri atar ve Masaüstüne kaydeder.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Divider()
                .overlay(AppTheme.border)
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bölüm Numarası")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.textSecondary)
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
        .corvusCard(padding: 24, radius: 16)
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
                        .fill(AppTheme.accentCyan.opacity(0.18))
                        .frame(width: 50, height: 50)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accentCyan)
                }
                .corvusGlow(color: AppTheme.accentCyan, radius: 6, opacity: 0.25)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Albert ve Cem Duyuru Otomasyonu")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("albert.json dosyasını saat ile günceller, After Effects albertSahne renderını başlatır ve albertSeo.txt oluşturur.")
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
                        TextField("23:00", text: $broadcastHour)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Render")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.textSecondary)
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
        .corvusCard(padding: 24, radius: 16)
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
                .foregroundColor(AppTheme.textMuted.opacity(0.6))
            
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text("Bu program otomasyonu corvus.py altyapısında şu anda yapım aşamasındadır.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("🚧 YAPIM AŞAMASINDA")
                .font(.caption.weight(.heavy))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.accentOrange.opacity(0.18))
                .foregroundColor(AppTheme.accentOrange)
                .overlay(
                    Capsule().stroke(AppTheme.accentOrange.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(32)
        .corvusCard(padding: 32, radius: 16)
    }
}

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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.indigo.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.indigo)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Photoshop Thumbnail Merkezi")
                            .font(.title2.weight(.bold))
                        Text("Adobe Photoshop JSX otomasyonu ile YouTube kapak görselleri (Thumbnail) üretimi.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Photoshop Status Badge
                    HStack(spacing: 8) {
                        Circle()
                            .fill(manager.photoshopFound ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(manager.photoshopFound ? manager.photoshopAppName : "Photoshop Bulunamadı")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(Capsule())
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                // Templates Grid (3 templates from corvus.py)
                VStack(spacing: 20) {
                    // 1. Memleket
                    thumbnailCard(
                        title: "1. Filtresiz Memleket Havası",
                        templateName: "memleketYatay.psd",
                        outputName: "memleket{no}.jpg",
                        icon: "waveform",
                        color: .orange,
                        description: "Kapak görselinde bölüm numarasını (#..) günceller ve renk1 / renk2 katmanlarına rastgele Hue uygulayarak dinamik renk kombinasyonu üretir."
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
                    
                    // 2. Canlı Maç
                    thumbnailCard(
                        title: "2. Canlı Maç Sohbetleri",
                        templateName: "canlimac.psd",
                        outputName: "canlimacyatay.jpg",
                        icon: "tv.fill",
                        color: .green,
                        description: "Lig/turnuva katmanını (superlig, cl, europa, conf, uluslar) seçer, takımların logolarını optik ağırlıklarına (225px vs 280px) göre Smart Object içine yerleştirir."
                    ) {
                        HStack(spacing: 12) {
                            TextField("Tarih (YYYY-MM-DD)", text: $canliMacDate)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                            
                            TextField("Maç ID", text: $canliMacId)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                            
                            Button {
                                let args = ["canli_thumbnail", "--mac_id", canliMacId, "--tarih", canliMacDate]
                                manager.runBridgeTask(arguments: args, title: "Canlı Maç Thumbnail: \(canliMacId)")
                            } label: {
                                Label("Oluştur", systemImage: "sparkles")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(canliMacId.trimmingCharacters(in: .whitespaces).isEmpty || manager.isRunningTask)
                        }
                    }
                    
                    // 3. Haftalık Program
                    thumbnailCard(
                        title: "3. Haftalık Program",
                        templateName: "haftalık.psd",
                        outputName: "haftalik_program.jpg",
                        icon: "calendar.badge.clock",
                        color: .purple,
                        description: "haftalık.psd dosyasını Photoshop ile açar ve hiçbir katmanı bozmadan maksimum 12 kalitesinde Masaüstüne kaydeder."
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
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            canliMacDate = f.string(from: Date())
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
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text("Şablon: \(templateName)")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Çıktı: ~/Desktop/\(outputName)")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            controls()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

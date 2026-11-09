//
//  Models.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI
import Foundation

// MARK: - User
enum CorvusUser: String, CaseIterable, Identifiable, Codable {
    case ufuk = "1"
    case yigit = "2"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .ufuk: return "Ufuk"
        case .yigit: return "Yiğit"
        }
    }
    
    var otherUser: CorvusUser {
        switch self {
        case .ufuk: return .yigit
        case .yigit: return .ufuk
        }
    }
    
    var sendNotificationTopic: String {
        switch self {
        case .ufuk: return "tellal_duyuru_ufuk_yigit_u2y_7294"
        case .yigit: return "tellal_duyuru_ufuk_yigit_y2u_7294"
        }
    }
    
    var receiveNotificationTopic: String {
        switch self {
        case .ufuk: return "tellal_duyuru_ufuk_yigit_y2u_7294"
        case .yigit: return "tellal_duyuru_ufuk_yigit_u2y_7294"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .ufuk: return Color.cyan
        case .yigit: return Color.purple
        }
    }
    
    var avatarSystemImage: String {
        switch self {
        case .ufuk: return "person.crop.circle.fill"
        case .yigit: return "person.crop.circle.badge.checkmark"
        }
    }
}

// MARK: - Calendar Item
struct CalendarItem: Identifiable, Equatable {
    let id: String
    var rawText: String
    var index: Int
    var title: String
    var day: String
    var time: String
    var info: String?
    var isDone: Bool
    var isCancelled: Bool
    
    init(rawText: String, fallbackIndex: Int) {
        self.id = UUID().uuidString
        self.rawText = rawText
        
        var working = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse info note if present
        if let infoRange = working.range(of: " | Bilgi: ") {
            self.info = String(working[infoRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            working = String(working[..<infoRange.lowerBound])
        } else {
            self.info = nil
        }
        
        // Parse index: "1-) ..."
        if let idxRange = working.range(of: "-)") {
            let idxStr = String(working[..<idxRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            self.index = Int(idxStr) ?? fallbackIndex
            working = String(working[idxRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        } else {
            self.index = fallbackIndex
        }
        
        self.isDone = working.contains("✅")
        self.isCancelled = working.contains("❌")
        
        working = working.replacingOccurrences(of: "✅", with: "")
                         .replacingOccurrences(of: "❌", with: "")
                         .trimmingCharacters(in: .whitespaces)
        
        // Split by " - " (Title - Day - Time)
        let parts = working.components(separatedBy: " - ").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count >= 3 {
            self.title = parts[0]
            self.day = parts[1]
            self.time = parts[2]
        } else if parts.count == 2 {
            self.title = parts[0]
            self.day = parts[1]
            self.time = ""
        } else {
            self.title = working
            self.day = ""
            self.time = ""
        }
    }
    
    func formattedRawLine(newIndex: Int? = nil) -> String {
        let idx = newIndex ?? self.index
        var namePart = title
        if isCancelled {
            namePart += " ❌"
        } else if isDone {
            namePart += " ✅"
        }
        
        var line = "\(idx)-) \(namePart)"
        if !day.isEmpty && !time.isEmpty {
            line += " - \(day) - \(time)"
        } else if !day.isEmpty {
            line += " - \(day)"
        }
        
        if let info = info, !info.isEmpty {
            line += " | Bilgi: \(info)"
        }
        return line
    }
}

// MARK: - Chat Message
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let rawText: String
    let sender: String
    let content: String
    let timestamp: Date
    
    init(rawText: String) {
        self.rawText = rawText
        self.timestamp = Date()
        
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let colonIndex = trimmed.firstIndex(of: ":") {
            self.sender = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let afterColon = trimmed.index(after: colonIndex)
            self.content = String(trimmed[afterColon...]).trimmingCharacters(in: .whitespaces)
        } else {
            self.sender = "Sistem"
            self.content = trimmed
        }
    }
    
    var senderColor: Color {
        let low = sender.lowercased()
        if low.contains("ufuk") {
            return Color.cyan
        } else if low.contains("yiğit") || low.contains("yigit") {
            return Color.purple
        } else if low.contains("cem") {
            return Color.orange
        } else {
            return Color.blue
        }
    }
    
    var isCurrentUser: Bool {
        // Will be compared with active user in UI
        false
    }
}

// MARK: - Match Item (API Sports)
struct MatchItem: Identifiable, Decodable {
    let id: Int
    let date: String
    let timeStr: String
    let home: String
    let homeId: Int
    let homeLogo: String?
    let away: String
    let awayId: Int
    let awayLogo: String?
    let leagueId: Int
    let leagueName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case timeStr = "time_str"
        case home
        case homeId = "home_id"
        case homeLogo = "home_logo"
        case away
        case awayId = "away_id"
        case awayLogo = "away_logo"
        case leagueId = "league_id"
        case leagueName = "league_name"
    }
}

// MARK: - Process Log Item
struct ProcessLogItem: Identifiable {
    let id = UUID()
    let timestamp: Date = Date()
    let text: String
    let isError: Bool
    let isProgress: Bool
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Program Templates
struct ProgramChoice: Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let defaultTime: String
    let icon: String
    
    static let allPrograms: [ProgramChoice] = [
        ProgramChoice(id: "Haftalık Program", title: "Haftalık Program", category: "Uykusuz Tosba", defaultTime: "21:00", icon: "calendar.badge.clock"),
        ProgramChoice(id: "Canlı Maç Sohbetleri", title: "Canlı Maç Sohbetleri", category: "Uykusuz Tosba", defaultTime: "20:00", icon: "tv.fill"),
        ProgramChoice(id: "Maç Sonu", title: "Maç Sonu", category: "Uykusuz Tosba", defaultTime: "22:00", icon: "sportscourt.fill"),
        ProgramChoice(id: "Tek Maçtan Yatanlar", title: "Tek Maçtan Yatanlar", category: "Uykusuz Tosba", defaultTime: "21:00", icon: "ticket.fill"),
        ProgramChoice(id: "FC27 Kariyer", title: "FC27 Kariyer", category: "Uykusuz Tosba", defaultTime: "20:30", icon: "gamecontroller.fill"),
        ProgramChoice(id: "Tosba Lojistik (ETS2)", title: "Tosba Lojistik (ETS2)", category: "Uykusuz Tosba", defaultTime: "21:30", icon: "truck.box.fill"),
        ProgramChoice(id: "Filtresiz Memleket Havası", title: "Filtresiz Memleket Havası", category: "Radio Mocas", defaultTime: "22:00", icon: "waveform"),
        ProgramChoice(id: "Albert ve Cem", title: "Albert ve Cem", category: "Radio Mocas", defaultTime: "23:00", icon: "mic.fill"),
        ProgramChoice(id: "Mocas Bey ve Radyosu", title: "Mocas Bey ve Radyosu", category: "Radio Mocas", defaultTime: "21:00", icon: "radio.fill"),
        ProgramChoice(id: "Aklımdaki Filmler", title: "Aklımdaki Filmler", category: "Radio Mocas", defaultTime: "21:00", icon: "film.fill")
    ]
}

// MARK: - Render Cache Item
struct RenderCacheItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let sizeBytes: Int64
    let isDirectory: Bool
    let modDate: Date?
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
    
    var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "m4v":
            return "film.fill"
        case "jpg", "jpeg", "png", "psd":
            return "photo.fill"
        case "txt", "json", "log":
            return "doc.text.fill"
        case "aep":
            return "play.rectangle.fill"
        default:
            return "doc.fill"
        }
    }
}

//
//  Theme.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI
import AppKit

// MARK: - Theme Mode
enum AppThemeMode: String, CaseIterable, Identifiable {
    case obsidian = "obsidian" // Dark Studio (Default)
    case oled = "oled"         // True Black OLED
    case midnight = "midnight" // Deep Space Blue
    case system = "system"     // Follow macOS
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .obsidian: return "Obsidian Studio ⭐️"
        case .oled: return "OLED Saf Siyah"
        case .midnight: return "Gece Mavisi / Space"
        case .system: return "Sistem Tercihi"
        }
    }
    
    var icon: String {
        switch self {
        case .obsidian: return "sparkles"
        case .oled: return "moon.fill"
        case .midnight: return "circle.hexagongrid.fill"
        case .system: return "gearshape.2"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .obsidian, .oled, .midnight:
            return .dark
        case .system:
            return nil
        }
    }
}

// MARK: - Design System Colors & Styles
struct AppTheme {
    static var activeTheme: AppThemeMode {
        let raw = UserDefaults.standard.string(forKey: "CorvusAppThemeMode") ?? "obsidian"
        return AppThemeMode(rawValue: raw) ?? .obsidian
    }
    
    // Backgrounds
    static var bg: Color {
        switch activeTheme {
        case .oled:
            return Color(hex: "000000")
        case .midnight:
            return Color(hex: "0A0D14")
        case .obsidian, .system:
            return Color(hex: "0D0F13")
        }
    }
    
    static var sidebarBg: Color {
        switch activeTheme {
        case .oled:
            return Color(hex: "050505")
        case .midnight:
            return Color(hex: "0C101A")
        case .obsidian, .system:
            return Color(hex: "11141B")
        }
    }
    
    static var surface: Color {
        switch activeTheme {
        case .oled:
            return Color(hex: "0E0E0E")
        case .midnight:
            return Color(hex: "131826")
        case .obsidian, .system:
            return Color(hex: "161922")
        }
    }
    
    static var surfaceHover: Color {
        switch activeTheme {
        case .oled:
            return Color(hex: "171717")
        case .midnight:
            return Color(hex: "1A2033")
        case .obsidian, .system:
            return Color(hex: "1E232E")
        }
    }
    
    static var surfaceElevated: Color {
        switch activeTheme {
        case .oled:
            return Color(hex: "141414")
        case .midnight:
            return Color(hex: "182030")
        case .obsidian, .system:
            return Color(hex: "222836")
        }
    }
    
    static var inputBg: Color {
        switch activeTheme {
        case .oled:
            return Color(hex: "0A0A0A")
        case .midnight:
            return Color(hex: "0F1420")
        case .obsidian, .system:
            return Color(hex: "12151D")
        }
    }
    
    // Borders
    static var border: Color {
        Color.white.opacity(0.08)
    }
    
    static var borderSubtle: Color {
        Color.white.opacity(0.04)
    }
    
    static var borderHighlight: Color {
        Color.white.opacity(0.15)
    }
    
    // Brand & Neon Accents
    static let accentCyan = Color(hex: "00C6FF")
    static let accentPurple = Color(hex: "A855F7")
    static let accentBlue = Color(hex: "3B82F6")
    static let accentOrange = Color(hex: "F97316")
    static let accentAmber = Color(hex: "F59E0B")
    static let accentGreen = Color(hex: "10B981")
    static let accentRose = Color(hex: "F43F5E")
    
    // Text
    static let textPrimary = Color(hex: "F8FAFC")
    static let textSecondary = Color(hex: "94A3B8")
    static let textMuted = Color(hex: "64748B")
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers for Sleek Dark Cards
struct CorvusCardModifier: ViewModifier {
    var radius: CGFloat = 16
    var padding: CGFloat = 20
    var isElevated: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(isElevated ? AppTheme.surfaceElevated : AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
    }
}

struct CorvusGlassModifier: ViewModifier {
    var radius: CGFloat = 16
    var padding: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(AppTheme.surface.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func corvusCard(padding: CGFloat = 20, radius: CGFloat = 16, isElevated: Bool = false) -> some View {
        modifier(CorvusCardModifier(radius: radius, padding: padding, isElevated: isElevated))
    }
    
    func corvusGlassCard(padding: CGFloat = 20, radius: CGFloat = 16) -> some View {
        modifier(CorvusGlassModifier(radius: radius, padding: padding))
    }
    
    func corvusGlow(color: Color, radius: CGFloat = 8, opacity: Double = 0.35) -> some View {
        self.shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
    }
}

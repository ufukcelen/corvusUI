//
//  Theme.swift
//  Corvus Mac
//
//  Created by Ufuk Celen on 30.10.2026.
//

import SwiftUI
import AppKit

// MARK: - App Theme Mode
enum AppThemeMode: String, CaseIterable, Identifiable {
    case obsidian = "obsidian"         // Obsidian Studio (Modern Studio) ⭐
    case vintageManor = "vintageManor" // Vintage Manor / Malikâne 🏰
    case medieval = "medieval"         // Ortaçağ (Medieval) ⚔️
    case byzantine = "byzantine"       // Bizans (Byzantine) 👑
    case futuristic = "futuristic"     // Gelecek (Futuristic / Cyberpunk) ⚡️
    case midnight = "midnight"         // Gece Mavisi / Deep Space 🌌
    case oled = "oled"                 // OLED Saf Siyah 🌑
    case system = "system"             // macOS Sistem Tercihi 💻
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .obsidian: return "Obsidian Studio ⭐"
        case .vintageManor: return "Vintage Malikâne 🏰"
        case .medieval: return "Ortaçağ (Medieval) ⚔️"
        case .byzantine: return "Bizans (Byzantine) 👑"
        case .futuristic: return "Gelecek (Futuristic) ⚡️"
        case .midnight: return "Gece Mavisi / Space 🌌"
        case .oled: return "OLED Saf Siyah 🌑"
        case .system: return "Sistem Tercihi 💻"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .obsidian: return "Obsidian"
        case .vintageManor: return "Vintage Malikâne"
        case .medieval: return "Ortaçağ"
        case .byzantine: return "Bizans"
        case .futuristic: return "Gelecek"
        case .midnight: return "Gece Mavisi"
        case .oled: return "OLED Siyah"
        case .system: return "Sistem"
        }
    }
    
    var subtitle: String {
        switch self {
        case .obsidian: return "Koyu gri cam stüdyo & neon dokunuşlar"
        case .vintageManor: return "Zümrüt yeşili, antik varak & pirinç"
        case .medieval: return "Taş kale, dövme demir, parşömen & is"
        case .byzantine: return "İmparatorluk moru, mozaik & altın varak"
        case .futuristic: return "Siber mainframe, neon cyan & keskin hatlar"
        case .midnight: return "Derin uzay mavisi & yumuşak degrade"
        case .oled: return "Saf siyah #000 & yüksek kontrast"
        case .system: return "macOS sistem karanlık/aydınlık ayarı"
        }
    }
    
    var icon: String {
        switch self {
        case .obsidian: return "sparkles"
        case .vintageManor: return "building.columns.fill"
        case .medieval: return "shield.checkered"
        case .byzantine: return "crown.fill"
        case .futuristic: return "cpu.fill"
        case .midnight: return "circle.hexagongrid.fill"
        case .oled: return "moon.fill"
        case .system: return "gearshape.2"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .obsidian, .vintageManor, .medieval, .byzantine, .futuristic, .midnight, .oled:
            return .dark
        case .system:
            return nil
        }
    }
    
    // MARK: - Color Palette
    var bg: Color {
        switch self {
        case .obsidian: return Color(hex: "0D0F13")
        case .vintageManor: return Color(hex: "101915") // Deep antique moss / emerald
        case .medieval: return Color(hex: "181513")     // Aged stone & timber
        case .byzantine: return Color(hex: "190E1D")    // Imperial porphyry purple
        case .futuristic: return Color(hex: "050B14")   // Cyber cockpit deep navy
        case .midnight: return Color(hex: "0A0D14")
        case .oled: return Color(hex: "000000")
        case .system: return Color(hex: "0D0F13")
        }
    }
    
    var sidebarBg: Color {
        switch self {
        case .obsidian: return Color(hex: "11141B")
        case .vintageManor: return Color(hex: "0C1411")
        case .medieval: return Color(hex: "12100E")
        case .byzantine: return Color(hex: "120815")
        case .futuristic: return Color(hex: "03070E")
        case .midnight: return Color(hex: "0C101A")
        case .oled: return Color(hex: "050505")
        case .system: return Color(hex: "11141B")
        }
    }
    
    var surface: Color {
        switch self {
        case .obsidian: return Color(hex: "161922")
        case .vintageManor: return Color(hex: "16231E")
        case .medieval: return Color(hex: "221E1B")
        case .byzantine: return Color(hex: "25142B")
        case .futuristic: return Color(hex: "091424")
        case .midnight: return Color(hex: "131826")
        case .oled: return Color(hex: "0E0E0E")
        case .system: return Color(hex: "161922")
        }
    }
    
    var surfaceHover: Color {
        switch self {
        case .obsidian: return Color(hex: "1E232E")
        case .vintageManor: return Color(hex: "1D2D27")
        case .medieval: return Color(hex: "2B2623")
        case .byzantine: return Color(hex: "2F1B38")
        case .futuristic: return Color(hex: "0E1F36")
        case .midnight: return Color(hex: "1A2033")
        case .oled: return Color(hex: "171717")
        case .system: return Color(hex: "1E232E")
        }
    }
    
    var surfaceElevated: Color {
        switch self {
        case .obsidian: return Color(hex: "222836")
        case .vintageManor: return Color(hex: "1F312B")
        case .medieval: return Color(hex: "2E2824")
        case .byzantine: return Color(hex: "361D3D")
        case .futuristic: return Color(hex: "10223B")
        case .midnight: return Color(hex: "182030")
        case .oled: return Color(hex: "141414")
        case .system: return Color(hex: "222836")
        }
    }
    
    var inputBg: Color {
        switch self {
        case .obsidian: return Color(hex: "12151D")
        case .vintageManor: return Color(hex: "0E1713")
        case .medieval: return Color(hex: "14110F")
        case .byzantine: return Color(hex: "130A17")
        case .futuristic: return Color(hex: "060D17")
        case .midnight: return Color(hex: "0F1420")
        case .oled: return Color(hex: "0A0A0A")
        case .system: return Color(hex: "12151D")
        }
    }
    
    // MARK: - Accent Colors
    var accentPrimary: Color {
        switch self {
        case .obsidian: return Color(hex: "00C6FF")    // Cyan
        case .vintageManor: return Color(hex: "D4AF37") // Antique Gold / Brass
        case .medieval: return Color(hex: "C8963E")     // Heraldic Gold
        case .byzantine: return Color(hex: "E5B842")    // Byzantine Gold
        case .futuristic: return Color(hex: "00F0FF")   // Laser Neon Cyan
        case .midnight: return Color(hex: "38BDF8")     // Sky Blue
        case .oled: return Color(hex: "F59E0B")         // Amber Gold
        case .system: return Color(hex: "00C6FF")
        }
    }
    
    var accentSecondary: Color {
        switch self {
        case .obsidian: return Color(hex: "A855F7")    // Purple
        case .vintageManor: return Color(hex: "C5A059") // Warm Brass
        case .medieval: return Color(hex: "9E2A2B")     // Banner Crimson
        case .byzantine: return Color(hex: "00D2D3")    // Mosaic Turquoise
        case .futuristic: return Color(hex: "0080FF")   // Hologram Blue
        case .midnight: return Color(hex: "818CF8")     // Indigo
        case .oled: return Color(hex: "3B82F6")         // Royal Blue
        case .system: return Color(hex: "A855F7")
        }
    }
    
    var accentTertiary: Color {
        switch self {
        case .obsidian: return Color(hex: "10B981")    // Green
        case .vintageManor: return Color(hex: "2D6A4F") // Forest Emerald
        case .medieval: return Color(hex: "D4A373")     // Aged Parchment
        case .byzantine: return Color(hex: "E63946")    // Imperial Ruby
        case .futuristic: return Color(hex: "BD00FF")   // Cyber Violet
        case .midnight: return Color(hex: "06B6D4")     // Cyan
        case .oled: return Color(hex: "10B981")         // Emerald
        case .system: return Color(hex: "10B981")
        }
    }
    
    // MARK: - Typography Colors
    var textPrimary: Color {
        switch self {
        case .vintageManor: return Color(hex: "F7F2E7") // Warm Ivory Cream
        case .medieval: return Color(hex: "F3E9DC")     // Parchment Cream
        case .byzantine: return Color(hex: "F8F2FB")    // Royal Lily
        case .futuristic: return Color(hex: "E8F4FD")   // Ice Cyan White
        case .obsidian, .midnight, .oled, .system: return Color(hex: "F8FAFC")
        }
    }
    
    var textSecondary: Color {
        switch self {
        case .vintageManor: return Color(hex: "C9BFAD")
        case .medieval: return Color(hex: "BCAC9B")
        case .byzantine: return Color(hex: "C9B6D1")
        case .futuristic: return Color(hex: "89B0D3")
        case .obsidian, .midnight, .oled, .system: return Color(hex: "94A3B8")
        }
    }
    
    var textMuted: Color {
        switch self {
        case .vintageManor: return Color(hex: "867D6F")
        case .medieval: return Color(hex: "7B6E60")
        case .byzantine: return Color(hex: "8B7593")
        case .futuristic: return Color(hex: "4E7194")
        case .obsidian, .midnight, .oled, .system: return Color(hex: "64748B")
        }
    }
    
    // MARK: - Border & Radius Configurations
    var cardBorderColor: Color {
        switch self {
        case .futuristic:
            return Color(hex: "00F0FF").opacity(0.40)
        case .byzantine:
            return Color(hex: "E5B842").opacity(0.38)
        case .vintageManor:
            return Color(hex: "D4AF37").opacity(0.35)
        case .medieval:
            return Color(hex: "C8963E").opacity(0.30)
        case .oled:
            return Color.white.opacity(0.12)
        case .midnight:
            return Color(hex: "38BDF8").opacity(0.12)
        case .obsidian, .system:
            return Color.white.opacity(0.08)
        }
    }
    
    var defaultCornerRadius: CGFloat {
        switch self {
        case .futuristic: return 8    // Sharp futuristic cyber chamfer
        case .medieval: return 10     // Heavy wrought iron corners
        case .byzantine: return 12    // Classic imperial frame
        case .vintageManor: return 14 // Antique manor curvature
        case .obsidian, .midnight, .oled, .system: return 16 // Smooth modern macOS rounded-2xl
        }
    }
    
    var hasGrain: Bool {
        switch self {
        case .vintageManor, .medieval, .byzantine, .futuristic:
            return true
        default:
            return false
        }
    }
    
    var grainOpacity: Double {
        switch self {
        case .medieval: return 0.040     // Parchment & stone texture
        case .byzantine: return 0.032    // Mosaic antique grain
        case .vintageManor: return 0.026 // Velvet & vintage paper grain
        case .futuristic: return 0.020   // CRT digital scan grain
        default: return 0.0
        }
    }
    
    var pulseRingColor: Color {
        accentPrimary
    }
}

// MARK: - Static Theme Convenience Facade
struct AppTheme {
    static var activeTheme: AppThemeMode {
        let raw = UserDefaults.standard.string(forKey: "CorvusAppThemeMode") ?? "obsidian"
        return AppThemeMode(rawValue: raw) ?? .obsidian
    }
    
    static var bg: Color { activeTheme.bg }
    static var sidebarBg: Color { activeTheme.sidebarBg }
    static var surface: Color { activeTheme.surface }
    static var surfaceHover: Color { activeTheme.surfaceHover }
    static var surfaceElevated: Color { activeTheme.surfaceElevated }
    static var inputBg: Color { activeTheme.inputBg }
    
    static var border: Color { activeTheme.cardBorderColor }
    static var borderSubtle: Color { activeTheme.cardBorderColor.opacity(0.5) }
    static var borderHighlight: Color { activeTheme.accentPrimary.opacity(0.4) }
    
    // Core Brand Accents
    static var accentCyan: Color { activeTheme.accentPrimary }
    static var accentPurple: Color { activeTheme.accentSecondary }
    static var accentBlue: Color { Color(hex: "3B82F6") }
    static var accentOrange: Color { Color(hex: "F97316") }
    static var accentAmber: Color { Color(hex: "F59E0B") }
    static var accentGreen: Color { Color(hex: "10B981") }
    static var accentRose: Color { Color(hex: "F43F5E") }
    
    // Text
    static var textPrimary: Color { activeTheme.textPrimary }
    static var textSecondary: Color { activeTheme.textSecondary }
    static var textMuted: Color { activeTheme.textMuted }
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

// MARK: - Native macOS Backdrop (Frosted Glass / Mica)
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Procedural Seamless Monochrome Grain Provider
final class GrainTextureProvider {
    static let sharedImage: NSImage = {
        let width = 128
        let height = 128
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var seed: UInt64 = 0xDEADBEEFCAFE
        for i in 0..<(width * height) {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let val = UInt8((seed >> 32) & 0xFF)
            let isWhite = (seed >> 24) & 1 == 1
            pixels[i * 4 + 0] = isWhite ? 255 : 0
            pixels[i * 4 + 1] = isWhite ? 255 : 0
            pixels[i * 4 + 2] = isWhite ? 255 : 0
            pixels[i * 4 + 3] = (val > 140) ? 28 : 0
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let cgImg = context?.makeImage() else { return NSImage() }
        return NSImage(cgImage: cgImg, size: NSSize(width: width, height: height))
    }()
}

// MARK: - Theme Grain Overlay
struct ThemeGrainOverlay: View {
    var opacity: Double = 0.03
    
    var body: some View {
        Image(nsImage: GrainTextureProvider.sharedImage)
            .resizable(resizingMode: .tile)
            .opacity(opacity)
            .blendMode(.overlay)
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }
}

// MARK: - Full Window Backdrop with Ambient Lighting
struct CorvusBackdropView: View {
    let theme: AppThemeMode
    
    var body: some View {
        ZStack {
            // 1. Base Theme Color
            theme.bg
                .ignoresSafeArea()
            
            // 2. macOS Native Glassmorphism / Mica Blur
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .opacity(0.20)
                .ignoresSafeArea()
            
            // 3. Subtle Grain / Noise Overlay
            if theme.hasGrain {
                ThemeGrainOverlay(opacity: theme.grainOpacity)
            }
            
            // 4. Ambient Theme-Specific Glows
            switch theme {
            case .futuristic:
                RadialGradient(
                    colors: [Color(hex: "00F0FF").opacity(0.08), Color.clear],
                    center: .topTrailing,
                    startRadius: 60,
                    endRadius: 550
                )
                .allowsHitTesting(false)
                .ignoresSafeArea()
            case .byzantine:
                RadialGradient(
                    colors: [Color(hex: "E5B842").opacity(0.07), Color(hex: "E63946").opacity(0.04), Color.clear],
                    center: .topLeading,
                    startRadius: 60,
                    endRadius: 500
                )
                .allowsHitTesting(false)
                .ignoresSafeArea()
            case .vintageManor:
                RadialGradient(
                    colors: [Color(hex: "D4AF37").opacity(0.06), Color.clear],
                    center: .topTrailing,
                    startRadius: 50,
                    endRadius: 480
                )
                .allowsHitTesting(false)
                .ignoresSafeArea()
            case .medieval:
                RadialGradient(
                    colors: [Color(hex: "9E2A2B").opacity(0.05), Color.clear],
                    center: .bottomLeading,
                    startRadius: 80,
                    endRadius: 500
                )
                .allowsHitTesting(false)
                .ignoresSafeArea()
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Theme Shadow Modifier
struct ThemeShadowModifier: ViewModifier {
    let theme: AppThemeMode
    
    func body(content: Content) -> some View {
        switch theme {
        case .futuristic:
            // Neon Glow + Tight Cyber Shadow
            content
                .shadow(color: theme.accentPrimary.opacity(0.35), radius: 12, x: 0, y: 0)
                .shadow(color: Color.black.opacity(0.60), radius: 8, x: 0, y: 4)
        case .medieval:
            // Diffuse Soot / Ash Smoke Shadows
            content
                .shadow(color: Color.black.opacity(0.75), radius: 20, x: 0, y: 9)
        case .byzantine:
            // Imperial Varnish & Gold Ember Shadow
            content
                .shadow(color: Color.black.opacity(0.65), radius: 16, x: 0, y: 6)
                .shadow(color: theme.accentPrimary.opacity(0.14), radius: 8, x: 0, y: 0)
        case .vintageManor:
            // Manor Warm Brass & Deep Timber Shadow
            content
                .shadow(color: Color.black.opacity(0.55), radius: 14, x: 0, y: 6)
                .shadow(color: theme.accentPrimary.opacity(0.10), radius: 6, x: 0, y: 0)
        case .oled:
            content
                .shadow(color: Color.white.opacity(0.04), radius: 8, x: 0, y: 2)
        default:
            // Modern Sleek Drop Shadow
            content
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Theme Adaptive Card Modifier
struct CorvusCardModifier: ViewModifier {
    var radius: CGFloat? = nil
    var padding: CGFloat = 20
    var isElevated: Bool = false
    
    var effectiveRadius: CGFloat {
        if let r = radius { return r }
        return AppTheme.activeTheme.defaultCornerRadius
    }
    
    func body(content: Content) -> some View {
        let theme = AppTheme.activeTheme
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: effectiveRadius)
                    .fill(isElevated ? theme.surfaceElevated : theme.surface)
            )
            .overlay(
                cardBorderOverlay(for: theme, radius: effectiveRadius)
            )
            .modifier(ThemeShadowModifier(theme: theme))
    }
    
    @ViewBuilder
    private func cardBorderOverlay(for theme: AppThemeMode, radius: CGFloat) -> some View {
        switch theme {
        case .byzantine, .vintageManor:
            // Double ornate antique border
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(theme.cardBorderColor, lineWidth: 1.2)
                RoundedRectangle(cornerRadius: max(2, radius - 3))
                    .stroke(theme.cardBorderColor.opacity(0.35), lineWidth: 0.8)
                    .padding(3)
            }
        case .medieval:
            // Forged iron & parchment dual contour
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(theme.cardBorderColor, lineWidth: 1.4)
                RoundedRectangle(cornerRadius: max(2, radius - 2))
                    .stroke(Color.black.opacity(0.5), lineWidth: 1)
                    .padding(2)
            }
        case .futuristic:
            // Crisp neon cyan cyber border with outer glow
            RoundedRectangle(cornerRadius: radius)
                .stroke(theme.cardBorderColor, lineWidth: 1.2)
                .corvusGlow(color: theme.accentPrimary, radius: 4, opacity: 0.45)
        default:
            RoundedRectangle(cornerRadius: radius)
                .stroke(theme.cardBorderColor, lineWidth: 1)
        }
    }
}

// MARK: - Theme Adaptive Glass Modifier
struct CorvusGlassModifier: ViewModifier {
    var radius: CGFloat? = nil
    var padding: CGFloat = 20
    
    var effectiveRadius: CGFloat {
        if let r = radius { return r }
        return AppTheme.activeTheme.defaultCornerRadius
    }
    
    func body(content: Content) -> some View {
        let theme = AppTheme.activeTheme
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: effectiveRadius)
                    .fill(theme.surface.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: effectiveRadius)
                    .stroke(
                        LinearGradient(
                            colors: [theme.cardBorderColor.opacity(0.6), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .modifier(ThemeShadowModifier(theme: theme))
    }
}

// MARK: - Live Service Pulsing Status Dot
struct StatusPulseDot: View {
    let status: Bool
    var customColor: Color? = nil
    var size: CGFloat = 8
    
    @State private var isPulsing: Bool = false
    
    var effectiveColor: Color {
        if let custom = customColor { return custom }
        return status ? AppTheme.accentGreen : AppTheme.accentRose
    }
    
    var body: some View {
        ZStack {
            if status {
                Circle()
                    .stroke(effectiveColor.opacity(isPulsing ? 0.0 : 0.65), lineWidth: 1.5)
                    .scaleEffect(isPulsing ? 2.3 : 1.0)
                    .frame(width: size, height: size)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                            isPulsing = true
                        }
                    }
            }
            
            Circle()
                .fill(effectiveColor)
                .frame(width: size, height: size)
                .corvusGlow(color: effectiveColor, radius: 4, opacity: status ? 0.6 : 0.2)
        }
    }
}

// MARK: - View Extension Helpers
extension View {
    func corvusCard(padding: CGFloat = 20, radius: CGFloat? = nil, isElevated: Bool = false) -> some View {
        modifier(CorvusCardModifier(radius: radius, padding: padding, isElevated: isElevated))
    }
    
    func corvusGlassCard(padding: CGFloat = 20, radius: CGFloat? = nil) -> some View {
        modifier(CorvusGlassModifier(radius: radius, padding: padding))
    }
    
    func corvusGlow(color: Color, radius: CGFloat = 8, opacity: Double = 0.35) -> some View {
        self.shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
    }
}

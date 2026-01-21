//
//  Theme.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let background = Color(hex: "0A0A0A")
        static let cardBackground = Color(hex: "1A1A1A")
        static let cardBackgroundElevated = Color(hex: "252525")
        
        // Text Colors
        static let textPrimary = Color(hex: "F5F5F5")
        static let textSecondary = Color(hex: "A0A0A0")
        static let textMuted = Color(hex: "606060")
        
        // Accent Colors
        static let accent = Color(hex: "E8E8E8")
        static let accentGold = Color(hex: "C9A962")
        static let accentHighlight = Color(hex: "FFFFFF")
        
        // State Colors
        static let playing = Color(hex: "4ADE80")
        static let stopped = Color(hex: "EF4444")
        static let selected = Color(hex: "3B82F6")
        
        // Border Colors
        static let border = Color(hex: "2A2A2A")
        static let borderLight = Color(hex: "3A3A3A")
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 14, weight: .medium, design: .rounded)
        static let bpmDisplay = Font.system(size: 72, weight: .bold, design: .monospaced)
        static let bpmLarge = Font.system(size: 48, weight: .bold, design: .monospaced)
        static let bpmMedium = Font.system(size: 32, weight: .bold, design: .monospaced)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
}

// MARK: - Color Extension
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

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    var isSelected: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ? AppTheme.Colors.cardBackgroundElevated : AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isActive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundColor(isActive ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isActive ? AppTheme.Colors.playing : AppTheme.Colors.cardBackgroundElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isActive ? AppTheme.Colors.playing : AppTheme.Colors.borderLight, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 60
    var isActive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundColor(isActive ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isActive ? AppTheme.Colors.playing : AppTheme.Colors.cardBackgroundElevated)
            )
            .overlay(
                Circle()
                    .stroke(isActive ? AppTheme.Colors.playing : AppTheme.Colors.borderLight, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle(isSelected: Bool = false) -> some View {
        modifier(CardStyle(isSelected: isSelected))
    }
}


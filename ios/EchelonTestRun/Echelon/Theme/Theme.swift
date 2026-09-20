import UIKit
import SwiftUI

enum AppTheme {
    // MARK: - Foundations: Colors
    enum Colors {
        static let background = UIColor(hex: "#0A0D14")
        static let glass = UIColor(hex: "#161D27")
        static let border = UIColor(hex: "#262E3B")
        
        static let blue = UIColor(hex: "#0A84FF")
        static let green = UIColor(hex: "#30D158")
        static let red = UIColor(hex: "#FF453A")
        static let yellow = UIColor(hex: "#FFD60A")
        static let cyan = UIColor(hex: "#5AC8FA")
        static let orange = UIColor(hex: "#FF9F0A")
        static let purple = UIColor(hex: "#BF5AF2")
        
        // Semantic aliases
        static let textPrimary = UIColor(hex: "#FFFFFF")
        static let textSecondary = UIColor(hex: "#8E9EAF")
        static let textTertiary = UIColor(hex: "#5A677B")
        
        static let cardBackground = UIColor(hex: "#151B26")
        static let pillBackground = UIColor(hex: "#1A2230")
        static let pillBorder = UIColor(hex: "#262E3B")
        static let greenGlow = UIColor(hex: "#30D158").withAlphaComponent(0.35)
        
        // Tags
        static let tagREU = cyan
        static let tagInternship = blue
        static let tagFellowship = orange
    }
    
    // MARK: - SwiftUI Color Palette
    enum SwiftUIColors {
        static let background = Color(AppTheme.Colors.background)
        static let glass = Color(AppTheme.Colors.glass)
        static let border = Color(AppTheme.Colors.border)
        static let blue = Color(AppTheme.Colors.blue)
        static let green = Color(AppTheme.Colors.green)
        static let red = Color(AppTheme.Colors.red)
        static let yellow = Color(AppTheme.Colors.yellow)
        static let cyan = Color(AppTheme.Colors.cyan)
        static let orange = Color(AppTheme.Colors.orange)
        static let purple = Color(AppTheme.Colors.purple)
        static let textPrimary = Color(AppTheme.Colors.textPrimary)
        static let textSecondary = Color(AppTheme.Colors.textSecondary)
        static let textTertiary = Color(AppTheme.Colors.textTertiary)
        static let cardBackground = Color(AppTheme.Colors.cardBackground)
        static let pillBackground = Color(AppTheme.Colors.pillBackground)
        static let pillBorder = Color(AppTheme.Colors.pillBorder)
    }
    
    // MARK: - Foundations: Typography (SF Pro)
    enum Typography {
        /// Display · 26 px
        static let display = UIFont.systemFont(ofSize: 26, weight: .bold)
        
        /// Title · 22 px
        static let title = UIFont.systemFont(ofSize: 22, weight: .bold)
        
        /// Card title · 17 px
        static let cardTitle = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let cardTitleBold = UIFont.systemFont(ofSize: 17, weight: .bold)
        
        /// Body · 13 px
        static let body = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let bodyMedium = UIFont.systemFont(ofSize: 13, weight: .medium)
        static let bodySemibold = UIFont.systemFont(ofSize: 13, weight: .semibold)
        
        /// Description · 12.5 px
        static let description = UIFont.systemFont(ofSize: 12.5, weight: .regular)
        
        /// Label · 11 px
        static let label = UIFont.systemFont(ofSize: 11, weight: .medium)
        static let labelBold = UIFont.systemFont(ofSize: 11, weight: .bold)
        
        /// Caption · 10 px
        static let caption = UIFont.systemFont(ofSize: 10, weight: .regular)
        static let captionBold = UIFont.systemFont(ofSize: 10, weight: .bold)
    }
    
    // MARK: - Foundations: Spacing
    // 4 / 6 / 8 / 10 / 12 / 16 / 20 / 24 / 28 / 32 / 40 / 48
    enum Spacing {
        static let s4: CGFloat = 4
        static let s6: CGFloat = 6
        static let s8: CGFloat = 8
        static let s10: CGFloat = 10
        static let s12: CGFloat = 12
        static let s14: CGFloat = 14
        static let s16: CGFloat = 16
        static let s18: CGFloat = 18
        static let s20: CGFloat = 20
        static let s24: CGFloat = 24
        static let s28: CGFloat = 28
        static let s32: CGFloat = 32
        static let s40: CGFloat = 40
        static let s48: CGFloat = 48
    }
    
    // MARK: - Foundations: Radii
    // 8 / 10 / 12 / 16 / 18 / 20 / 22 / 26 / 32 / 34 / 53 / pill
    enum Radii {
        static let r8: CGFloat = 8
        static let r10: CGFloat = 10
        static let r12: CGFloat = 12
        static let r16: CGFloat = 16
        static let r18: CGFloat = 18
        static let r20: CGFloat = 20
        static let r22: CGFloat = 22
        static let r26: CGFloat = 26
        static let r32: CGFloat = 32
        static let r34: CGFloat = 34
        static let r53: CGFloat = 53
        
        static func pill(forHeight height: CGFloat) -> CGFloat {
            return height / 2.0
        }
    }
    
    // MARK: - Foundations: Effects
    // Echelon/Glass — inner highlight and soft drop shadow
    enum Effects {
        static func applyEchelonGlass(
            to view: UIView,
            cornerRadius: CGFloat = Radii.r26,
            innerHighlight: Bool = true,
            softShadow: Bool = true
        ) {
            view.backgroundColor = Colors.glass.withAlphaComponent(0.88)
            view.layer.cornerRadius = cornerRadius
            
            if innerHighlight {
                view.layer.borderWidth = 1.0
                view.layer.borderColor = Colors.border.cgColor
            }
            
            if softShadow {
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.35
                view.layer.shadowOffset = CGSize(width: 0, height: 8)
                view.layer.shadowRadius = 16
                view.layer.masksToBounds = false
            }
        }
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.remove(at: cleanHex.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        
        let red, green, blue: CGFloat
        if cleanHex.count == 6 {
            red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        } else {
            red = 1.0; green = 1.0; blue = 1.0
        }
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

// MARK: - SwiftUI Color Hex Extension
extension Color {
    init(hex: String, opacity: Double = 1.0) {
        let uiColor = UIColor(hex: hex, alpha: CGFloat(opacity))
        self.init(uiColor)
    }
}

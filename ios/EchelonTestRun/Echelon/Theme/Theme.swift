import UIKit
import SwiftUI

enum AppTheme {
    // MARK: - Foundations: Colors (Apple Developer UIKit Palette)
    enum Colors {
        static let background = UIColor(hex: "#080B11")
        static let glass = UIColor(white: 0.12, alpha: 0.72)
        static let border = UIColor(white: 1.0, alpha: 0.14)
        
        static let blue = UIColor(hex: "#0A84FF")
        static let green = UIColor(hex: "#30D158")
        static let red = UIColor(hex: "#FF453A")
        static let yellow = UIColor(hex: "#FFD60A")
        static let cyan = UIColor(hex: "#5AC8FA")
        static let orange = UIColor(hex: "#FF9F0A")
        static let purple = UIColor(hex: "#BF5AF2")
        
        // Semantic aliases
        static let textPrimary = UIColor(white: 1.0, alpha: 0.98)
        static let textSecondary = UIColor(white: 1.0, alpha: 0.65)
        static let textTertiary = UIColor(white: 1.0, alpha: 0.42)
        
        static let cardBackground = UIColor(hex: "#121721")
        static let pillBackground = UIColor(white: 1.0, alpha: 0.08)
        static let pillBorder = UIColor(white: 1.0, alpha: 0.14)
        static let greenGlow = UIColor(hex: "#30D158").withAlphaComponent(0.35)
        
        // Tags
        static let tagREU = cyan
        static let tagInternship = blue
        static let tagFellowship = orange
    }
    
    // MARK: - SwiftUI Color Palette
    enum SwiftUIColors {
        static let background = Color(AppTheme.Colors.background)
        static let glass = Color.white.opacity(0.08)
        static let border = Color.white.opacity(0.14)
        static let blue = Color(AppTheme.Colors.blue)
        static let green = Color(AppTheme.Colors.green)
        static let red = Color(AppTheme.Colors.red)
        static let yellow = Color(AppTheme.Colors.yellow)
        static let cyan = Color(AppTheme.Colors.cyan)
        static let orange = Color(AppTheme.Colors.orange)
        static let purple = Color(AppTheme.Colors.purple)
        static let textPrimary = Color.white.opacity(0.98)
        static let textSecondary = Color.white.opacity(0.65)
        static let textTertiary = Color.white.opacity(0.42)
        static let cardBackground = Color(hex: "#121721")
        static let pillBackground = Color.white.opacity(0.08)
        static let pillBorder = Color.white.opacity(0.14)
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
    // Apple UIKit Liquid Glass & System Materials
    enum Effects {
        static func makeGlassEffect(style: UIBlurEffect.Style = .systemUltraThinMaterialDark) -> UIVisualEffect {
            if let glassClass = NSClassFromString("UIGlassEffect") as? NSObject.Type,
               let instance = glassClass.init() as? UIVisualEffect {
                return instance
            }
            return UIBlurEffect(style: style)
        }
        
        @discardableResult
        static func applyEchelonGlass(
            to view: UIView,
            cornerRadius: CGFloat = Radii.r26,
            innerHighlight: Bool = true,
            softShadow: Bool = true,
            blurStyle: UIBlurEffect.Style = .systemUltraThinMaterialDark,
            tintOpacity: CGFloat = 0.35
        ) -> UIVisualEffectView {
            view.backgroundColor = .clear
            view.layer.cornerRadius = cornerRadius
            view.layer.cornerCurve = .continuous
            
            // Remove existing glass view if re-applying
            view.viewWithTag(99901)?.removeFromSuperview()
            
            let blurEffect = makeGlassEffect(style: blurStyle)
            let effectView = UIVisualEffectView(effect: blurEffect)
            effectView.tag = 99901
            effectView.translatesAutoresizingMaskIntoConstraints = false
            effectView.layer.cornerRadius = cornerRadius
            effectView.layer.cornerCurve = .continuous
            effectView.clipsToBounds = true
            effectView.isUserInteractionEnabled = false
            
            // Subtle dark dimming layer (per Apple Liquid Glass HIG guidance for contrast over rich photos)
            let tintView = UIView()
            tintView.translatesAutoresizingMaskIntoConstraints = false
            tintView.backgroundColor = UIColor(white: 0.08, alpha: tintOpacity)
            tintView.isUserInteractionEnabled = false
            effectView.contentView.addSubview(tintView)
            
            NSLayoutConstraint.activate([
                tintView.topAnchor.constraint(equalTo: effectView.contentView.topAnchor),
                tintView.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor),
                tintView.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor),
                tintView.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor)
            ])
            
            view.insertSubview(effectView, at: 0)
            
            NSLayoutConstraint.activate([
                effectView.topAnchor.constraint(equalTo: view.topAnchor),
                effectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                effectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                effectView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            
            if innerHighlight {
                view.layer.borderWidth = 1.0
                view.layer.borderColor = Colors.border.cgColor
            } else {
                view.layer.borderWidth = 0
            }
            
            if softShadow {
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.32
                view.layer.shadowOffset = CGSize(width: 0, height: 8)
                view.layer.shadowRadius = 18
                view.layer.masksToBounds = false
            } else {
                view.layer.shadowOpacity = 0
            }
            
            return effectView
        }
    }
    
    // MARK: - SwiftUI Liquid Glass Modifiers
    struct LiquidGlassModifier: ViewModifier {
        var cornerRadius: CGFloat = 20
        var strokeColor: Color = Color.white.opacity(0.14)
        var shadowRadius: CGFloat = 14
        
        func body(content: Content) -> some View {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.25), radius: shadowRadius, x: 0, y: 6)
        }
    }
    
    struct LiquidGlassPillModifier: ViewModifier {
        var strokeColor: Color = Color.white.opacity(0.16)
        var shadowRadius: CGFloat = 8
        
        func body(content: Content) -> some View {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(strokeColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: shadowRadius, x: 0, y: 3)
        }
    }
}

// MARK: - View Extension for Liquid Glass
extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, strokeColor: Color = Color.white.opacity(0.14)) -> some View {
        modifier(AppTheme.LiquidGlassModifier(cornerRadius: cornerRadius, strokeColor: strokeColor))
    }
    
    func liquidGlassPill(strokeColor: Color = Color.white.opacity(0.16)) -> some View {
        modifier(AppTheme.LiquidGlassPillModifier(strokeColor: strokeColor))
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

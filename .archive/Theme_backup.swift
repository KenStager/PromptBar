import SwiftUI

struct Theme {
    // MARK: - Colors
    struct Colors {
        // Primary
        static let accent = Color.accentColor
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(NSColor.tertiaryLabelColor)
        
        // Backgrounds
        static let background = Color(NSColor.windowBackgroundColor)
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)
        static let selectedBackground = Color.blue.opacity(0.1)
        static let hoverBackground = Color.primary.opacity(0.05)
        
        // Status
        static let success = Color(NSColor.systemGreen)
        static let warning = Color(NSColor.systemOrange)
        static let error = Color(NSColor.systemRed)
        static let info = Color(NSColor.systemBlue)
        
        // Categories
        static let categoryColors: [String: Color] = [
            "Coding": Color.blue,
            "Writing": Color.purple,
            "Analysis": Color.green,
            "Creative": Color.orange,
            "Data": Color.indigo,
            "Other": Color.gray
        ]
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 20, weight: .semibold, design: .default)
        static let title = Font.system(size: 15, weight: .medium, design: .default)
        static let headline = Font.system(size: 13, weight: .medium, design: .default)
        static let body = Font.system(size: 13, weight: .regular, design: .default)
        static let callout = Font.system(size: 12, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let footnote = Font.system(size: 10, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }
    
    // MARK: - Shadows
    struct Shadows {
        static func small() -> some View {
            Color.black.opacity(0.1)
                .blur(radius: 2)
                .offset(x: 0, y: 1)
        }
        
        static func medium() -> some View {
            Color.black.opacity(0.15)
                .blur(radius: 4)
                .offset(x: 0, y: 2)
        }
        
        static func large() -> some View {
            Color.black.opacity(0.2)
                .blur(radius: 8)
                .offset(x: 0, y: 4)
        }
        
        // For use with .shadow() modifier
        static let smallRadius: CGFloat = 2
        static let mediumRadius: CGFloat = 4
        static let largeRadius: CGFloat = 8
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
    }
}

// MARK: - View Modifiers
extension View {
    func cardStyle(isSelected: Bool = false, isHovered: Bool = false) -> some View {
        self
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isSelected ? Theme.Colors.selectedBackground : 
                          isHovered ? Theme.Colors.hoverBackground : 
                          Theme.Colors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? Theme.Colors.accent.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: Theme.Shadows.smallRadius,
                x: 0,
                y: 1
            )
    }
    
    func primaryButton() -> some View {
        self
            .buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        self
            .buttonStyle(SecondaryButtonStyle())
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.body)
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(Theme.Colors.accent.opacity(isEnabled ? 1.0 : 0.5))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.body)
            .foregroundColor(Theme.Colors.primaryText)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    init(progress: Double, size: CGFloat = 20, lineWidth: CGFloat = 2) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    Theme.Colors.success,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animation.spring, value: progress)
            
            Text("\(Int(progress * 100))")
                .font(.system(size: size * 0.4, weight: .medium, design: .rounded))
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(width: size, height: size)
    }
}

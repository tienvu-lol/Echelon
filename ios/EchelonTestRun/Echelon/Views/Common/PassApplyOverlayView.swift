import UIKit

enum SwipeStampType {
    case pass
    case apply
}

class PassApplyOverlayView: UIView {
    private let stampLabel = UILabel()
    private let stampType: SwipeStampType
    
    init(type: SwipeStampType) {
        self.stampType = type
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UIColor.clear
        layer.borderWidth = 3.5
        layer.cornerRadius = AppTheme.Radii.r10
        layer.masksToBounds = true
        
        stampLabel.translatesAutoresizingMaskIntoConstraints = false
        // Typography: Display · 26 px
        stampLabel.font = AppTheme.Typography.display
        stampLabel.textAlignment = .center
        addSubview(stampLabel)
        
        NSLayoutConstraint.activate([
            stampLabel.topAnchor.constraint(equalTo: topAnchor, constant: AppTheme.Spacing.s4),
            stampLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AppTheme.Spacing.s4),
            stampLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppTheme.Spacing.s16),
            stampLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppTheme.Spacing.s16)
        ])
        
        switch stampType {
        case .pass:
            layer.borderColor = AppTheme.Colors.red.cgColor
            stampLabel.textColor = AppTheme.Colors.red
            stampLabel.text = "PASS"
            transform = CGAffineTransform(rotationAngle: -0.22) // ~ -12.5 deg
        case .apply:
            layer.borderColor = AppTheme.Colors.green.cgColor
            stampLabel.textColor = AppTheme.Colors.green
            stampLabel.text = "APPLY"
            transform = CGAffineTransform(rotationAngle: 0.22) // ~ +12.5 deg
        }
    }
}

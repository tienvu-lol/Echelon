import UIKit

class TagPillView: UIView {
    private let iconImageView = UIImageView()
    private let textLabel = UILabel()
    private let stackView = UIStackView()
    
    init(
        text: String,
        iconName: String? = nil,
        textColor: UIColor = AppTheme.Colors.textPrimary,
        backgroundColor: UIColor = AppTheme.Colors.pillBackground,
        borderColor: UIColor? = AppTheme.Colors.border,
        font: UIFont = AppTheme.Typography.label,
        cornerRadius: CGFloat = AppTheme.Radii.r16
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupViews(font: font, cornerRadius: cornerRadius)
        configure(
            text: text,
            iconName: iconName,
            textColor: textColor,
            backgroundColor: backgroundColor,
            borderColor: borderColor
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(font: UIFont, cornerRadius: CGFloat) {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = AppTheme.Spacing.s6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.isHidden = true
        stackView.addArrangedSubview(iconImageView)
        
        textLabel.font = font
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(textLabel)
        
        let bottomC = stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AppTheme.Spacing.s6)
        bottomC.priority = UILayoutPriority(999)
        let trailingC = stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppTheme.Spacing.s10)
        trailingC.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 12),
            iconImageView.heightAnchor.constraint(equalToConstant: 12),
            
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: AppTheme.Spacing.s6),
            bottomC,
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppTheme.Spacing.s10),
            trailingC
        ])
    }
    
    override var intrinsicContentSize: CGSize {
        let textSize = textLabel.intrinsicContentSize
        let iconWidth: CGFloat = iconImageView.isHidden ? 0 : 12 + AppTheme.Spacing.s6
        let width = textSize.width + iconWidth + AppTheme.Spacing.s10 * 2
        let height = max(textSize.height + AppTheme.Spacing.s6 * 2, 24)
        return CGSize(width: ceil(width), height: ceil(height))
    }
    
    func configure(
        text: String,
        iconName: String? = nil,
        textColor: UIColor = AppTheme.Colors.textPrimary,
        backgroundColor: UIColor = AppTheme.Colors.pillBackground,
        borderColor: UIColor? = AppTheme.Colors.border
    ) {
        self.backgroundColor = backgroundColor
        
        if let borderColor = borderColor {
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = 1.0
        } else {
            layer.borderWidth = 0
            layer.borderColor = nil
        }
        
        textLabel.text = text
        textLabel.textColor = textColor
        
        if let iconName = iconName {
            iconImageView.image = UIImage(systemName: iconName)
            iconImageView.tintColor = textColor
            iconImageView.isHidden = false
        } else {
            iconImageView.image = nil
            iconImageView.isHidden = true
        }
    }
}

/// A dynamic wrapping container that lays out tags horizontally and wraps to subsequent rows using Foundations spacing
class TagFlowView: UIView {
    var horizontalSpacing: CGFloat = AppTheme.Spacing.s8
    var verticalSpacing: CGFloat = AppTheme.Spacing.s8
    
    private var tagViews: [UIView] = []
    
    func setTags(_ tags: [String], customColor: UIColor? = nil) {
        tagViews.forEach { $0.removeFromSuperview() }
        tagViews.removeAll()
        
        for tag in tags {
            let pill = TagPillView(
                text: tag,
                textColor: customColor ?? AppTheme.Colors.textSecondary,
                backgroundColor: customColor?.withAlphaComponent(0.12) ?? AppTheme.Colors.pillBackground,
                borderColor: customColor?.withAlphaComponent(0.3) ?? AppTheme.Colors.border,
                font: AppTheme.Typography.label,
                cornerRadius: AppTheme.Radii.r16
            )
            addSubview(pill)
            tagViews.append(pill)
        }
        
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maxWidth = bounds.width
        guard maxWidth > 0 else { return }
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeightInRow: CGFloat = 0
        
        for view in tagViews {
            let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                // Wrap to next line
                currentX = 0
                currentY += maxHeightInRow + verticalSpacing
                maxHeightInRow = 0
            }
            
            view.frame = CGRect(x: currentX, y: currentY, width: size.width, height: size.height)
            currentX += size.width + horizontalSpacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let referenceWidth = bounds.width > 0 ? bounds.width : (superview?.bounds.width ?? window?.windowScene?.screen.bounds.width ?? 375)
        let maxWidth = max(referenceWidth - 64, 100)
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeightInRow: CGFloat = 0
        
        for view in tagViews {
            let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += maxHeightInRow + verticalSpacing
                maxHeightInRow = 0
            }
            currentX += size.width + horizontalSpacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
        
        let totalHeight = currentY + maxHeightInRow
        return CGSize(width: maxWidth, height: max(totalHeight, 28))
    }
}

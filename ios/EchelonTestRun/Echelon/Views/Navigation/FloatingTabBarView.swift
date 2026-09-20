import UIKit

protocol FloatingTabBarDelegate: AnyObject {
    func floatingTabBar(_ tabBar: FloatingTabBarView, didSelectTabAt index: Int)
}

class FloatingTabBarView: UIView {
    weak var delegate: FloatingTabBarDelegate?
    
    private let stackView = UIStackView()
    private var tabButtons: [UIButton] = []
    private var badgeLabels: [Int: UILabel] = [:]
    private var activeIndicator = UIView()
    private var selectedIndex: Int = 0
    
    private let tabs: [(title: String, icon: String)] = [
        ("Discover", "safari.fill"),
        ("Matches", "bolt.fill"),
        ("Profile", "person.crop.circle.fill")
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        // Echelon/Glass effect with soft drop shadow and Radii · 32 px
        AppTheme.Effects.applyEchelonGlass(to: self, cornerRadius: AppTheme.Radii.r32)
        
        // Active indicator pill
        activeIndicator.translatesAutoresizingMaskIntoConstraints = false
        activeIndicator.backgroundColor = UIColor(hex: "#222D3D")
        activeIndicator.layer.cornerRadius = AppTheme.Radii.r20
        activeIndicator.layer.borderWidth = 1.0
        activeIndicator.layer.borderColor = AppTheme.Colors.border.cgColor
        addSubview(activeIndicator)
        
        // Horizontal stack
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: AppTheme.Spacing.s6),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AppTheme.Spacing.s6),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppTheme.Spacing.s8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppTheme.Spacing.s8)
        ])
        
        for (index, tab) in tabs.enumerated() {
            let button = createTabButton(title: tab.title, icon: tab.icon, index: index)
            stackView.addArrangedSubview(button)
            tabButtons.append(button)
        }
        
        updateSelection(animated: false)
    }
    
    private func createTabButton(title: String, icon: String, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = index
        button.addTarget(self, action: #selector(didTapTab(_:)), for: .touchUpInside)
        
        let container = UIStackView()
        container.isUserInteractionEnabled = false
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .horizontal
        container.spacing = AppTheme.Spacing.s6
        container.alignment = .center
        button.addSubview(container)
        
        let imgView = UIImageView(image: UIImage(systemName: icon))
        imgView.tag = 100
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        container.addArrangedSubview(imgView)
        
        let label = UILabel()
        label.tag = 101
        label.text = title
        label.font = AppTheme.Typography.labelBold
        container.addArrangedSubview(label)
        
        // Badge view (for Matches tab)
        let badge = UILabel()
        badge.tag = 102
        badge.font = AppTheme.Typography.captionBold
        badge.textColor = .white
        badge.backgroundColor = AppTheme.Colors.red
        badge.textAlignment = .center
        badge.layer.cornerRadius = AppTheme.Radii.r8
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.isHidden = true
        button.addSubview(badge)
        badgeLabels[index] = badge
        
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            badge.topAnchor.constraint(equalTo: button.topAnchor, constant: AppTheme.Spacing.s6),
            badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -AppTheme.Spacing.s8),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            badge.heightAnchor.constraint(equalToConstant: 18)
        ])
        
        return button
    }
    
    func setBadgeCount(_ count: Int, forTabAt index: Int) {
        guard let badge = badgeLabels[index] else { return }
        if count > 0 {
            badge.text = "\(count)"
            badge.isHidden = false
        } else {
            badge.isHidden = true
        }
    }
    
    @objc private func didTapTab(_ sender: UIButton) {
        let index = sender.tag
        guard index != selectedIndex else { return }
        
        selectedIndex = index
        updateSelection(animated: true)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        delegate?.floatingTabBar(self, didSelectTabAt: index)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: AppTheme.Radii.r32).cgPath
        updateIndicatorPosition(animated: false)
    }
    
    private func updateSelection(animated: Bool) {
        for (idx, btn) in tabButtons.enumerated() {
            let isSelected = (idx == selectedIndex)
            let iconView = btn.viewWithTag(100) as? UIImageView
            let label = btn.viewWithTag(101) as? UILabel
            
            UIView.animate(withDuration: animated ? 0.25 : 0) {
                let color = isSelected ? AppTheme.Colors.blue : AppTheme.Colors.textSecondary
                iconView?.tintColor = color
                label?.textColor = isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary
                label?.font = isSelected ? AppTheme.Typography.labelBold : AppTheme.Typography.label
            }
        }
        updateIndicatorPosition(animated: animated)
    }
    
    private func updateIndicatorPosition(animated: Bool) {
        guard selectedIndex < tabButtons.count else { return }
        let targetButton = tabButtons[selectedIndex]
        guard targetButton.bounds.width > 0 else { return }
        
        let convertedFrame = targetButton.convert(targetButton.bounds, to: self)
        let targetFrame = convertedFrame.insetBy(dx: AppTheme.Spacing.s4, dy: AppTheme.Spacing.s4)
        
        if animated {
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.78,
                initialSpringVelocity: 0.4,
                options: [.curveEaseInOut],
                animations: {
                    self.activeIndicator.frame = targetFrame
                }
            )
        } else {
            self.activeIndicator.frame = targetFrame
        }
    }
}

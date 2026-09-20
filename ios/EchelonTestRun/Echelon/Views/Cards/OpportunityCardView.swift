import UIKit

protocol OpportunityCardDelegate: AnyObject {
    func cardDidSwipeLeft(_ card: OpportunityCardView)
    func cardDidSwipeRight(_ card: OpportunityCardView)
    func cardDidTapInfo(_ card: OpportunityCardView)
}

class OpportunityCardView: UIView {
    weak var delegate: OpportunityCardDelegate?
    
    let opportunity: OpportunityCard
    
    // UI Elements
    private let cardContentView = UIView()
    private let backgroundImageView = UIImageView()
    private let gradientOverlayView = UIView()
    private let gradientLayer = CAGradientLayer()
    
    // Top Bar
    private let orgPillView = UIView()
    private let orgIconImageView = UIImageView()
    private let orgNameLabel = UILabel()
    private let orgLocationLabel = UILabel()
    private let matchScoreView = CircularProgressView()
    
    // Stamp Overlays
    private let passStamp = PassApplyOverlayView(type: .pass)
    private let applyStamp = PassApplyOverlayView(type: .apply)
    
    // Bottom Container
    private let bottomContainerView = UIView()
    private let typePill = TagPillView(
        text: "Opportunity",
        iconName: "briefcase.fill",
        textColor: AppTheme.Colors.cyan,
        backgroundColor: AppTheme.Colors.cyan.withAlphaComponent(0.15),
        borderColor: AppTheme.Colors.cyan.withAlphaComponent(0.4),
        font: AppTheme.Typography.labelBold,
        cornerRadius: AppTheme.Radii.r12
    )
    private let titleLabel = UILabel()
    private let infoRowStack = UIStackView()
    private let skillsStackView = UIStackView()
    private let descriptionLabel = UILabel()
    private let footerStack = UIStackView()
    private let deadlineLabel = UILabel()
    private let perksButton = UIButton(type: .system)
    
    // Gesture & Animation tracking
    private var panGesture: UIPanGestureRecognizer?
    private var originalCenter: CGPoint = .zero
    private let swipeThreshold: CGFloat = 110.0
    private var isAnimatingSwipe = false
    
    init(opportunity: OpportunityCard) {
        self.opportunity = opportunity
        super.init(frame: .zero)
        setupCard()
        configure(with: opportunity)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientOverlayView.bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: AppTheme.Radii.r26).cgPath
    }
    
    private func setupCard() {
        backgroundColor = .clear
        
        // Outer Shadow (Soft drop shadow from Foundations)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 16
        
        // Main Container using Radii · 26 px
        cardContentView.translatesAutoresizingMaskIntoConstraints = false
        cardContentView.backgroundColor = AppTheme.Colors.cardBackground
        cardContentView.layer.cornerRadius = AppTheme.Radii.r26
        cardContentView.layer.borderWidth = 1.0
        cardContentView.layer.borderColor = AppTheme.Colors.border.cgColor
        cardContentView.layer.masksToBounds = true
        addSubview(cardContentView)
        
        // Background subtle graphic / backdrop
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.image = UIImage(systemName: "building.2.crop.circle")
        backgroundImageView.tintColor = AppTheme.Colors.glass.withAlphaComponent(0.4)
        cardContentView.addSubview(backgroundImageView)
        
        // Dark gradient to ensure high contrast
        gradientLayer.colors = [
            AppTheme.Colors.background.withAlphaComponent(0.7).cgColor,
            AppTheme.Colors.background.withAlphaComponent(0.95).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientOverlayView.layer.addSublayer(gradientLayer)
        gradientOverlayView.translatesAutoresizingMaskIntoConstraints = false
        gradientOverlayView.isUserInteractionEnabled = false
        cardContentView.addSubview(gradientOverlayView)
        
        setupTopBar()
        setupBottomPanel()
        setupStamps()
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            cardContentView.topAnchor.constraint(equalTo: topAnchor),
            cardContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cardContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            backgroundImageView.topAnchor.constraint(equalTo: cardContentView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor),
            backgroundImageView.heightAnchor.constraint(equalTo: cardContentView.heightAnchor, multiplier: 0.6),
            
            gradientOverlayView.topAnchor.constraint(equalTo: cardContentView.topAnchor),
            gradientOverlayView.bottomAnchor.constraint(equalTo: cardContentView.bottomAnchor),
            gradientOverlayView.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor),
            gradientOverlayView.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor)
        ])
        
        // Pan Gesture
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.panGesture = pan
        addGestureRecognizer(pan)
    }
    
    private func setupTopBar() {
        // Org Pill (Left) with Glass Effect and Radii · 20 px
        orgPillView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.Effects.applyEchelonGlass(to: orgPillView, cornerRadius: AppTheme.Radii.r20)
        cardContentView.addSubview(orgPillView)
        
        // Org Icon
        orgIconImageView.translatesAutoresizingMaskIntoConstraints = false
        orgIconImageView.contentMode = .scaleAspectFit
        orgIconImageView.tintColor = AppTheme.Colors.green
        orgIconImageView.backgroundColor = AppTheme.Colors.pillBackground
        orgIconImageView.layer.cornerRadius = AppTheme.Radii.r12
        orgIconImageView.layer.masksToBounds = true
        orgPillView.addSubview(orgIconImageView)
        
        // Text Stack in Org Pill
        let orgTextStack = UIStackView()
        orgTextStack.axis = .vertical
        orgTextStack.spacing = 1
        orgTextStack.translatesAutoresizingMaskIntoConstraints = false
        orgPillView.addSubview(orgTextStack)
        
        // Typography · Body Semibold (13 px)
        orgNameLabel.font = AppTheme.Typography.bodySemibold
        orgNameLabel.textColor = AppTheme.Colors.textPrimary
        orgTextStack.addArrangedSubview(orgNameLabel)
        
        // Typography · Label (11 px)
        orgLocationLabel.font = AppTheme.Typography.label
        orgLocationLabel.textColor = AppTheme.Colors.textSecondary
        orgTextStack.addArrangedSubview(orgLocationLabel)
        
        // Circular Match Progress (Right)
        matchScoreView.translatesAutoresizingMaskIntoConstraints = false
        cardContentView.addSubview(matchScoreView)
        
        NSLayoutConstraint.activate([
            orgPillView.topAnchor.constraint(equalTo: cardContentView.topAnchor, constant: AppTheme.Spacing.s16),
            orgPillView.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor, constant: AppTheme.Spacing.s16),
            orgPillView.heightAnchor.constraint(equalToConstant: 44),
            
            orgIconImageView.leadingAnchor.constraint(equalTo: orgPillView.leadingAnchor, constant: AppTheme.Spacing.s8),
            orgIconImageView.centerYAnchor.constraint(equalTo: orgPillView.centerYAnchor),
            orgIconImageView.widthAnchor.constraint(equalToConstant: 28),
            orgIconImageView.heightAnchor.constraint(equalToConstant: 28),
            
            orgTextStack.leadingAnchor.constraint(equalTo: orgIconImageView.trailingAnchor, constant: AppTheme.Spacing.s8),
            orgTextStack.trailingAnchor.constraint(equalTo: orgPillView.trailingAnchor, constant: -AppTheme.Spacing.s12),
            orgTextStack.centerYAnchor.constraint(equalTo: orgPillView.centerYAnchor),
            
            matchScoreView.topAnchor.constraint(equalTo: cardContentView.topAnchor, constant: AppTheme.Spacing.s16),
            matchScoreView.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor, constant: -AppTheme.Spacing.s16),
            matchScoreView.widthAnchor.constraint(equalToConstant: 44),
            matchScoreView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupBottomPanel() {
        // Bottom Container with Echelon/Glass effect and Radii · 22 px
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.Effects.applyEchelonGlass(to: bottomContainerView, cornerRadius: AppTheme.Radii.r22)
        cardContentView.addSubview(bottomContainerView)
        
        typePill.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(typePill)
        
        // Typography · Card title · 17 px (bold) / Title · 22 px
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = AppTheme.Typography.cardTitleBold
        titleLabel.textColor = AppTheme.Colors.textPrimary
        titleLabel.numberOfLines = 2
        bottomContainerView.addSubview(titleLabel)
        
        infoRowStack.translatesAutoresizingMaskIntoConstraints = false
        infoRowStack.axis = .horizontal
        infoRowStack.spacing = AppTheme.Spacing.s12
        infoRowStack.alignment = .center
        bottomContainerView.addSubview(infoRowStack)
        
        // Skills Horizontal Stack
        skillsStackView.translatesAutoresizingMaskIntoConstraints = false
        skillsStackView.axis = .horizontal
        skillsStackView.spacing = AppTheme.Spacing.s6
        skillsStackView.alignment = .center
        bottomContainerView.addSubview(skillsStackView)
        
        // Typography · Description · 12.5 px
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = AppTheme.Typography.description
        descriptionLabel.textColor = AppTheme.Colors.textSecondary
        descriptionLabel.numberOfLines = 3
        bottomContainerView.addSubview(descriptionLabel)
        
        // Footer (Deadline + Perks)
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        footerStack.axis = .horizontal
        footerStack.distribution = .equalSpacing
        footerStack.alignment = .center
        bottomContainerView.addSubview(footerStack)
        
        // Typography · Label · 11 px
        deadlineLabel.font = AppTheme.Typography.label
        deadlineLabel.textColor = AppTheme.Colors.textSecondary
        footerStack.addArrangedSubview(deadlineLabel)
        
        perksButton.setTitle("↓ Perks", for: .normal)
        perksButton.titleLabel?.font = AppTheme.Typography.labelBold
        perksButton.setTitleColor(AppTheme.Colors.textSecondary, for: .normal)
        perksButton.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)
        footerStack.addArrangedSubview(perksButton)
        
        NSLayoutConstraint.activate([
            bottomContainerView.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor, constant: AppTheme.Spacing.s12),
            bottomContainerView.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor, constant: -AppTheme.Spacing.s12),
            bottomContainerView.bottomAnchor.constraint(equalTo: cardContentView.bottomAnchor, constant: -AppTheme.Spacing.s12),
            bottomContainerView.topAnchor.constraint(greaterThanOrEqualTo: orgPillView.bottomAnchor, constant: AppTheme.Spacing.s12),
            
            typePill.topAnchor.constraint(equalTo: bottomContainerView.topAnchor, constant: AppTheme.Spacing.s12),
            typePill.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: AppTheme.Spacing.s12),
            
            titleLabel.topAnchor.constraint(equalTo: typePill.bottomAnchor, constant: AppTheme.Spacing.s8),
            titleLabel.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: AppTheme.Spacing.s12),
            titleLabel.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -AppTheme.Spacing.s12),
            
            infoRowStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppTheme.Spacing.s8),
            infoRowStack.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: AppTheme.Spacing.s12),
            infoRowStack.trailingAnchor.constraint(lessThanOrEqualTo: bottomContainerView.trailingAnchor, constant: -AppTheme.Spacing.s12),
            
            skillsStackView.topAnchor.constraint(equalTo: infoRowStack.bottomAnchor, constant: AppTheme.Spacing.s10),
            skillsStackView.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: AppTheme.Spacing.s12),
            skillsStackView.trailingAnchor.constraint(lessThanOrEqualTo: bottomContainerView.trailingAnchor, constant: -AppTheme.Spacing.s12),
            skillsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            
            descriptionLabel.topAnchor.constraint(equalTo: skillsStackView.bottomAnchor, constant: AppTheme.Spacing.s10),
            descriptionLabel.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: AppTheme.Spacing.s12),
            descriptionLabel.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -AppTheme.Spacing.s12),
            
            footerStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: AppTheme.Spacing.s12),
            footerStack.leadingAnchor.constraint(equalTo: bottomContainerView.leadingAnchor, constant: AppTheme.Spacing.s12),
            footerStack.trailingAnchor.constraint(equalTo: bottomContainerView.trailingAnchor, constant: -AppTheme.Spacing.s12),
            footerStack.bottomAnchor.constraint(equalTo: bottomContainerView.bottomAnchor, constant: -AppTheme.Spacing.s12)
        ])
    }
    
    private func setupStamps() {
        passStamp.translatesAutoresizingMaskIntoConstraints = false
        passStamp.alpha = 0
        cardContentView.addSubview(passStamp)
        
        applyStamp.translatesAutoresizingMaskIntoConstraints = false
        applyStamp.alpha = 0
        cardContentView.addSubview(applyStamp)
        
        NSLayoutConstraint.activate([
            passStamp.topAnchor.constraint(equalTo: cardContentView.topAnchor, constant: AppTheme.Spacing.s48),
            passStamp.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor, constant: -AppTheme.Spacing.s32),
            
            applyStamp.topAnchor.constraint(equalTo: cardContentView.topAnchor, constant: AppTheme.Spacing.s48),
            applyStamp.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor, constant: AppTheme.Spacing.s32)
        ])
    }
    
    private func configure(with opp: OpportunityCard) {
        orgNameLabel.text = opp.organization
        orgLocationLabel.text = opp.location ?? "Remote"
        
        let iconName = opp.companyLogoName ?? "shield.lefthalf.filled"
        orgIconImageView.image = UIImage(systemName: iconName)
        
        if let match = opp.matchPercentage {
            matchScoreView.percentage = match
        } else {
            matchScoreView.percentage = 80
        }
        
        // Configure Type Pill dynamically
        let pillColor: UIColor
        let pillIcon: String
        switch opp.opportunityType.lowercased() {
        case "reu":
            pillColor = AppTheme.Colors.cyan
            pillIcon = "flask.fill"
        case "fellowship":
            pillColor = AppTheme.Colors.orange
            pillIcon = "sparkles"
        case "internship":
            pillColor = AppTheme.Colors.blue
            pillIcon = "briefcase.fill"
        default:
            pillColor = AppTheme.Colors.purple
            pillIcon = "tag.fill"
        }
        typePill.configure(
            text: opp.opportunityType.uppercased(),
            iconName: pillIcon,
            textColor: pillColor,
            backgroundColor: pillColor.withAlphaComponent(0.15),
            borderColor: pillColor.withAlphaComponent(0.4)
        )
        
        titleLabel.text = opp.title
        descriptionLabel.text = opp.description
        
        // Info Row items (Typography · Label 11 px)
        infoRowStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let location = opp.location {
            let locView = makeInfoBadge(icon: "mappin.and.ellipse", text: location)
            infoRowStack.addArrangedSubview(locView)
        }
        if let comp = opp.compensation {
            let compView = makeInfoBadge(icon: "dollarsign.circle.fill", text: comp)
            infoRowStack.addArrangedSubview(compView)
        }
        if let dur = opp.duration {
            let durView = makeInfoBadge(icon: "clock.fill", text: dur)
            infoRowStack.addArrangedSubview(durView)
        }
        
        // Skills Pills
        skillsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for skill in opp.skills.prefix(4) {
            let pill = TagPillView(
                text: skill,
                textColor: AppTheme.Colors.textPrimary,
                backgroundColor: AppTheme.Colors.pillBackground,
                borderColor: AppTheme.Colors.border,
                font: AppTheme.Typography.label,
                cornerRadius: AppTheme.Radii.r12
            )
            skillsStackView.addArrangedSubview(pill)
        }
        
        // Deadline
        if let deadline = opp.deadline {
            let attributed = NSMutableAttributedString(
                string: "Deadline ",
                attributes: [.foregroundColor: AppTheme.Colors.textSecondary, .font: AppTheme.Typography.label]
            )
            attributed.append(NSAttributedString(
                string: deadline,
                attributes: [.foregroundColor: AppTheme.Colors.textPrimary, .font: AppTheme.Typography.labelBold]
            ))
            deadlineLabel.attributedText = attributed
        } else {
            deadlineLabel.text = "Rolling Applications"
            deadlineLabel.font = AppTheme.Typography.label
        }
    }
    
    private func makeInfoBadge(icon: String, text: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = AppTheme.Spacing.s4
        stack.alignment = .center
        
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = AppTheme.Colors.textSecondary
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        img.widthAnchor.constraint(equalToConstant: 12).isActive = true
        img.heightAnchor.constraint(equalToConstant: 12).isActive = true
        stack.addArrangedSubview(img)
        
        let lbl = UILabel()
        lbl.text = text
        lbl.font = AppTheme.Typography.label
        lbl.textColor = AppTheme.Colors.textSecondary
        stack.addArrangedSubview(lbl)
        
        return stack
    }
    
    // MARK: - Pan Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isAnimatingSwipe else { return }
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .began:
            originalCenter = center
        case .changed:
            let xOffset = translation.x
            let rotationStrength = min(xOffset / (bounds.width * 1.5), 1.0)
            let rotationAngle = rotationStrength * (CGFloat.pi / 10)
            
            center = CGPoint(x: originalCenter.x + xOffset, y: originalCenter.y + translation.y * 0.4)
            transform = CGAffineTransform(rotationAngle: rotationAngle)
            
            // Stamp alpha
            if xOffset > 0 {
                applyStamp.alpha = min(xOffset / swipeThreshold, 1.0)
                passStamp.alpha = 0
            } else {
                passStamp.alpha = min(-xOffset / swipeThreshold, 1.0)
                applyStamp.alpha = 0
            }
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: superview)
            if translation.x > swipeThreshold || velocity.x > 750 {
                animateSwipe(direction: .apply)
            } else if translation.x < -swipeThreshold || velocity.x < -750 {
                animateSwipe(direction: .pass)
            } else {
                resetCardPosition()
            }
        default:
            break
        }
    }
    
    private func resetCardPosition() {
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut],
            animations: {
                self.center = self.originalCenter
                self.transform = .identity
                self.passStamp.alpha = 0
                self.applyStamp.alpha = 0
            }
        )
    }
    
    func swipeLeft() {
        guard !isAnimatingSwipe else { return }
        animateSwipe(direction: .pass)
    }
    
    func swipeRight() {
        guard !isAnimatingSwipe else { return }
        animateSwipe(direction: .apply)
    }
    
    private func animateSwipe(direction: SwipeStampType) {
        guard !isAnimatingSwipe else { return }
        isAnimatingSwipe = true
        isUserInteractionEnabled = false
        
        let screenWidth = window?.windowScene?.screen.bounds.width ?? superview?.bounds.width ?? 375
        let translationX: CGFloat = direction == .apply ? screenWidth * 1.4 : -screenWidth * 1.4
        let rotationAngle: CGFloat = direction == .apply ? 0.35 : -0.35
        
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                if direction == .apply {
                    self.applyStamp.alpha = 1.0
                } else {
                    self.passStamp.alpha = 1.0
                }
                self.center = CGPoint(x: self.originalCenter.x + translationX, y: self.originalCenter.y + 40)
                self.transform = CGAffineTransform(rotationAngle: rotationAngle)
            },
            completion: { _ in
                self.removeFromSuperview()
                if direction == .apply {
                    self.delegate?.cardDidSwipeRight(self)
                } else {
                    self.delegate?.cardDidSwipeLeft(self)
                }
            }
        )
    }
    
    @objc private func didTapInfo() {
        delegate?.cardDidTapInfo(self)
    }
}

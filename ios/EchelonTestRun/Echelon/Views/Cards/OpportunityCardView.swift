import UIKit

protocol OpportunityCardDelegate: AnyObject {
    func cardDidSwipeLeft(_ card: OpportunityCardView)
    func cardDidSwipeRight(_ card: OpportunityCardView)
    func cardDidTap(_ card: OpportunityCardView)
    func cardDidTapInfo(_ card: OpportunityCardView)
}

class OpportunityCardView: UIView, UIGestureRecognizerDelegate {
    weak var delegate: OpportunityCardDelegate?
    
    let opportunity: OpportunityCard
    
    // UI Elements
    private let cardContentView = UIView()
    private let backgroundImageView = UIImageView()
    private let imagePlaceholderView = UIView()
    private let gradientOverlayView = UIView()
    private let gradientLayer = CAGradientLayer()
    
    // Top Bar Floating Glass
    private let orgPillView = UIView()
    private let orgIconImageView = UIImageView()
    private let orgNameLabel = UILabel()
    private let orgLocationLabel = UILabel()
    private let matchScoreView = CircularProgressView()
    
    // Bottom Sheet Floating Glass
    private let bottomContainerView = UIView()
    private let typePill = TagPillView(text: "")
    private let titleLabel = UILabel()
    private let infoRowStack = UIStackView()
    private let skillsStackView = UIStackView()
    private let descriptionLabel = UILabel()
    private let footerStack = UIStackView()
    private let deadlineLabel = UILabel()
    private let viewDetailsButton = UIButton(type: .system)
    
    // Stamps
    private let passStamp = PassApplyOverlayView(type: .pass)
    private let matchStamp = PassApplyOverlayView(type: .match)
    
    // Gesture & State
    private var panGesture: UIPanGestureRecognizer?
    private var tapGesture: UITapGestureRecognizer?
    private var originalCenter: CGPoint = .zero
    private var isAnimatingSwipe = false
    private let swipeThreshold: CGFloat = 110.0
    
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
        
        // Outer Shadow per Apple HIG floating layer
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 22
        layer.masksToBounds = false
        
        // Main Container using Radii · 26 px with continuous corner curves
        cardContentView.translatesAutoresizingMaskIntoConstraints = false
        cardContentView.backgroundColor = AppTheme.Colors.cardBackground
        cardContentView.layer.cornerRadius = AppTheme.Radii.r26
        cardContentView.layer.cornerCurve = .continuous
        cardContentView.layer.borderWidth = 1.0
        cardContentView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        cardContentView.layer.masksToBounds = true
        addSubview(cardContentView)
        
        // Placeholder background view
        imagePlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        imagePlaceholderView.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        cardContentView.addSubview(imagePlaceholderView)
        
        // Background remote image / backdrop
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        cardContentView.addSubview(backgroundImageView)
        
        // Subtle optical vignette gradient allowing background photo to shine through
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.08).cgColor,
            UIColor.black.withAlphaComponent(0.35).cgColor,
            UIColor.black.withAlphaComponent(0.85).cgColor
        ]
        gradientLayer.locations = [0.0, 0.40, 1.0]
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
            
            imagePlaceholderView.topAnchor.constraint(equalTo: cardContentView.topAnchor),
            imagePlaceholderView.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor),
            imagePlaceholderView.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor),
            imagePlaceholderView.heightAnchor.constraint(equalTo: cardContentView.heightAnchor, multiplier: 0.62),
            
            backgroundImageView.topAnchor.constraint(equalTo: cardContentView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor),
            backgroundImageView.heightAnchor.constraint(equalTo: cardContentView.heightAnchor, multiplier: 0.62),
            
            gradientOverlayView.topAnchor.constraint(equalTo: cardContentView.topAnchor),
            gradientOverlayView.bottomAnchor.constraint(equalTo: cardContentView.bottomAnchor),
            gradientOverlayView.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor),
            gradientOverlayView.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor)
        ])
        
        // Pan Gesture (Horizontal Swipe)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        self.panGesture = pan
        addGestureRecognizer(pan)
        
        // Tap Gesture (Opens Opportunity Detail)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCardTap(_:)))
        tap.cancelsTouchesInView = false
        self.tapGesture = tap
        addGestureRecognizer(tap)
    }
    
    private func setupTopBar() {
        // Org Pill (Left) with Apple UIKit Liquid Glass Effect
        orgPillView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.Effects.applyEchelonGlass(
            to: orgPillView,
            cornerRadius: AppTheme.Radii.r22,
            innerHighlight: true,
            softShadow: true,
            blurStyle: .systemUltraThinMaterialDark,
            tintOpacity: 0.25
        )
        cardContentView.addSubview(orgPillView)
        
        // Org Icon
        orgIconImageView.translatesAutoresizingMaskIntoConstraints = false
        orgIconImageView.contentMode = .scaleAspectFit
        orgIconImageView.tintColor = AppTheme.Colors.green
        orgIconImageView.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        orgIconImageView.layer.cornerRadius = AppTheme.Radii.r12
        orgIconImageView.layer.cornerCurve = .continuous
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
        
        // Circular Match Progress with Liquid Glass (Right)
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
        // Bottom Container with Apple UIKit Liquid Glass effect and Radii · 22 px
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.Effects.applyEchelonGlass(
            to: bottomContainerView,
            cornerRadius: AppTheme.Radii.r22,
            innerHighlight: true,
            softShadow: true,
            blurStyle: .systemThinMaterialDark,
            tintOpacity: 0.40
        )
        cardContentView.addSubview(bottomContainerView)
        
        typePill.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(typePill)
        
        // Typography · Card title · 17 px (bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = AppTheme.Typography.cardTitleBold
        titleLabel.textColor = AppTheme.Colors.textPrimary
        titleLabel.numberOfLines = 2
        bottomContainerView.addSubview(titleLabel)
        
        infoRowStack.translatesAutoresizingMaskIntoConstraints = false
        infoRowStack.axis = .horizontal
        infoRowStack.spacing = AppTheme.Spacing.s10
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
        
        // Footer (Deadline + View Details)
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        footerStack.axis = .horizontal
        footerStack.distribution = .equalSpacing
        footerStack.alignment = .center
        bottomContainerView.addSubview(footerStack)
        
        // Typography · Label · 11 px
        deadlineLabel.font = AppTheme.Typography.label
        deadlineLabel.textColor = AppTheme.Colors.textSecondary
        footerStack.addArrangedSubview(deadlineLabel)
        
        // Modern Apple Button Configuration for Details
        var detailsConfig = UIButton.Configuration.tinted()
        detailsConfig.title = "Details"
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        detailsConfig.image = UIImage(systemName: "chevron.right", withConfiguration: symbolConfig)
        detailsConfig.imagePlacement = .trailing
        detailsConfig.imagePadding = 4
        detailsConfig.cornerStyle = .capsule
        detailsConfig.baseForegroundColor = AppTheme.Colors.cyan
        detailsConfig.baseBackgroundColor = AppTheme.Colors.cyan.withAlphaComponent(0.16)
        detailsConfig.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12)
        viewDetailsButton.configuration = detailsConfig
        viewDetailsButton.addTarget(self, action: #selector(didTapDetails), for: .touchUpInside)
        footerStack.addArrangedSubview(viewDetailsButton)
        
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
        
        matchStamp.translatesAutoresizingMaskIntoConstraints = false
        matchStamp.alpha = 0
        cardContentView.addSubview(matchStamp)
        
        NSLayoutConstraint.activate([
            passStamp.topAnchor.constraint(equalTo: cardContentView.topAnchor, constant: AppTheme.Spacing.s48),
            passStamp.trailingAnchor.constraint(equalTo: cardContentView.trailingAnchor, constant: -AppTheme.Spacing.s32),
            
            matchStamp.topAnchor.constraint(equalTo: cardContentView.topAnchor, constant: AppTheme.Spacing.s48),
            matchStamp.leadingAnchor.constraint(equalTo: cardContentView.leadingAnchor, constant: AppTheme.Spacing.s32)
        ])
    }
    
    private func configure(with opp: OpportunityCard) {
        orgNameLabel.text = opp.organization
        orgLocationLabel.text = opp.location
        orgLocationLabel.isHidden = opp.location == nil
        
        // Remote Image Loading for Opportunity
        if let imageUrl = opp.imageUrl, !imageUrl.isEmpty {
            ImageLoader.shared.loadImage(from: imageUrl) { [weak self] image in
                if let loadedImage = image {
                    self?.backgroundImageView.image = loadedImage
                } else {
                    self?.backgroundImageView.image = UIImage(systemName: "building.2.crop.circle")
                }
            }
        } else {
            backgroundImageView.image = UIImage(systemName: "building.2.crop.circle")
        }
        
        // Org Logo or Symbol
        if let logoUrl = opp.organizationLogoUrl, !logoUrl.isEmpty {
            ImageLoader.shared.loadImage(from: logoUrl) { [weak self] img in
                if let img = img {
                    self?.orgIconImageView.image = img
                }
            }
        } else {
            let iconName = opp.companyLogoName ?? "shield.lefthalf.filled"
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            orgIconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        }
        
        if let match = opp.matchPercentage {
            matchScoreView.percentage = match
            matchScoreView.isHidden = false
        } else {
            matchScoreView.isHidden = true
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
        descriptionLabel.text = opp.explanation?.isEmpty == false
            ? opp.explanation
            : opp.description
        
        // Info Row items
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
            deadlineLabel.attributedText = nil
            deadlineLabel.text = nil
        }
    }
    
    private func makeInfoBadge(icon: String, text: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = AppTheme.Spacing.s4
        stack.alignment = .center
        
        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        let img = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
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
    
    // MARK: - Pan Gesture Handling (Horizontal Swiping Only, No Swipe Down)
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
            
            // Subtly track y movement for fluid tilt, but NEVER trigger vertical actions
            center = CGPoint(x: originalCenter.x + xOffset, y: originalCenter.y + translation.y * 0.25)
            transform = CGAffineTransform(rotationAngle: rotationAngle)
            
            // Stamp alpha based strictly on horizontal threshold
            if xOffset > 0 {
                matchStamp.alpha = min(xOffset / swipeThreshold, 1.0)
                passStamp.alpha = 0
            } else {
                passStamp.alpha = min(-xOffset / swipeThreshold, 1.0)
                matchStamp.alpha = 0
            }
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: superview)
            // Strict horizontal threshold and velocity
            if translation.x > swipeThreshold || velocity.x > 800 {
                animateSwipe(direction: .match)
            } else if translation.x < -swipeThreshold || velocity.x < -800 {
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
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.78,
            initialSpringVelocity: 0.4,
            options: [.curveEaseOut],
            animations: {
                self.center = self.originalCenter
                self.transform = .identity
                self.passStamp.alpha = 0
                self.matchStamp.alpha = 0
            }
        )
    }
    
    func swipeLeft() {
        guard !isAnimatingSwipe else { return }
        animateSwipe(direction: .pass)
    }
    
    func swipeRight() {
        guard !isAnimatingSwipe else { return }
        animateSwipe(direction: .match)
    }
    
    private func animateSwipe(direction: SwipeStampType) {
        guard !isAnimatingSwipe else { return }
        isAnimatingSwipe = true
        isUserInteractionEnabled = false
        
        let screenWidth = window?.windowScene?.screen.bounds.width ?? superview?.bounds.width ?? 375
        let translationX: CGFloat = direction == .match ? screenWidth * 1.4 : -screenWidth * 1.4
        let rotationAngle: CGFloat = direction == .match ? 0.35 : -0.35
        
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                if direction == .match {
                    self.matchStamp.alpha = 1.0
                } else {
                    self.passStamp.alpha = 1.0
                }
                self.center = CGPoint(x: self.originalCenter.x + translationX, y: self.originalCenter.y + 30)
                self.transform = CGAffineTransform(rotationAngle: rotationAngle)
            },
            completion: { _ in
                self.removeFromSuperview()
                if direction == .match {
                    self.delegate?.cardDidSwipeRight(self)
                } else {
                    self.delegate?.cardDidSwipeLeft(self)
                }
            }
        )
    }
    
    @objc private func handleCardTap(_ gesture: UITapGestureRecognizer) {
        delegate?.cardDidTap(self)
    }
    
    @objc private func didTapDetails() {
        delegate?.cardDidTap(self)
    }
    
    func cardDidTapInfo(_ card: OpportunityCardView) {
        delegate?.cardDidTapInfo(self)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture && otherGestureRecognizer == tapGesture {
            return false
        }
        return false
    }
}

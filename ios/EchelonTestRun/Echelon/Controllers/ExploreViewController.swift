import UIKit

class ExploreViewController: UIViewController, OpportunityCardDelegate {
    
    // Header Views
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let liveBadgeStack = UIStackView()
    private let liveDotView = UIView()
    private let liveTextLabel = UILabel()
    
    // Card Deck Container
    private let cardDeckContainer = UIView()
    private var cardViews: [OpportunityCardView] = []
    private var opportunities: [OpportunityCard] = OpportunityCard.mockDeck
    
    // Action Buttons Bar
    private let actionButtonsStack = UIStackView()
    private let passButton = UIButton(type: .system)
    private let starButton = UIButton(type: .system)
    private let applyButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    
    // Empty State Views
    private let emptyStateView = UIView()
    private let emptyIconLabel = UILabel()
    private let emptyTitleLabel = UILabel()
    private let emptySubtitleLabel = UILabel()
    private let refreshButton = UIButton(type: .system)
    
    // Callback when match is made
    var onOpportunityApplied: ((OpportunityCard) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCards()
    }
    
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        
        setupHeader()
        setupCardDeck()
        setupActionButtons()
        setupEmptyState()
        
        NSLayoutConstraint.activate([
            // Header
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.s8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s20),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s20),
            headerStack.heightAnchor.constraint(equalToConstant: 40),
            
            // Action Buttons
            actionButtonsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -84),
            actionButtonsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButtonsStack.heightAnchor.constraint(equalToConstant: 70),
            
            // Card Deck Container (Tinder-sized, occupies prominent portion of screen)
            cardDeckContainer.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: AppTheme.Spacing.s8),
            cardDeckContainer.bottomAnchor.constraint(equalTo: actionButtonsStack.topAnchor, constant: -AppTheme.Spacing.s12),
            cardDeckContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s12),
            cardDeckContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s12),
            
            // Empty State
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s32),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s32)
        ])
    }
    
    private func setupHeader() {
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        view.addSubview(headerStack)
        
        // Left text: Title + Count
        let titleContainer = UIStackView()
        titleContainer.axis = .horizontal
        titleContainer.spacing = AppTheme.Spacing.s8
        titleContainer.alignment = .center
        
        // Typography · Display · 26 px
        titleLabel.text = "Explore"
        titleLabel.font = AppTheme.Typography.display
        titleLabel.textColor = AppTheme.Colors.textPrimary
        titleContainer.addArrangedSubview(titleLabel)
        
        // Typography · Body · 13 px (Medium)
        countLabel.text = "\(opportunities.count) opportunities"
        countLabel.font = AppTheme.Typography.bodyMedium
        countLabel.textColor = AppTheme.Colors.textSecondary
        titleContainer.addArrangedSubview(countLabel)
        
        headerStack.addArrangedSubview(titleContainer)
        
        // Right live badge
        liveBadgeStack.axis = .horizontal
        liveBadgeStack.spacing = AppTheme.Spacing.s6
        liveBadgeStack.alignment = .center
        
        liveDotView.translatesAutoresizingMaskIntoConstraints = false
        liveDotView.backgroundColor = AppTheme.Colors.green
        liveDotView.layer.cornerRadius = 3.5
        liveDotView.widthAnchor.constraint(equalToConstant: 7).isActive = true
        liveDotView.heightAnchor.constraint(equalToConstant: 7).isActive = true
        liveBadgeStack.addArrangedSubview(liveDotView)
        
        // Typography · Label · 11 px (Bold)
        liveTextLabel.text = "Live"
        liveTextLabel.font = AppTheme.Typography.labelBold
        liveTextLabel.textColor = AppTheme.Colors.green
        liveBadgeStack.addArrangedSubview(liveTextLabel)
        
        headerStack.addArrangedSubview(liveBadgeStack)
    }
    
    private func setupCardDeck() {
        cardDeckContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardDeckContainer)
    }
    
    private func setupActionButtons() {
        actionButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsStack.axis = .horizontal
        actionButtonsStack.spacing = AppTheme.Spacing.s18
        actionButtonsStack.alignment = .center
        view.addSubview(actionButtonsStack)
        
        // 1. Pass button (X)
        configureCircularButton(passButton, size: 48, icon: "xmark", iconColor: AppTheme.Colors.red, bgColor: AppTheme.Colors.glass, borderColor: AppTheme.Colors.border)
        passButton.addTarget(self, action: #selector(didTapPass), for: .touchUpInside)
        actionButtonsStack.addArrangedSubview(passButton)
        
        // 2. Star button
        configureCircularButton(starButton, size: 48, icon: "star.fill", iconColor: AppTheme.Colors.yellow, bgColor: AppTheme.Colors.glass, borderColor: AppTheme.Colors.border)
        starButton.addTarget(self, action: #selector(didTapStar), for: .touchUpInside)
        actionButtonsStack.addArrangedSubview(starButton)
        
        // 3. Like/Apply button (Hero Heart)
        configureCircularButton(applyButton, size: 66, icon: "heart.fill", iconColor: .white, bgColor: AppTheme.Colors.green, borderColor: nil)
        applyButton.layer.shadowColor = AppTheme.Colors.green.cgColor
        applyButton.layer.shadowOpacity = 0.55
        applyButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        applyButton.layer.shadowRadius = 14
        applyButton.addTarget(self, action: #selector(didTapApply), for: .touchUpInside)
        actionButtonsStack.addArrangedSubview(applyButton)
        
        // 4. Info button
        configureCircularButton(infoButton, size: 48, icon: "info.circle", iconColor: AppTheme.Colors.textSecondary, bgColor: AppTheme.Colors.glass, borderColor: AppTheme.Colors.border)
        infoButton.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)
        actionButtonsStack.addArrangedSubview(infoButton)
    }
    
    private func configureCircularButton(_ button: UIButton, size: CGFloat, icon: String, iconColor: UIColor, bgColor: UIColor, borderColor: UIColor?) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = bgColor
        button.layer.cornerRadius = size / 2
        button.layer.masksToBounds = false
        
        if let borderColor = borderColor {
            button.layer.borderWidth = 1.0
            button.layer.borderColor = borderColor.cgColor
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: size * 0.4, weight: .bold)
        let img = UIImage(systemName: icon, withConfiguration: config)
        button.setImage(img, for: .normal)
        button.tintColor = iconColor
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size)
        ])
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        
        emptyIconLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyIconLabel.text = "🎓"
        emptyIconLabel.font = .systemFont(ofSize: 64)
        emptyIconLabel.textAlignment = .center
        emptyStateView.addSubview(emptyIconLabel)
        
        // Typography · Title · 22 px
        emptyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyTitleLabel.text = "You've seen them all"
        emptyTitleLabel.font = AppTheme.Typography.title
        emptyTitleLabel.textColor = AppTheme.Colors.textPrimary
        emptyTitleLabel.textAlignment = .center
        emptyStateView.addSubview(emptyTitleLabel)
        
        // Typography · Body · 13 px
        emptySubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptySubtitleLabel.text = "New opportunities are added weekly.\nRefresh to see more."
        emptySubtitleLabel.font = AppTheme.Typography.body
        emptySubtitleLabel.textColor = AppTheme.Colors.textSecondary
        emptySubtitleLabel.textAlignment = .center
        emptySubtitleLabel.numberOfLines = 2
        emptyStateView.addSubview(emptySubtitleLabel)
        
        // Refresh Button with Radii · 16 px & Blue
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.titleLabel?.font = AppTheme.Typography.cardTitleBold
        refreshButton.setTitleColor(.white, for: .normal)
        refreshButton.backgroundColor = AppTheme.Colors.blue
        refreshButton.layer.cornerRadius = AppTheme.Radii.r16
        refreshButton.layer.shadowColor = AppTheme.Colors.blue.cgColor
        refreshButton.layer.shadowOpacity = 0.4
        refreshButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        refreshButton.layer.shadowRadius = 10
        refreshButton.addTarget(self, action: #selector(didTapRefresh), for: .touchUpInside)
        emptyStateView.addSubview(refreshButton)
        
        NSLayoutConstraint.activate([
            emptyIconLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyIconLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            
            emptyTitleLabel.topAnchor.constraint(equalTo: emptyIconLabel.bottomAnchor, constant: AppTheme.Spacing.s16),
            emptyTitleLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyTitleLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            emptySubtitleLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: AppTheme.Spacing.s8),
            emptySubtitleLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptySubtitleLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            refreshButton.topAnchor.constraint(equalTo: emptySubtitleLabel.bottomAnchor, constant: AppTheme.Spacing.s24),
            refreshButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 140),
            refreshButton.heightAnchor.constraint(equalToConstant: 44),
            refreshButton.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    private func loadCards() {
        cardViews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()
        
        opportunities = OpportunityCard.mockDeck
        updateCountLabel()
        
        let initialCards = Array(opportunities.prefix(3))
        for (index, opp) in initialCards.enumerated() {
            let card = OpportunityCardView(opportunity: opp)
            card.delegate = self
            card.translatesAutoresizingMaskIntoConstraints = false
            
            // Insert each card at index 0 of cardDeckContainer so later cards sit behind earlier ones
            cardDeckContainer.insertSubview(card, at: 0)
            
            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: cardDeckContainer.topAnchor),
                card.bottomAnchor.constraint(equalTo: cardDeckContainer.bottomAnchor),
                card.leadingAnchor.constraint(equalTo: cardDeckContainer.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: cardDeckContainer.trailingAnchor)
            ])
            
            let isTop = (index == 0)
            card.isUserInteractionEnabled = isTop
            let scale: CGFloat = isTop ? 1.0 : (1.0 - CGFloat(index) * 0.04)
            card.transform = isTop ? .identity : CGAffineTransform(scaleX: scale, y: scale)
            
            cardViews.append(card)
        }
        
        updateEmptyState()
    }
    
    private func updateCountLabel() {
        countLabel.text = "\(opportunities.count) opportunities"
    }
    
    private func updateEmptyState() {
        let isEmpty = opportunities.isEmpty
        emptyStateView.isHidden = !isEmpty
        actionButtonsStack.isHidden = isEmpty
        cardDeckContainer.isHidden = isEmpty
        
        if isEmpty {
            countLabel.text = "0 opportunities"
        }
    }
    
    // MARK: - OpportunityCardDelegate
    func cardDidSwipeLeft(_ card: OpportunityCardView) {
        handleCardSwiped(card: card, wasApplied: false)
    }
    
    func cardDidSwipeRight(_ card: OpportunityCardView) {
        handleCardSwiped(card: card, wasApplied: true)
    }
    
    func cardDidTapInfo(_ card: OpportunityCardView) {
        let alert = UIAlertController(
            title: card.opportunity.title,
            message: "\(card.opportunity.organization)\n\n\(card.opportunity.description)\n\nPerks: Competitive stipend, 1-on-1 mentorship, housing support.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = card
            popover.sourceRect = card.bounds
        }
        present(alert, animated: true)
    }
    
    private func handleCardSwiped(card: OpportunityCardView, wasApplied: Bool) {
        if let index = cardViews.firstIndex(of: card) {
            cardViews.remove(at: index)
        }
        
        if !opportunities.isEmpty {
            let removed = opportunities.removeFirst()
            if wasApplied {
                onOpportunityApplied?(removed)
            }
        }
        
        updateCountLabel()
        
        for (idx, cv) in cardViews.enumerated() {
            if idx == 0 {
                cv.isUserInteractionEnabled = true
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5, animations: {
                    cv.transform = .identity
                })
            } else {
                cv.isUserInteractionEnabled = false
                let scale: CGFloat = 1.0 - CGFloat(idx) * 0.04
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5, animations: {
                    cv.transform = CGAffineTransform(scaleX: scale, y: scale)
                })
            }
        }
        
        if opportunities.count > cardViews.count {
            let nextIndex = cardViews.count
            if nextIndex < opportunities.count {
                let opp = opportunities[nextIndex]
                let newCard = OpportunityCardView(opportunity: opp)
                newCard.delegate = self
                newCard.translatesAutoresizingMaskIntoConstraints = false
                newCard.isUserInteractionEnabled = false
                
                // Always insert new cards at index 0 of the container so they are at the bottom of the stack
                cardDeckContainer.insertSubview(newCard, at: 0)
                
                NSLayoutConstraint.activate([
                    newCard.topAnchor.constraint(equalTo: cardDeckContainer.topAnchor),
                    newCard.bottomAnchor.constraint(equalTo: cardDeckContainer.bottomAnchor),
                    newCard.leadingAnchor.constraint(equalTo: cardDeckContainer.leadingAnchor),
                    newCard.trailingAnchor.constraint(equalTo: cardDeckContainer.trailingAnchor)
                ])
                
                let scale: CGFloat = 1.0 - CGFloat(cardViews.count) * 0.04
                newCard.transform = CGAffineTransform(scaleX: scale, y: scale)
                
                cardViews.append(newCard)
            }
        }
        
        updateEmptyState()
    }
    
    // MARK: - Button Actions
    @objc private func didTapPass() {
        guard let topCard = cardViews.first else { return }
        topCard.swipeLeft()
    }
    
    @objc private func didTapApply() {
        guard let topCard = cardViews.first else { return }
        topCard.swipeRight()
    }
    
    @objc private func didTapStar() {
        guard let topCard = cardViews.first else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        topCard.swipeRight()
    }
    
    @objc private func didTapInfo() {
        guard let topCard = cardViews.first else { return }
        cardDidTapInfo(topCard)
    }
    
    @objc private func didTapRefresh() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        loadCards()
    }
}

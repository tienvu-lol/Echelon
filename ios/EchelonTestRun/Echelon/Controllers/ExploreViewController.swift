import UIKit
import SwiftUI

class ExploreViewController: UIViewController, OpportunityCardDelegate {
    
    // MARK: - Header Views
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let liveBadgeStack = UIStackView()
    private let liveDotView = UIView()
    private let liveTextLabel = UILabel()
    
    // MARK: - Card Deck Container
    private let cardDeckContainer = UIView()
    private var cardViews: [OpportunityCardView] = []
    private var batchOpportunities: [OpportunityCard] = []
    
    // MARK: - State & Status Views
    private let statusContainerView = UIView()
    private let statusIconLabel = UILabel()
    private let statusTitleLabel = UILabel()
    private let statusSubtitleLabel = UILabel()
    private let refreshInfoLabel = UILabel()
    private let refreshButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Batching & Rate Limiting (Batches of exactly 7)
    private let batchSize = 7
    private var isLoadingBatch = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchBatch(isRefresh: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MatchStore.shared.evaluateRateLimit()
        updateBatchCompleteStateIfNeeded()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        
        setupHeader()
        setupCardDeck()
        setupStatusViews()
        
        NSLayoutConstraint.activate([
            // Header
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.s8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s20),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s20),
            headerStack.heightAnchor.constraint(equalToConstant: 40),
            
            // Card Deck Container occupies prominent screen real estate without action buttons
            cardDeckContainer.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: AppTheme.Spacing.s12),
            cardDeckContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -96),
            cardDeckContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s12),
            cardDeckContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s12),
            
            // Status / End-of-batch Container
            statusContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            statusContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s32),
            statusContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s32),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupHeader() {
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        view.addSubview(headerStack)
        
        let titleContainer = UIStackView()
        titleContainer.axis = .horizontal
        titleContainer.spacing = AppTheme.Spacing.s8
        titleContainer.alignment = .center
        
        titleLabel.text = "Discover"
        titleLabel.font = AppTheme.Typography.display
        titleLabel.textColor = AppTheme.Colors.textPrimary
        titleContainer.addArrangedSubview(titleLabel)
        
        countLabel.text = "\(batchSize) in batch"
        countLabel.font = AppTheme.Typography.bodyMedium
        countLabel.textColor = AppTheme.Colors.textSecondary
        titleContainer.addArrangedSubview(countLabel)
        
        headerStack.addArrangedSubview(titleContainer)
        
        // Live badge
        liveBadgeStack.axis = .horizontal
        liveBadgeStack.spacing = AppTheme.Spacing.s6
        liveBadgeStack.alignment = .center
        
        liveDotView.translatesAutoresizingMaskIntoConstraints = false
        liveDotView.backgroundColor = AppTheme.Colors.green
        liveDotView.layer.cornerRadius = 3.5
        liveDotView.widthAnchor.constraint(equalToConstant: 7).isActive = true
        liveDotView.heightAnchor.constraint(equalToConstant: 7).isActive = true
        liveBadgeStack.addArrangedSubview(liveDotView)
        
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
    
    private func setupStatusViews() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = AppTheme.Colors.cyan
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        statusContainerView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerView.isHidden = true
        view.addSubview(statusContainerView)
        
        statusIconLabel.translatesAutoresizingMaskIntoConstraints = false
        statusIconLabel.text = "✨"
        statusIconLabel.font = .systemFont(ofSize: 56)
        statusIconLabel.textAlignment = .center
        statusContainerView.addSubview(statusIconLabel)
        
        statusTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusTitleLabel.font = AppTheme.Typography.title
        statusTitleLabel.textColor = AppTheme.Colors.textPrimary
        statusTitleLabel.textAlignment = .center
        statusContainerView.addSubview(statusTitleLabel)
        
        statusSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusSubtitleLabel.font = AppTheme.Typography.body
        statusSubtitleLabel.textColor = AppTheme.Colors.textSecondary
        statusSubtitleLabel.textAlignment = .center
        statusSubtitleLabel.numberOfLines = 3
        statusContainerView.addSubview(statusSubtitleLabel)
        
        refreshInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        refreshInfoLabel.font = AppTheme.Typography.labelBold
        refreshInfoLabel.textColor = AppTheme.Colors.cyan
        refreshInfoLabel.textAlignment = .center
        statusContainerView.addSubview(refreshInfoLabel)
        
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.setTitle("Refresh Opportunities", for: .normal)
        refreshButton.titleLabel?.font = AppTheme.Typography.cardTitleBold
        refreshButton.setTitleColor(.white, for: .normal)
        refreshButton.backgroundColor = AppTheme.Colors.blue
        refreshButton.layer.cornerRadius = AppTheme.Radii.r16
        refreshButton.layer.shadowColor = AppTheme.Colors.blue.cgColor
        refreshButton.layer.shadowOpacity = 0.4
        refreshButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        refreshButton.layer.shadowRadius = 10
        refreshButton.addTarget(self, action: #selector(didTapRefresh), for: .touchUpInside)
        statusContainerView.addSubview(refreshButton)
        
        NSLayoutConstraint.activate([
            statusIconLabel.topAnchor.constraint(equalTo: statusContainerView.topAnchor),
            statusIconLabel.centerXAnchor.constraint(equalTo: statusContainerView.centerXAnchor),
            
            statusTitleLabel.topAnchor.constraint(equalTo: statusIconLabel.bottomAnchor, constant: AppTheme.Spacing.s12),
            statusTitleLabel.leadingAnchor.constraint(equalTo: statusContainerView.leadingAnchor),
            statusTitleLabel.trailingAnchor.constraint(equalTo: statusContainerView.trailingAnchor),
            
            statusSubtitleLabel.topAnchor.constraint(equalTo: statusTitleLabel.bottomAnchor, constant: AppTheme.Spacing.s8),
            statusSubtitleLabel.leadingAnchor.constraint(equalTo: statusContainerView.leadingAnchor),
            statusSubtitleLabel.trailingAnchor.constraint(equalTo: statusContainerView.trailingAnchor),
            
            refreshInfoLabel.topAnchor.constraint(equalTo: statusSubtitleLabel.bottomAnchor, constant: AppTheme.Spacing.s12),
            refreshInfoLabel.leadingAnchor.constraint(equalTo: statusContainerView.leadingAnchor),
            refreshInfoLabel.trailingAnchor.constraint(equalTo: statusContainerView.trailingAnchor),
            
            refreshButton.topAnchor.constraint(equalTo: refreshInfoLabel.bottomAnchor, constant: AppTheme.Spacing.s20),
            refreshButton.centerXAnchor.constraint(equalTo: statusContainerView.centerXAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 220),
            refreshButton.heightAnchor.constraint(equalToConstant: 50),
            refreshButton.bottomAnchor.constraint(equalTo: statusContainerView.bottomAnchor)
        ])
    }
    
    // MARK: - Batch Fetching
    private func fetchBatch(isRefresh: Bool) {
        guard !isLoadingBatch else { return }
        
        if isRefresh {
            MatchStore.shared.evaluateRateLimit()
            guard MatchStore.shared.canRefresh else {
                updateBatchCompleteStateIfNeeded()
                return
            }
        }
        
        isLoadingBatch = true
        statusContainerView.isHidden = true
        cardDeckContainer.isHidden = true
        loadingIndicator.startAnimating()
        
        let studentId = MatchStore.shared.studentProfile.id
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let batch = try await APIService.shared.getOpportunityBatch(
                    studentId: studentId,
                    limit: self.batchSize,
                    isRefresh: isRefresh
                )
                
                await MainActor.run {
                    self.isLoadingBatch = false
                    self.loadingIndicator.stopAnimating()
                    
                    var opps = batch.opportunities
                    if opps.isEmpty {
                        opps = OpportunityCard.mockDeck
                    }
                    self.batchOpportunities = Array(opps.prefix(self.batchSize))
                    self.renderCards()
                }
            } catch {
                await MainActor.run {
                    self.isLoadingBatch = false
                    self.loadingIndicator.stopAnimating()
                    let opps = OpportunityCard.mockDeck
                    self.batchOpportunities = Array(opps.prefix(self.batchSize))
                    self.renderCards()
                }
            }
        }
    }
    
    // MARK: - Card Stack Rendering
    private func renderCards() {
        cardViews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()
        
        updateCountLabel()
        
        guard !batchOpportunities.isEmpty else {
            updateBatchCompleteStateIfNeeded()
            return
        }
        
        statusContainerView.isHidden = true
        cardDeckContainer.isHidden = false
        
        // Show top 3 cards in stack for 3D depth effect
        let initialCards = Array(batchOpportunities.prefix(3))
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
    }
    
    private func updateCountLabel() {
        let remaining = batchOpportunities.count
        countLabel.text = "\(remaining) left in batch"
    }
    
    // MARK: - End-of-Batch & Rate Limit State
    private func updateBatchCompleteStateIfNeeded() {
        guard batchOpportunities.isEmpty && !isLoadingBatch else { return }
        
        cardDeckContainer.isHidden = true
        statusContainerView.isHidden = false
        countLabel.text = "Batch complete"
        
        MatchStore.shared.evaluateRateLimit()
        let canRefresh = MatchStore.shared.canRefresh
        let refreshesRemaining = MatchStore.shared.refreshesRemaining
        
        if canRefresh {
            statusIconLabel.text = "🎉"
            statusTitleLabel.text = "Batch Complete"
            statusSubtitleLabel.text = "You've reviewed all 7 opportunities in this batch. Tap below to fetch your next set."
            refreshInfoLabel.text = "\(refreshesRemaining) refresh\(refreshesRemaining == 1 ? "" : "es") remaining this hour"
            refreshInfoLabel.textColor = AppTheme.Colors.cyan
            
            refreshButton.isEnabled = true
            refreshButton.setTitle("Refresh Opportunities", for: .normal)
            refreshButton.backgroundColor = AppTheme.Colors.blue
            refreshButton.alpha = 1.0
        } else {
            statusIconLabel.text = "⏳"
            statusTitleLabel.text = "All Refreshes Used"
            
            var minutesText = "30"
            if let nextDate = MatchStore.shared.nextRefreshAvailableAt {
                let diffMin = max(1, Int(nextDate.timeIntervalSinceNow / 60))
                minutesText = "\(diffMin)"
            }
            
            statusSubtitleLabel.text = "You've used all 3 refreshes for now.\nMore opportunities will be available in \(minutesText) minutes."
            refreshInfoLabel.text = "Rate limit: 3 refreshes / hour"
            refreshInfoLabel.textColor = AppTheme.Colors.orange
            
            refreshButton.isEnabled = false
            refreshButton.setTitle("Rate Limited", for: .normal)
            refreshButton.backgroundColor = AppTheme.Colors.glass
            refreshButton.alpha = 0.55
        }
    }
    
    private func showErrorState(message: String) {
        cardDeckContainer.isHidden = true
        statusContainerView.isHidden = false
        
        statusIconLabel.text = "⚠️"
        statusTitleLabel.text = "Something went wrong"
        statusSubtitleLabel.text = message
        refreshInfoLabel.text = "Check your connection and try again."
        refreshInfoLabel.textColor = AppTheme.Colors.red
        
        refreshButton.isEnabled = true
        refreshButton.setTitle("Retry", for: .normal)
        refreshButton.backgroundColor = AppTheme.Colors.blue
        refreshButton.alpha = 1.0
    }
    
    // MARK: - OpportunityCardDelegate
    func cardDidSwipeLeft(_ card: OpportunityCardView) {
        handleCardSwiped(card: card, isMatch: false)
    }
    
    func cardDidSwipeRight(_ card: OpportunityCardView) {
        handleCardSwiped(card: card, isMatch: true)
    }
    
    func cardDidTap(_ card: OpportunityCardView) {
        openOpportunityDetail(for: card.opportunity)
    }
    
    func cardDidTapInfo(_ card: OpportunityCardView) {
        openOpportunityDetail(for: card.opportunity)
    }
    
    private func openOpportunityDetail(for opportunity: OpportunityCard) {
        let detailView = OpportunityDetailView(opportunity: opportunity)
        let hostingController = UIHostingController(rootView: detailView)
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true)
    }
    
    private func handleCardSwiped(card: OpportunityCardView, isMatch: Bool) {
        if let index = cardViews.firstIndex(of: card) {
            cardViews.remove(at: index)
        }
        
        guard !batchOpportunities.isEmpty else { return }
        let swipedOpp = batchOpportunities.removeFirst()
        
        let studentId = MatchStore.shared.studentProfile.id
        
        if isMatch {
            // Right swipe = MATCH (Not Applied)
            MatchStore.shared.recordSwipe(opportunity: swipedOpp, direction: .matched)
            Task {
                _ = try? await APIService.shared.recordSwipe(studentId: studentId, opportunityId: swipedOpp.id, direction: "match")
            }
        } else {
            // Left swipe = PASS
            MatchStore.shared.recordSwipe(opportunity: swipedOpp, direction: .passed)
            Task {
                _ = try? await APIService.shared.recordSwipe(studentId: studentId, opportunityId: swipedOpp.id, direction: "pass")
            }
        }
        
        updateCountLabel()
        
        // Reposition remaining cards in stack
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
        
        // Add next card into container from current batch if available
        if batchOpportunities.count > cardViews.count {
            let nextIndex = cardViews.count
            if nextIndex < batchOpportunities.count {
                let nextOpp = batchOpportunities[nextIndex]
                let newCard = OpportunityCardView(opportunity: nextOpp)
                newCard.delegate = self
                newCard.translatesAutoresizingMaskIntoConstraints = false
                newCard.isUserInteractionEnabled = false
                
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
        
        // Check if all 7 in batch have been swiped
        if batchOpportunities.isEmpty && cardViews.isEmpty {
            updateBatchCompleteStateIfNeeded()
        }
    }
    
    // MARK: - Actions
    @objc private func didTapRefresh() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        fetchBatch(isRefresh: true)
    }
}

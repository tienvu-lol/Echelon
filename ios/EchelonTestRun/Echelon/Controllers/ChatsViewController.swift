import UIKit
import SwiftUI
import Combine

class ChatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    // MARK: - Header & Controls
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let searchBar = UISearchBar()
    
    // MARK: - TableView & Empty State
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyContainerView = UIView()
    private let emptyIconImageView = UIImageView()
    private let emptyTitleLabel = UILabel()
    private let emptySubtitleLabel = UILabel()
    private let browseButton = UIButton(type: .system)
    
    // MARK: - State
    private var cancellables = Set<AnyCancellable>()
    private var searchQuery: String = ""
    
    private var currentOpportunityIds: [String] {
        let allIds = MatchStore.shared.activeChatOpportunityIds
        guard !searchQuery.isEmpty else { return allIds }
        
        return allIds.filter { oppId in
            guard let opp = MatchStore.shared.opportunity(for: oppId) else { return false }
            let matchesOrg = opp.organization.localizedCaseInsensitiveContains(searchQuery)
            let matchesTitle = opp.title.localizedCaseInsensitiveContains(searchQuery)
            let matchesLastMsg = MatchStore.shared.chatHistory(for: oppId).last?.text.localizedCaseInsensitiveContains(searchQuery) ?? false
            return matchesOrg || matchesTitle || matchesLastMsg
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSubscriptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateEmptyState()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        
        setupHeader()
        setupSearchBar()
        setupTableView()
        setupEmptyState()
        
        NSLayoutConstraint.activate([
            // Header
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.s8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s20),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s20),
            
            // Search Bar
            searchBar.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: AppTheme.Spacing.s8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s12),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s12),
            searchBar.heightAnchor.constraint(equalToConstant: 44),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: AppTheme.Spacing.s8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -96),
            
            // Empty State
            emptyContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 10),
            emptyContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s32),
            emptyContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s32)
        ])
    }
    
    private func setupHeader() {
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.alignment = .leading
        view.addSubview(headerStack)
        
        titleLabel.text = "Chats"
        titleLabel.font = AppTheme.Typography.display
        titleLabel.textColor = AppTheme.Colors.textPrimary
        headerStack.addArrangedSubview(titleLabel)
        
        subtitleLabel.text = "Direct conversations with company advisors"
        subtitleLabel.font = AppTheme.Typography.bodyMedium
        subtitleLabel.textColor = AppTheme.Colors.textTertiary
        headerStack.addArrangedSubview(subtitleLabel)
    }
    
    private func setupSearchBar() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.delegate = self
        searchBar.placeholder = "Search conversations..."
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = AppTheme.Colors.cyan
        searchBar.overrideUserInterfaceStyle = .dark
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = AppTheme.Colors.textPrimary
            textField.font = AppTheme.Typography.body
            textField.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
            textField.layer.cornerRadius = 12
            textField.layer.masksToBounds = true
        }
        view.addSubview(searchBar)
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatThreadTableViewCell.self, forCellReuseIdentifier: ChatThreadTableViewCell.identifier)
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 20, right: 0)
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
    }
    
    private func setupEmptyState() {
        emptyContainerView.translatesAutoresizingMaskIntoConstraints = false
        emptyContainerView.isHidden = true
        view.addSubview(emptyContainerView)
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = AppTheme.Spacing.s12
        emptyContainerView.addSubview(stack)
        
        // Icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)
        emptyIconImageView.image = UIImage(systemName: "bubble.left.and.bubble.right.fill", withConfiguration: iconConfig)
        emptyIconImageView.tintColor = AppTheme.Colors.cyan.withAlphaComponent(0.8)
        stack.addArrangedSubview(emptyIconImageView)
        
        // Title
        emptyTitleLabel.text = "No Conversations Yet"
        emptyTitleLabel.font = AppTheme.Typography.title
        emptyTitleLabel.textColor = AppTheme.Colors.textPrimary
        emptyTitleLabel.textAlignment = .center
        stack.addArrangedSubview(emptyTitleLabel)
        
        // Subtitle
        emptySubtitleLabel.text = "When you start talking to AI advisors or ask questions while viewing opportunities, your chat threads will appear here."
        emptySubtitleLabel.font = AppTheme.Typography.body
        emptySubtitleLabel.textColor = AppTheme.Colors.textSecondary
        emptySubtitleLabel.textAlignment = .center
        emptySubtitleLabel.numberOfLines = 0
        stack.addArrangedSubview(emptySubtitleLabel)
        
        // Browse Button
        browseButton.translatesAutoresizingMaskIntoConstraints = false
        browseButton.setTitle("Explore Opportunities", for: .normal)
        browseButton.setTitleColor(.white, for: .normal)
        browseButton.titleLabel?.font = AppTheme.Typography.cardTitleBold
        browseButton.backgroundColor = AppTheme.Colors.blue
        browseButton.layer.cornerRadius = AppTheme.Radii.r18
        browseButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        browseButton.addTarget(self, action: #selector(didTapBrowse), for: .touchUpInside)
        stack.addArrangedSubview(browseButton)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: emptyContainerView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: emptyContainerView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: emptyContainerView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: emptyContainerView.trailingAnchor),
            browseButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupSubscriptions() {
        MatchStore.shared.$chatHistories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
            .store(in: &cancellables)
    }
    
    private func updateEmptyState() {
        let isEmpty = currentOpportunityIds.isEmpty
        emptyContainerView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    @objc private func didTapBrowse() {
        // Switch to Discover tab (tab 0)
        if let parentTabBar = parent as? MainFloatingTabBarController {
            // Tell parent to select tab 0
            NotificationCenter.default.post(name: NSNotification.Name("SwitchToDiscoverTab"), object: nil)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name("SwitchToDiscoverTab"), object: nil)
        }
    }
    
    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        tableView.reloadData()
        updateEmptyState()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentOpportunityIds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatThreadTableViewCell.identifier, for: indexPath) as? ChatThreadTableViewCell else {
            return UITableViewCell()
        }
        
        let oppId = currentOpportunityIds[indexPath.row]
        if let opp = MatchStore.shared.opportunity(for: oppId) {
            let messages = MatchStore.shared.chatHistory(for: oppId)
            cell.configure(with: opp, messages: messages)
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < currentOpportunityIds.count else { return }
        
        let oppId = currentOpportunityIds[indexPath.row]
        guard let opp = MatchStore.shared.opportunity(for: oppId) else { return }
        
        openChatConversation(for: opp)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < currentOpportunityIds.count else { return nil }
        let oppId = currentOpportunityIds[indexPath.row]
        guard let opp = MatchStore.shared.opportunity(for: oppId) else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            let alert = UIAlertController(
                title: "Delete Chat?",
                message: "Are you sure you want to delete the chat history with \(opp.organization)?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completion(false)
            })
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                MatchStore.shared.deleteChatHistory(for: oppId)
                self?.tableView.reloadData()
                self?.updateEmptyState()
                completion(true)
            })
            self?.present(alert, animated: true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = AppTheme.Colors.red
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func openChatConversation(for opportunity: OpportunityCard) {
        let chatView = ChatConversationView(opportunity: opportunity)
        let hostingController = UIHostingController(rootView: chatView)
        hostingController.overrideUserInterfaceStyle = .dark
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true)
    }
}

// MARK: - Custom Chat Thread Table View Cell (Apple UIKit Liquid Glass)
class ChatThreadTableViewCell: UITableViewCell {
    static let identifier = "ChatThreadTableViewCell"
    
    private let cardContainer = UIView()
    private let logoContainer = UIView()
    private let logoImageView = UIImageView()
    private let contentStack = UIStackView()
    private let topRowStack = UIStackView()
    private let orgLabel = UILabel()
    private let timeLabel = UILabel()
    private let roleLabel = UILabel()
    private let previewLabel = UILabel()
    private let chevronImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        AppTheme.Effects.applyEchelonGlass(
            to: cardContainer,
            cornerRadius: AppTheme.Radii.r20,
            innerHighlight: true,
            softShadow: true,
            blurStyle: .systemUltraThinMaterialDark,
            tintOpacity: 0.32
        )
        contentView.addSubview(cardContainer)
        
        // Logo Container
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        logoContainer.layer.cornerRadius = AppTheme.Radii.r16
        logoContainer.layer.cornerCurve = .continuous
        logoContainer.layer.borderWidth = 1.0
        logoContainer.layer.borderColor = UIColor(white: 1.0, alpha: 0.14).cgColor
        logoContainer.layer.masksToBounds = true
        cardContainer.addSubview(logoContainer)
        
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.tintColor = AppTheme.Colors.cyan
        logoContainer.addSubview(logoImageView)
        
        // Content Stack
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 3
        cardContainer.addSubview(contentStack)
        
        // Top Row: Org Name + Timestamp
        topRowStack.axis = .horizontal
        topRowStack.alignment = .center
        topRowStack.distribution = .equalSpacing
        contentStack.addArrangedSubview(topRowStack)
        
        orgLabel.font = AppTheme.Typography.cardTitleBold
        orgLabel.textColor = AppTheme.Colors.textPrimary
        topRowStack.addArrangedSubview(orgLabel)
        
        timeLabel.font = AppTheme.Typography.captionBold
        timeLabel.textColor = AppTheme.Colors.textTertiary
        topRowStack.addArrangedSubview(timeLabel)
        
        // Role Title
        roleLabel.font = AppTheme.Typography.labelBold
        roleLabel.textColor = AppTheme.Colors.cyan
        roleLabel.numberOfLines = 1
        contentStack.addArrangedSubview(roleLabel)
        
        // Preview Message
        previewLabel.font = AppTheme.Typography.body
        previewLabel.textColor = AppTheme.Colors.textSecondary
        previewLabel.numberOfLines = 2
        contentStack.addArrangedSubview(previewLabel)
        
        // Chevron
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevronImageView.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevronImageView.tintColor = AppTheme.Colors.textTertiary
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppTheme.Spacing.s6),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppTheme.Spacing.s6),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppTheme.Spacing.s18),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppTheme.Spacing.s18),
            
            logoContainer.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: AppTheme.Spacing.s14),
            logoContainer.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            logoContainer.widthAnchor.constraint(equalToConstant: 48),
            logoContainer.heightAnchor.constraint(equalToConstant: 48),
            
            logoImageView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 24),
            logoImageView.heightAnchor.constraint(equalToConstant: 24),
            
            contentStack.leadingAnchor.constraint(equalTo: logoContainer.trailingAnchor, constant: AppTheme.Spacing.s12),
            contentStack.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -AppTheme.Spacing.s8),
            contentStack.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: AppTheme.Spacing.s12),
            contentStack.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -AppTheme.Spacing.s12),
            
            chevronImageView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -AppTheme.Spacing.s14),
            chevronImageView.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    func configure(with opp: OpportunityCard, messages: [ChatMessage]) {
        orgLabel.text = opp.organization
        roleLabel.text = opp.title
        
        if let lastMsg = messages.last {
            let prefix = (lastMsg.sender == .user) ? "You: " : ""
            previewLabel.text = "\(prefix)\(lastMsg.text)"
            timeLabel.text = formatTimestamp(lastMsg.timestamp)
        } else {
            previewLabel.text = "No messages yet"
            timeLabel.text = ""
        }
        
        // Logo
        if let logoUrl = opp.organizationLogoUrl, !logoUrl.isEmpty {
            ImageLoader.shared.loadImage(from: logoUrl) { [weak self] img in
                if let img = img {
                    self?.logoImageView.image = img
                } else {
                    self?.setFallbackIcon(for: opp)
                }
            }
        } else {
            setFallbackIcon(for: opp)
        }
        
        // Accent Color
        if let hex = opp.accentHex {
            logoImageView.tintColor = UIColor(hex: hex)
        } else {
            logoImageView.tintColor = AppTheme.Colors.cyan
        }
    }
    
    private func setFallbackIcon(for opp: OpportunityCard) {
        let iconName = opp.companyLogoName ?? "building.2.fill"
        logoImageView.image = UIImage(systemName: iconName)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

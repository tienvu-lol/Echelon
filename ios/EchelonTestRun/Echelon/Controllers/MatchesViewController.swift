import UIKit
import SwiftUI
import Combine

class MatchesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Category Enum
    enum MatchCategory: Int {
        case notApplied = 0
        case applied = 1
    }
    
    // MARK: - Header & Controls
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["Not Applied (0)", "Applied (0)"])
    
    // MARK: - TableView & Empty State
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyContainerView = UIView()
    private let emptyIconLabel = UILabel()
    private let emptyTitleLabel = UILabel()
    private let emptySubtitleLabel = UILabel()
    
    private var selectedCategory: MatchCategory = .notApplied
    private var cancellables = Set<AnyCancellable>()
    
    private var currentList: [MatchedOpportunity] {
        switch selectedCategory {
        case .notApplied:
            return MatchStore.shared.notAppliedMatches
        case .applied:
            return MatchStore.shared.appliedMatches
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
        updateSegmentTitles()
        tableView.reloadData()
        updateEmptyState()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        
        setupHeader()
        setupSegmentedControl()
        setupTableView()
        setupEmptyState()
        
        NSLayoutConstraint.activate([
            // Header
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.s8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s20),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s20),
            
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: AppTheme.Spacing.s12),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s18),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s18),
            segmentedControl.heightAnchor.constraint(equalToConstant: 38),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: AppTheme.Spacing.s12),
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
        headerStack.axis = .horizontal
        headerStack.alignment = .firstBaseline
        headerStack.distribution = .equalSpacing
        view.addSubview(headerStack)
        
        titleLabel.text = "Matches"
        titleLabel.font = AppTheme.Typography.display
        titleLabel.textColor = AppTheme.Colors.textPrimary
        headerStack.addArrangedSubview(titleLabel)
    }
    
    private func setupSegmentedControl() {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.backgroundColor = AppTheme.Colors.glass
        segmentedControl.selectedSegmentTintColor = AppTheme.Colors.blue
        
        let normalTextAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: AppTheme.Colors.textSecondary,
            .font: AppTheme.Typography.bodySemibold
        ]
        let selectedTextAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: AppTheme.Typography.bodySemibold
        ]
        
        segmentedControl.setTitleTextAttributes(normalTextAttrs, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttrs, for: .selected)
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: AppTheme.Spacing.s4, left: 0, bottom: AppTheme.Spacing.s20, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MatchTableViewCell.self, forCellReuseIdentifier: MatchTableViewCell.identifier)
        view.addSubview(tableView)
    }
    
    private func setupEmptyState() {
        emptyContainerView.translatesAutoresizingMaskIntoConstraints = false
        emptyContainerView.isHidden = true
        view.addSubview(emptyContainerView)
        
        emptyIconLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyIconLabel.font = .systemFont(ofSize: 52)
        emptyIconLabel.textAlignment = .center
        emptyContainerView.addSubview(emptyIconLabel)
        
        emptyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyTitleLabel.font = AppTheme.Typography.title
        emptyTitleLabel.textColor = AppTheme.Colors.textPrimary
        emptyTitleLabel.textAlignment = .center
        emptyContainerView.addSubview(emptyTitleLabel)
        
        emptySubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptySubtitleLabel.font = AppTheme.Typography.body
        emptySubtitleLabel.textColor = AppTheme.Colors.textSecondary
        emptySubtitleLabel.textAlignment = .center
        emptySubtitleLabel.numberOfLines = 3
        emptyContainerView.addSubview(emptySubtitleLabel)
        
        NSLayoutConstraint.activate([
            emptyIconLabel.topAnchor.constraint(equalTo: emptyContainerView.topAnchor),
            emptyIconLabel.centerXAnchor.constraint(equalTo: emptyContainerView.centerXAnchor),
            
            emptyTitleLabel.topAnchor.constraint(equalTo: emptyIconLabel.bottomAnchor, constant: AppTheme.Spacing.s12),
            emptyTitleLabel.leadingAnchor.constraint(equalTo: emptyContainerView.leadingAnchor),
            emptyTitleLabel.trailingAnchor.constraint(equalTo: emptyContainerView.trailingAnchor),
            
            emptySubtitleLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: AppTheme.Spacing.s8),
            emptySubtitleLabel.leadingAnchor.constraint(equalTo: emptyContainerView.leadingAnchor),
            emptySubtitleLabel.trailingAnchor.constraint(equalTo: emptyContainerView.trailingAnchor),
            emptySubtitleLabel.bottomAnchor.constraint(equalTo: emptyContainerView.bottomAnchor)
        ])
    }
    
    private func setupSubscriptions() {
        MatchStore.shared.$notAppliedMatches
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSegmentTitles()
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
            .store(in: &cancellables)
        
        MatchStore.shared.$appliedMatches
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSegmentTitles()
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
            .store(in: &cancellables)
    }
    
    private func updateSegmentTitles() {
        let notAppliedCount = MatchStore.shared.notAppliedMatches.count
        let appliedCount = MatchStore.shared.appliedMatches.count
        segmentedControl.setTitle("Not Applied (\(notAppliedCount))", forSegmentAt: 0)
        segmentedControl.setTitle("Applied (\(appliedCount))", forSegmentAt: 1)
    }
    
    private func updateEmptyState() {
        let isEmpty = currentList.isEmpty
        emptyContainerView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        if isEmpty {
            switch selectedCategory {
            case .notApplied:
                emptyIconLabel.text = "🎯"
                emptyTitleLabel.text = "No Matches Pending"
                emptySubtitleLabel.text = "Swipe right on opportunities in Discover to match with them and review before applying."
            case .applied:
                emptyIconLabel.text = "📋"
                emptyTitleLabel.text = "No Applications Yet"
                emptySubtitleLabel.text = "Apply to your matched opportunities to track your submitted applications here."
            }
        }
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        selectedCategory = MatchCategory(rawValue: sender.selectedSegmentIndex) ?? .notApplied
        tableView.reloadData()
        updateEmptyState()
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MatchTableViewCell.identifier, for: indexPath) as? MatchTableViewCell else {
            return UITableViewCell()
        }
        let item = currentList[indexPath.row]
        cell.configure(with: item)
        
        cell.onApplyTapped = { [weak self] in
            self?.handleApply(for: item)
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate (Opens Same Opportunity Detail Page)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = currentList[indexPath.row]
        openOpportunityDetail(for: item.opportunity)
    }
    
    private func openOpportunityDetail(for opportunity: OpportunityCard) {
        let detailView = OpportunityDetailView(opportunity: opportunity)
        let hostingController = UIHostingController(rootView: detailView)
        hostingController.modalPresentationStyle = .pageSheet
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(hostingController, animated: true)
    }
    
    private func handleApply(for match: MatchedOpportunity) {
        if let urlStr = match.applyUrl, let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
        MatchStore.shared.applyToOpportunity(id: match.opportunity.id)
        
        Task {
            _ = try? await APIService.shared.applyOpportunity(
                studentId: MatchStore.shared.studentProfile.id,
                opportunityId: match.opportunity.id
            )
        }
        
        updateSegmentTitles()
        tableView.reloadData()
        updateEmptyState()
    }
}

// MARK: - Custom Match Table View Cell (Organization Logo Based)
class MatchTableViewCell: UITableViewCell {
    static let identifier = "MatchTableViewCell"
    
    private let cardContainer = UIView()
    private let accentStripe = UIView()
    private let logoContainer = UIView()
    private let logoImageView = UIImageView()
    private let textStack = UIStackView()
    private let orgLabel = UILabel()
    private let titleLabel = UILabel()
    private let detailInfoLabel = UILabel()
    
    private let rightActionStack = UIStackView()
    private let typePillView = TagPillView(
        text: "Internship",
        font: AppTheme.Typography.labelBold,
        cornerRadius: AppTheme.Radii.r12
    )
    private let statusButton = UIButton(type: .system)
    
    var onApplyTapped: (() -> Void)?
    
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
        AppTheme.Effects.applyEchelonGlass(to: cardContainer, cornerRadius: AppTheme.Radii.r20)
        contentView.addSubview(cardContainer)
        
        accentStripe.translatesAutoresizingMaskIntoConstraints = false
        accentStripe.layer.cornerRadius = 2
        cardContainer.addSubview(accentStripe)
        
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.backgroundColor = AppTheme.Colors.pillBackground
        logoContainer.layer.cornerRadius = 14
        logoContainer.layer.borderWidth = 1.0
        logoContainer.layer.borderColor = AppTheme.Colors.border.cgColor
        logoContainer.layer.masksToBounds = true
        cardContainer.addSubview(logoContainer)
        
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.tintColor = AppTheme.Colors.cyan
        logoContainer.addSubview(logoImageView)
        
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 3
        cardContainer.addSubview(textStack)
        
        orgLabel.font = AppTheme.Typography.cardTitleBold
        orgLabel.textColor = AppTheme.Colors.textPrimary
        textStack.addArrangedSubview(orgLabel)
        
        titleLabel.font = AppTheme.Typography.bodyMedium
        titleLabel.textColor = AppTheme.Colors.textSecondary
        titleLabel.numberOfLines = 1
        textStack.addArrangedSubview(titleLabel)
        
        detailInfoLabel.font = AppTheme.Typography.label
        detailInfoLabel.textColor = AppTheme.Colors.textTertiary
        textStack.addArrangedSubview(detailInfoLabel)
        
        rightActionStack.translatesAutoresizingMaskIntoConstraints = false
        rightActionStack.axis = .vertical
        rightActionStack.alignment = .trailing
        rightActionStack.spacing = AppTheme.Spacing.s8
        cardContainer.addSubview(rightActionStack)
        
        typePillView.translatesAutoresizingMaskIntoConstraints = false
        rightActionStack.addArrangedSubview(typePillView)
        
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        statusButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        rightActionStack.addArrangedSubview(statusButton)
        
        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppTheme.Spacing.s6),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppTheme.Spacing.s6),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppTheme.Spacing.s18),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppTheme.Spacing.s18),
            
            accentStripe.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            accentStripe.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: AppTheme.Spacing.s12),
            accentStripe.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -AppTheme.Spacing.s12),
            accentStripe.widthAnchor.constraint(equalToConstant: 4),
            
            logoContainer.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: AppTheme.Spacing.s14),
            logoContainer.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            logoContainer.widthAnchor.constraint(equalToConstant: 48),
            logoContainer.heightAnchor.constraint(equalToConstant: 48),
            
            logoImageView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 26),
            logoImageView.heightAnchor.constraint(equalToConstant: 26),
            
            textStack.leadingAnchor.constraint(equalTo: logoContainer.trailingAnchor, constant: AppTheme.Spacing.s12),
            textStack.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: rightActionStack.leadingAnchor, constant: -AppTheme.Spacing.s10),
            
            rightActionStack.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -AppTheme.Spacing.s14),
            rightActionStack.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            rightActionStack.topAnchor.constraint(greaterThanOrEqualTo: cardContainer.topAnchor, constant: AppTheme.Spacing.s12),
            rightActionStack.bottomAnchor.constraint(lessThanOrEqualTo: cardContainer.bottomAnchor, constant: -AppTheme.Spacing.s12)
        ])
    }
    
    func configure(with match: MatchedOpportunity) {
        orgLabel.text = match.organization
        titleLabel.text = match.title
        
        let loc = match.opportunity.location ?? "Remote"
        let comp = match.opportunity.compensation ?? "Competitive"
        detailInfoLabel.text = "\(loc) · \(comp)"
        
        let accentColor = UIColor(hex: match.accentColorHex)
        accentStripe.backgroundColor = accentColor
        
        // Organization Logo Loading (Not the large hero image)
        if let logoUrl = match.opportunity.organizationLogoUrl, !logoUrl.isEmpty {
            ImageLoader.shared.loadImage(from: logoUrl) { [weak self] img in
                if let img = img {
                    self?.logoImageView.image = img
                }
            }
        } else {
            logoImageView.image = UIImage(systemName: match.iconSystemName)
        }
        
        // Type pill styling
        let tagColor: UIColor
        switch match.opportunityType.lowercased() {
        case "reu":
            tagColor = AppTheme.Colors.cyan
        case "fellowship":
            tagColor = AppTheme.Colors.orange
        default:
            tagColor = AppTheme.Colors.blue
        }
        typePillView.configure(
            text: match.opportunityType,
            textColor: tagColor,
            backgroundColor: tagColor.withAlphaComponent(0.14),
            borderColor: tagColor.withAlphaComponent(0.35)
        )
        
        // Status / Action button configuration
        if match.applicationStatus == .applied {
            var config = UIButton.Configuration.filled()
            config.title = "Applied ✓"
            config.baseBackgroundColor = AppTheme.Colors.green.withAlphaComponent(0.2)
            config.baseForegroundColor = AppTheme.Colors.green
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            config.background.cornerRadius = AppTheme.Radii.r10
            statusButton.configuration = config
            statusButton.isUserInteractionEnabled = false
        } else {
            var config = UIButton.Configuration.filled()
            config.title = "Apply"
            config.baseBackgroundColor = AppTheme.Colors.blue
            config.baseForegroundColor = .white
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
            config.background.cornerRadius = AppTheme.Radii.r10
            statusButton.configuration = config
            statusButton.isUserInteractionEnabled = true
        }
    }
    
    @objc private func didTapButton() {
        onApplyTapped?()
    }
}

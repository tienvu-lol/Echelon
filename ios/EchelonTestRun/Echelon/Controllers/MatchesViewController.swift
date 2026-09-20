import UIKit

class MatchesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var matches: [MatchedOpportunity] = MatchedOpportunity.mockMatches
    
    var matchCount: Int {
        return matches.count
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        
        setupHeader()
        setupTableView()
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.s8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s20),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s20),
            
            tableView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: AppTheme.Spacing.s16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])
    }
    
    private func setupHeader() {
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.alignment = .firstBaseline
        headerStack.distribution = .equalSpacing
        view.addSubview(headerStack)
        
        // Typography · Display · 26 px
        titleLabel.text = "Matches"
        titleLabel.font = AppTheme.Typography.display
        titleLabel.textColor = AppTheme.Colors.textPrimary
        headerStack.addArrangedSubview(titleLabel)
        
        // Typography · Body · 13 px (Semibold)
        updateTotalLabel()
        totalLabel.font = AppTheme.Typography.bodySemibold
        totalLabel.textColor = AppTheme.Colors.blue
        headerStack.addArrangedSubview(totalLabel)
    }
    
    private func updateTotalLabel() {
        totalLabel.text = "\(matches.count) total"
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
    
    func addMatch(_ opportunity: OpportunityCard) {
        // Prevent duplicate entries
        guard !matches.contains(where: { $0.id == opportunity.id }) else { return }
        
        let newMatch = MatchedOpportunity(
            id: opportunity.id,
            organization: opportunity.organization,
            title: opportunity.title,
            opportunityType: opportunity.opportunityType,
            iconSystemName: opportunity.companyLogoName ?? "sparkles",
            accentColorHex: opportunity.accentHex ?? "#0A84FF",
            applyUrl: opportunity.applyUrl
        )
        matches.insert(newMatch, at: 0)
        updateTotalLabel()
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MatchTableViewCell.identifier, for: indexPath) as? MatchTableViewCell else {
            return UITableViewCell()
        }
        let item = matches[indexPath.row]
        cell.configure(with: item)
        cell.onApplyTapped = { [weak self] in
            self?.handleApply(for: item)
        }
        return cell
    }
    
    private func handleApply(for match: MatchedOpportunity) {
        let alert = UIAlertController(
            title: "Apply to \(match.organization)",
            message: "Opening application portal for \(match.title)...",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { _ in
            if let urlStr = match.applyUrl, let url = URL(string: urlStr) {
                UIApplication.shared.open(url)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Custom Match Table View Cell
class MatchTableViewCell: UITableViewCell {
    static let identifier = "MatchTableViewCell"
    
    private let cardContainer = UIView()
    private let accentStripe = UIView()
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let textStack = UIStackView()
    private let orgLabel = UILabel()
    private let titleLabel = UILabel()
    
    private let rightActionStack = UIStackView()
    private let typePillView = TagPillView(
        text: "Internship",
        font: AppTheme.Typography.labelBold,
        cornerRadius: AppTheme.Radii.r12
    )
    private let applyButton = UIButton(type: .system)
    
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
        // Glass Effect with Radii · 20 px
        AppTheme.Effects.applyEchelonGlass(to: cardContainer, cornerRadius: AppTheme.Radii.r20)
        contentView.addSubview(cardContainer)
        
        // Left Accent Stripe
        accentStripe.translatesAutoresizingMaskIntoConstraints = false
        accentStripe.layer.cornerRadius = 2
        cardContainer.addSubview(accentStripe)
        
        // Icon Container with Radii · 14 px
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = AppTheme.Colors.pillBackground
        iconContainer.layer.cornerRadius = 14
        iconContainer.layer.masksToBounds = true
        cardContainer.addSubview(iconContainer)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = AppTheme.Colors.textPrimary
        iconContainer.addSubview(iconImageView)
        
        // Text Stack
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 3
        cardContainer.addSubview(textStack)
        
        // Typography · Card title · 17 px (Bold)
        orgLabel.font = AppTheme.Typography.cardTitleBold
        orgLabel.textColor = AppTheme.Colors.textPrimary
        textStack.addArrangedSubview(orgLabel)
        
        // Typography · Body · 13 px (Medium)
        titleLabel.font = AppTheme.Typography.bodyMedium
        titleLabel.textColor = AppTheme.Colors.textSecondary
        titleLabel.numberOfLines = 1
        textStack.addArrangedSubview(titleLabel)
        
        // Right Action Stack
        rightActionStack.translatesAutoresizingMaskIntoConstraints = false
        rightActionStack.axis = .vertical
        rightActionStack.alignment = .trailing
        rightActionStack.spacing = AppTheme.Spacing.s8
        cardContainer.addSubview(rightActionStack)
        
        typePillView.translatesAutoresizingMaskIntoConstraints = false
        rightActionStack.addArrangedSubview(typePillView)
        
        // Apply Button with modern configuration
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.filled()
        config.title = "Apply"
        config.baseBackgroundColor = AppTheme.Colors.blue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(
            top: AppTheme.Spacing.s6,
            leading: AppTheme.Spacing.s16,
            bottom: AppTheme.Spacing.s6,
            trailing: AppTheme.Spacing.s16
        )
        config.background.cornerRadius = AppTheme.Radii.r10
        applyButton.configuration = config
        applyButton.addTarget(self, action: #selector(didTapApply), for: .touchUpInside)
        rightActionStack.addArrangedSubview(applyButton)
        
        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AppTheme.Spacing.s6),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -AppTheme.Spacing.s6),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppTheme.Spacing.s18),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppTheme.Spacing.s18),
            
            accentStripe.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            accentStripe.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: AppTheme.Spacing.s12),
            accentStripe.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -AppTheme.Spacing.s12),
            accentStripe.widthAnchor.constraint(equalToConstant: 4),
            
            iconContainer.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: AppTheme.Spacing.s14),
            iconContainer.centerYAnchor.constraint(equalTo: cardContainer.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 48),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            textStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: AppTheme.Spacing.s12),
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
        
        let accentColor = UIColor(hex: match.accentColorHex)
        accentStripe.backgroundColor = accentColor
        
        iconImageView.image = UIImage(systemName: match.iconSystemName)
        
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
    }
    
    @objc private func didTapApply() {
        onApplyTapped?()
    }
}

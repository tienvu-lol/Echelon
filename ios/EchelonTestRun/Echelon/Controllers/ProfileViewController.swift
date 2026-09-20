import UIKit

class ProfileViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    
    private let titleLabel = UILabel()
    
    // Cards
    private let profileHeaderCard = UIView()
    private let statsStack = UIStackView()
    private let skillsCard = UIView()
    private let preferencesCard = UIView()
    
    var userProfile: UserProfile = UserProfile.mockProfile
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        
        // Navigation Title: Display · 26 px
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Profile"
        titleLabel.font = AppTheme.Typography.display
        titleLabel.textColor = AppTheme.Colors.textPrimary
        view.addSubview(titleLabel)
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: AppTheme.Spacing.s12, left: 0, bottom: 120, right: 0)
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.axis = .vertical
        contentView.spacing = AppTheme.Spacing.s16
        contentView.alignment = .fill
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.s8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s20),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppTheme.Spacing.s12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: AppTheme.Spacing.s18),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -AppTheme.Spacing.s18),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -36)
        ])
        
        setupProfileHeaderCard()
        setupStatsRow()
        setupSkillsCard()
        setupPreferencesCard()
    }
    
    // MARK: - 1. Profile Header Card
    private func setupProfileHeaderCard() {
        // Echelon/Glass with Radii · 22 px
        AppTheme.Effects.applyEchelonGlass(to: profileHeaderCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(profileHeaderCard)
        
        // Avatar Box with Radii · 16 px
        let avatarView = UIView()
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.backgroundColor = AppTheme.Colors.blue.withAlphaComponent(0.2)
        avatarView.layer.cornerRadius = AppTheme.Radii.r16
        avatarView.layer.borderWidth = 1.0
        avatarView.layer.borderColor = AppTheme.Colors.blue.withAlphaComponent(0.4).cgColor
        avatarView.layer.masksToBounds = true
        profileHeaderCard.addSubview(avatarView)
        
        let avatarIcon = UIImageView(image: UIImage(systemName: "person.fill"))
        avatarIcon.tintColor = AppTheme.Colors.blue
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarIcon)
        
        // User Info Stack
        let infoStack = UIStackView()
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoStack.axis = .vertical
        infoStack.spacing = AppTheme.Spacing.s4
        profileHeaderCard.addSubview(infoStack)
        
        // Typography · Title · 22 px
        let nameLabel = UILabel()
        nameLabel.text = userProfile.name
        nameLabel.font = AppTheme.Typography.title
        nameLabel.textColor = AppTheme.Colors.textPrimary
        infoStack.addArrangedSubview(nameLabel)
        
        // Typography · Body · 13 px
        let headlineLabel = UILabel()
        headlineLabel.text = userProfile.headline
        headlineLabel.font = AppTheme.Typography.body
        headlineLabel.textColor = AppTheme.Colors.textSecondary
        infoStack.addArrangedSubview(headlineLabel)
        
        // Star Rating + GPA Row
        let ratingStack = UIStackView()
        ratingStack.axis = .horizontal
        ratingStack.spacing = 3
        ratingStack.alignment = .center
        
        for i in 1...5 {
            let star = UIImageView()
            star.translatesAutoresizingMaskIntoConstraints = false
            star.widthAnchor.constraint(equalToConstant: 13).isActive = true
            star.heightAnchor.constraint(equalToConstant: 13).isActive = true
            star.contentMode = .scaleAspectFit
            star.tintColor = AppTheme.Colors.yellow
            if i <= 4 {
                star.image = UIImage(systemName: "star.fill")
            } else {
                star.image = UIImage(systemName: "star.leadinghalf.filled")
            }
            ratingStack.addArrangedSubview(star)
        }
        
        // Typography · Label · 11 px
        let gpaLabel = UILabel()
        gpaLabel.text = " \(userProfile.gpa) GPA"
        gpaLabel.font = AppTheme.Typography.label
        gpaLabel.textColor = AppTheme.Colors.textSecondary
        ratingStack.addArrangedSubview(gpaLabel)
        
        infoStack.addArrangedSubview(ratingStack)
        
        // Typography · Description · 12.5 px
        let bioLabel = UILabel()
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.text = userProfile.bio
        bioLabel.font = AppTheme.Typography.description
        bioLabel.textColor = AppTheme.Colors.textSecondary
        bioLabel.numberOfLines = 0
        profileHeaderCard.addSubview(bioLabel)
        
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: profileHeaderCard.topAnchor, constant: AppTheme.Spacing.s18),
            avatarView.leadingAnchor.constraint(equalTo: profileHeaderCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            avatarView.widthAnchor.constraint(equalToConstant: 58),
            avatarView.heightAnchor.constraint(equalToConstant: 58),
            
            avatarIcon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 32),
            avatarIcon.heightAnchor.constraint(equalToConstant: 32),
            
            infoStack.topAnchor.constraint(equalTo: profileHeaderCard.topAnchor, constant: AppTheme.Spacing.s18),
            infoStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: AppTheme.Spacing.s14),
            infoStack.trailingAnchor.constraint(equalTo: profileHeaderCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            
            bioLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: AppTheme.Spacing.s14),
            bioLabel.leadingAnchor.constraint(equalTo: profileHeaderCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            bioLabel.trailingAnchor.constraint(equalTo: profileHeaderCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            bioLabel.bottomAnchor.constraint(equalTo: profileHeaderCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    // MARK: - 2. Stats Row (Explored, Applied, Interviews)
    private func setupStatsRow() {
        statsStack.axis = .horizontal
        statsStack.spacing = AppTheme.Spacing.s10
        statsStack.distribution = .fillEqually
        contentView.addArrangedSubview(statsStack)
        
        let card1 = makeStatCard(value: "\(userProfile.stats.exploredCount)", label: "Explored")
        let card2 = makeStatCard(value: "\(userProfile.stats.appliedCount)", label: "Applied")
        let card3 = makeStatCard(value: "\(userProfile.stats.interviewsCount)", label: "Interviews")
        
        statsStack.addArrangedSubview(card1)
        statsStack.addArrangedSubview(card2)
        statsStack.addArrangedSubview(card3)
    }
    
    private func makeStatCard(value: String, label: String) -> UIView {
        let card = UIView()
        // Echelon/Glass with Radii · 18 px
        AppTheme.Effects.applyEchelonGlass(to: card, cornerRadius: AppTheme.Radii.r18)
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 3
        card.addSubview(stack)
        
        // Typography · Title · 22 px (Bold)
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = AppTheme.Typography.title
        valueLabel.textColor = AppTheme.Colors.textPrimary
        stack.addArrangedSubview(valueLabel)
        
        // Typography · Label · 11 px
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = AppTheme.Typography.label
        titleLabel.textColor = AppTheme.Colors.textSecondary
        stack.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 78),
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        
        return card
    }
    
    // MARK: - 3. Skills Card
    private func setupSkillsCard() {
        // Echelon/Glass with Radii · 22 px
        AppTheme.Effects.applyEchelonGlass(to: skillsCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(skillsCard)
        
        // Typography · Card title · 17 px (Bold)
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Skills"
        title.font = AppTheme.Typography.cardTitleBold
        title.textColor = AppTheme.Colors.textPrimary
        skillsCard.addSubview(title)
        
        let tagFlow = TagFlowView()
        tagFlow.translatesAutoresizingMaskIntoConstraints = false
        tagFlow.setTags(userProfile.skills, customColor: AppTheme.Colors.cyan)
        skillsCard.addSubview(tagFlow)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: skillsCard.topAnchor, constant: AppTheme.Spacing.s16),
            title.leadingAnchor.constraint(equalTo: skillsCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            
            tagFlow.topAnchor.constraint(equalTo: title.bottomAnchor, constant: AppTheme.Spacing.s14),
            tagFlow.leadingAnchor.constraint(equalTo: skillsCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            tagFlow.trailingAnchor.constraint(equalTo: skillsCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            tagFlow.bottomAnchor.constraint(equalTo: skillsCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    // MARK: - 4. Search Preferences Card
    private func setupPreferencesCard() {
        // Echelon/Glass with Radii · 22 px
        AppTheme.Effects.applyEchelonGlass(to: preferencesCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(preferencesCard)
        
        // Typography · Card title · 17 px (Bold)
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Search Preferences"
        title.font = AppTheme.Typography.cardTitleBold
        title.textColor = AppTheme.Colors.textPrimary
        preferencesCard.addSubview(title)
        
        let rowsStack = UIStackView()
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        rowsStack.axis = .vertical
        rowsStack.spacing = AppTheme.Spacing.s14
        preferencesCard.addSubview(rowsStack)
        
        let prefs = userProfile.preferences
        rowsStack.addArrangedSubview(makePrefRow(title: "Opportunity Type", value: prefs.opportunityType))
        rowsStack.addArrangedSubview(makePrefRow(title: "Start Date", value: prefs.startDate))
        rowsStack.addArrangedSubview(makePrefRow(title: "Min. Pay", value: prefs.minPay))
        rowsStack.addArrangedSubview(makePrefRow(title: "Location", value: prefs.location))
        rowsStack.addArrangedSubview(makePrefRow(title: "GPA", value: prefs.gpa))
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: preferencesCard.topAnchor, constant: AppTheme.Spacing.s16),
            title.leadingAnchor.constraint(equalTo: preferencesCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            
            rowsStack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: AppTheme.Spacing.s16),
            rowsStack.leadingAnchor.constraint(equalTo: preferencesCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            rowsStack.trailingAnchor.constraint(equalTo: preferencesCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            rowsStack.bottomAnchor.constraint(equalTo: preferencesCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    private func makePrefRow(title: String, value: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        
        // Typography · Body · 13 px (Medium)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AppTheme.Typography.bodyMedium
        titleLabel.textColor = AppTheme.Colors.textSecondary
        row.addArrangedSubview(titleLabel)
        
        // Typography · Body · 13 px (Semibold)
        let valLabel = UILabel()
        valLabel.text = value
        valLabel.font = AppTheme.Typography.bodySemibold
        valLabel.textColor = AppTheme.Colors.textPrimary
        row.addArrangedSubview(valLabel)
        
        return row
    }
}

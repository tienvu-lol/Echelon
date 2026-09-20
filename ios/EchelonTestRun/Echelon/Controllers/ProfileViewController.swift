import UIKit
import SwiftUI

class ProfileViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let settingsButton = UIButton(type: .system)
    
    // Cards
    private let profileHeaderCard = UIView()
    private let statsStack = UIStackView()
    private let educationCard = UIView()
    private let skillsCard = UIView()
    private let preferencesCard = UIView()
    private let resumeCard = UIView()
    private let accountCard = UIView()
    
    // Header UI elements to update dynamically
    private let avatarView = UIView()
    private let avatarInitialLabel = UILabel()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let headlineLabel = UILabel()
    private let gpaLabel = UILabel()
    private let bioLabel = UILabel()
    
    // Cards inner references
    private let educationStack = UIStackView()
    private let skillsFlow = TagFlowView()
    private let preferencesStack = UIStackView()
    private let resumeFileNameLabel = UILabel()
    private let userEmailLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadProfileData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadProfileData()
    }
    
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        
        setupTopHeader()
        
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
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.s8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s20),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s20),
            headerStack.heightAnchor.constraint(equalToConstant: 40),
            
            scrollView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: AppTheme.Spacing.s8),
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
        setupEducationCard()
        setupSkillsCard()
        setupPreferencesCard()
        setupResumeCard()
        setupAccountCard()
    }
    
    private func setupTopHeader() {
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        view.addSubview(headerStack)
        
        titleLabel.text = "Profile"
        titleLabel.font = AppTheme.Typography.display
        titleLabel.textColor = AppTheme.Colors.textPrimary
        headerStack.addArrangedSubview(titleLabel)
        
        // Settings Gear Icon
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.tintColor = AppTheme.Colors.textSecondary
        settingsButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
        headerStack.addArrangedSubview(settingsButton)
    }
    
    // MARK: - 1. Profile Header Card
    private func setupProfileHeaderCard() {
        AppTheme.Effects.applyEchelonGlass(to: profileHeaderCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(profileHeaderCard)
        
        // Avatar Box: Circular with letter fallback (e.g. Samuel -> 'S')
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.backgroundColor = AppTheme.Colors.blue.withAlphaComponent(0.2)
        avatarView.layer.cornerRadius = 29 // 58/2 circular
        avatarView.layer.borderWidth = 1.5
        avatarView.layer.borderColor = AppTheme.Colors.blue.withAlphaComponent(0.5).cgColor
        avatarView.layer.masksToBounds = true
        profileHeaderCard.addSubview(avatarView)
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isHidden = true
        avatarView.addSubview(avatarImageView)
        
        avatarInitialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarInitialLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        avatarInitialLabel.textColor = .white
        avatarInitialLabel.textAlignment = .center
        avatarView.addSubview(avatarInitialLabel)
        
        let infoStack = UIStackView()
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoStack.axis = .vertical
        infoStack.spacing = AppTheme.Spacing.s4
        profileHeaderCard.addSubview(infoStack)
        
        nameLabel.font = AppTheme.Typography.title
        nameLabel.textColor = AppTheme.Colors.textPrimary
        infoStack.addArrangedSubview(nameLabel)
        
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
            star.image = UIImage(systemName: i <= 4 ? "star.fill" : "star.leadinghalf.filled")
            ratingStack.addArrangedSubview(star)
        }
        
        gpaLabel.font = AppTheme.Typography.label
        gpaLabel.textColor = AppTheme.Colors.textSecondary
        ratingStack.addArrangedSubview(gpaLabel)
        
        infoStack.addArrangedSubview(ratingStack)
        
        bioLabel.translatesAutoresizingMaskIntoConstraints = false
        bioLabel.font = AppTheme.Typography.description
        bioLabel.textColor = AppTheme.Colors.textSecondary
        bioLabel.numberOfLines = 0
        profileHeaderCard.addSubview(bioLabel)
        
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: profileHeaderCard.topAnchor, constant: AppTheme.Spacing.s18),
            avatarView.leadingAnchor.constraint(equalTo: profileHeaderCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            avatarView.widthAnchor.constraint(equalToConstant: 58),
            avatarView.heightAnchor.constraint(equalToConstant: 58),
            
            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            
            avatarInitialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarInitialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            infoStack.topAnchor.constraint(equalTo: profileHeaderCard.topAnchor, constant: AppTheme.Spacing.s18),
            infoStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: AppTheme.Spacing.s14),
            infoStack.trailingAnchor.constraint(equalTo: profileHeaderCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            
            bioLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: AppTheme.Spacing.s14),
            bioLabel.leadingAnchor.constraint(equalTo: profileHeaderCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            bioLabel.trailingAnchor.constraint(equalTo: profileHeaderCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            bioLabel.bottomAnchor.constraint(equalTo: profileHeaderCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    // MARK: - 2. Stats Row
    private func setupStatsRow() {
        statsStack.axis = .horizontal
        statsStack.spacing = AppTheme.Spacing.s10
        statsStack.distribution = .fillEqually
        contentView.addArrangedSubview(statsStack)
        
        let notAppliedCount = MatchStore.shared.notAppliedMatches.count
        let appliedCount = MatchStore.shared.appliedMatches.count
        
        let card1 = makeStatCard(value: "\(notAppliedCount)", label: "Matches")
        let card2 = makeStatCard(value: "\(appliedCount)", label: "Applied")
        let card3 = makeStatCard(value: "3", label: "Interviews")
        
        statsStack.addArrangedSubview(card1)
        statsStack.addArrangedSubview(card2)
        statsStack.addArrangedSubview(card3)
    }
    
    private func makeStatCard(value: String, label: String) -> UIView {
        let card = UIView()
        AppTheme.Effects.applyEchelonGlass(to: card, cornerRadius: AppTheme.Radii.r18)
        
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 3
        card.addSubview(stack)
        
        let valLabel = UILabel()
        valLabel.text = value
        valLabel.font = AppTheme.Typography.title
        valLabel.textColor = AppTheme.Colors.textPrimary
        stack.addArrangedSubview(valLabel)
        
        let tLabel = UILabel()
        tLabel.text = label
        tLabel.font = AppTheme.Typography.label
        tLabel.textColor = AppTheme.Colors.textSecondary
        stack.addArrangedSubview(tLabel)
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 78),
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return card
    }
    
    // MARK: - 3. Education Card
    private func setupEducationCard() {
        AppTheme.Effects.applyEchelonGlass(to: educationCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(educationCard)
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Education & Academics"
        title.font = AppTheme.Typography.cardTitleBold
        title.textColor = AppTheme.Colors.textPrimary
        educationCard.addSubview(title)
        
        educationStack.translatesAutoresizingMaskIntoConstraints = false
        educationStack.axis = .vertical
        educationStack.spacing = AppTheme.Spacing.s12
        educationCard.addSubview(educationStack)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: educationCard.topAnchor, constant: AppTheme.Spacing.s16),
            title.leadingAnchor.constraint(equalTo: educationCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            
            educationStack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: AppTheme.Spacing.s14),
            educationStack.leadingAnchor.constraint(equalTo: educationCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            educationStack.trailingAnchor.constraint(equalTo: educationCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            educationStack.bottomAnchor.constraint(equalTo: educationCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    // MARK: - 4. Skills Card
    private func setupSkillsCard() {
        AppTheme.Effects.applyEchelonGlass(to: skillsCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(skillsCard)
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Skills & Technologies"
        title.font = AppTheme.Typography.cardTitleBold
        title.textColor = AppTheme.Colors.textPrimary
        skillsCard.addSubview(title)
        
        skillsFlow.translatesAutoresizingMaskIntoConstraints = false
        skillsCard.addSubview(skillsFlow)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: skillsCard.topAnchor, constant: AppTheme.Spacing.s16),
            title.leadingAnchor.constraint(equalTo: skillsCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            
            skillsFlow.topAnchor.constraint(equalTo: title.bottomAnchor, constant: AppTheme.Spacing.s14),
            skillsFlow.leadingAnchor.constraint(equalTo: skillsCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            skillsFlow.trailingAnchor.constraint(equalTo: skillsCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            skillsFlow.bottomAnchor.constraint(equalTo: skillsCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    // MARK: - 5. Preferences Card
    private func setupPreferencesCard() {
        AppTheme.Effects.applyEchelonGlass(to: preferencesCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(preferencesCard)
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Preferences & Interests"
        title.font = AppTheme.Typography.cardTitleBold
        title.textColor = AppTheme.Colors.textPrimary
        preferencesCard.addSubview(title)
        
        preferencesStack.translatesAutoresizingMaskIntoConstraints = false
        preferencesStack.axis = .vertical
        preferencesStack.spacing = AppTheme.Spacing.s12
        preferencesCard.addSubview(preferencesStack)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: preferencesCard.topAnchor, constant: AppTheme.Spacing.s16),
            title.leadingAnchor.constraint(equalTo: preferencesCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            
            preferencesStack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: AppTheme.Spacing.s14),
            preferencesStack.leadingAnchor.constraint(equalTo: preferencesCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            preferencesStack.trailingAnchor.constraint(equalTo: preferencesCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            preferencesStack.bottomAnchor.constraint(equalTo: preferencesCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    // MARK: - 6. Resume Card
    private func setupResumeCard() {
        AppTheme.Effects.applyEchelonGlass(to: resumeCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(resumeCard)
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Resume Status"
        title.font = AppTheme.Typography.cardTitleBold
        title.textColor = AppTheme.Colors.textPrimary
        resumeCard.addSubview(title)
        
        let row = UIStackView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        resumeCard.addSubview(row)
        
        let icon = UIImageView(image: UIImage(systemName: "doc.text.fill"))
        icon.tintColor = AppTheme.Colors.cyan
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 24).isActive = true
        row.addArrangedSubview(icon)
        
        resumeFileNameLabel.font = AppTheme.Typography.bodySemibold
        resumeFileNameLabel.textColor = AppTheme.Colors.textPrimary
        row.addArrangedSubview(resumeFileNameLabel)
        
        let editResumeBtn = UIButton(type: .system)
        editResumeBtn.setTitle("Edit", for: .normal)
        editResumeBtn.titleLabel?.font = AppTheme.Typography.labelBold
        editResumeBtn.setTitleColor(AppTheme.Colors.cyan, for: .normal)
        editResumeBtn.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
        row.addArrangedSubview(editResumeBtn)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: resumeCard.topAnchor, constant: AppTheme.Spacing.s16),
            title.leadingAnchor.constraint(equalTo: resumeCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            
            row.topAnchor.constraint(equalTo: title.bottomAnchor, constant: AppTheme.Spacing.s12),
            row.leadingAnchor.constraint(equalTo: resumeCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            row.trailingAnchor.constraint(equalTo: resumeCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            row.bottomAnchor.constraint(equalTo: resumeCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    // MARK: - 7. Account Card
    private func setupAccountCard() {
        AppTheme.Effects.applyEchelonGlass(to: accountCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(accountCard)
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Account & Settings"
        title.font = AppTheme.Typography.cardTitleBold
        title.textColor = AppTheme.Colors.textPrimary
        accountCard.addSubview(title)
        
        let editButton = UIButton(type: .system)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.setTitle("Edit Profile & Settings", for: .normal)
        editButton.setTitleColor(AppTheme.Colors.blue, for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        editButton.setImage(UIImage(systemName: "pencil"), for: .normal)
        editButton.tintColor = AppTheme.Colors.blue
        editButton.backgroundColor = AppTheme.Colors.blue.withAlphaComponent(0.12)
        editButton.layer.cornerRadius = AppTheme.Radii.r12
        editButton.layer.borderWidth = 1
        editButton.layer.borderColor = AppTheme.Colors.blue.withAlphaComponent(0.3).cgColor
        editButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
        accountCard.addSubview(editButton)
        
        let signOutButton = UIButton(type: .system)
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.setTitleColor(AppTheme.Colors.red, for: .normal)
        signOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        signOutButton.setImage(UIImage(systemName: "rectangle.portrait.and.arrow.right"), for: .normal)
        signOutButton.tintColor = AppTheme.Colors.red
        signOutButton.backgroundColor = AppTheme.Colors.red.withAlphaComponent(0.12)
        signOutButton.layer.cornerRadius = AppTheme.Radii.r12
        signOutButton.layer.borderWidth = 1
        signOutButton.layer.borderColor = AppTheme.Colors.red.withAlphaComponent(0.3).cgColor
        signOutButton.addTarget(self, action: #selector(didTapSignOut), for: .touchUpInside)
        accountCard.addSubview(signOutButton)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: accountCard.topAnchor, constant: AppTheme.Spacing.s16),
            title.leadingAnchor.constraint(equalTo: accountCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            
            editButton.topAnchor.constraint(equalTo: title.bottomAnchor, constant: AppTheme.Spacing.s14),
            editButton.leadingAnchor.constraint(equalTo: accountCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            editButton.trailingAnchor.constraint(equalTo: accountCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            editButton.heightAnchor.constraint(equalToConstant: 42),
            
            signOutButton.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: AppTheme.Spacing.s10),
            signOutButton.leadingAnchor.constraint(equalTo: accountCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            signOutButton.trailingAnchor.constraint(equalTo: accountCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            signOutButton.heightAnchor.constraint(equalToConstant: 42),
            signOutButton.bottomAnchor.constraint(equalTo: accountCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    // MARK: - Reload Data
    private func reloadProfileData() {
        let p = MatchStore.shared.studentProfile
        let dispName = p.name ?? AuthService.shared.userDisplayName ?? "Alex Chen"
        nameLabel.text = dispName
        
        // Circular avatar letter fallback (e.g. Samuel -> 'S')
        let initial = String(dispName.prefix(1)).uppercased()
        avatarInitialLabel.text = initial.isEmpty ? "S" : initial
        
        if let picUrl = p.profilePictureUrl, !picUrl.isEmpty {
            ImageLoader.shared.loadImage(from: picUrl) { [weak self] img in
                if let img = img {
                    self?.avatarImageView.image = img
                    self?.avatarImageView.isHidden = false
                    self?.avatarInitialLabel.isHidden = true
                }
            }
        } else {
            avatarImageView.isHidden = true
            avatarInitialLabel.isHidden = false
        }
        
        let uni = p.university ?? "Virginia Tech"
        headlineLabel.text = "\(p.major) · \(uni) '\(p.graduationYear % 100)"
        
        if let gpa = p.gpa {
            gpaLabel.text = String(format: " %.2f GPA", gpa)
        } else {
            gpaLabel.text = " 3.92 GPA"
        }
        bioLabel.text = p.bio ?? "Passionate about systems engineering and applied ML. Seeking research and engineering internships."
        
        // Education rows
        educationStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        educationStack.addArrangedSubview(makePrefRow(title: "School", value: uni))
        educationStack.addArrangedSubview(makePrefRow(title: "Degree & Major", value: "\(p.degree ?? "B.S.") in \(p.major)"))
        if let minor = p.minor, !minor.isEmpty {
            educationStack.addArrangedSubview(makePrefRow(title: "Minor", value: minor))
        }
        educationStack.addArrangedSubview(makePrefRow(title: "Graduation Year", value: "\(p.graduationYear)"))
        
        // Coursework tags
        if !p.coursework.isEmpty {
            let courseTagFlow = TagFlowView()
            courseTagFlow.setTags(p.coursework, customColor: AppTheme.Colors.blue)
            educationStack.addArrangedSubview(courseTagFlow)
        }
        
        // Skills
        skillsFlow.setTags(p.skills, customColor: AppTheme.Colors.cyan)
        
        // Preferences
        preferencesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if !p.interests.isEmpty {
            preferencesStack.addArrangedSubview(makePrefRow(title: "Interests", value: p.interests.joined(separator: ", ")))
        }
        if !p.workModePreferences.isEmpty {
            preferencesStack.addArrangedSubview(makePrefRow(title: "Work Modes", value: p.workModePreferences.joined(separator: ", ")))
        }
        if !p.locationPreferences.isEmpty {
            preferencesStack.addArrangedSubview(makePrefRow(title: "Preferred Locations", value: p.locationPreferences.joined(separator: ", ")))
        }
        if let comp = p.compensationPreference {
            preferencesStack.addArrangedSubview(makePrefRow(title: "Target Pay", value: comp))
        }
        
        // Resume
        resumeFileNameLabel.text = p.resume?.fileName ?? "Resume Attached"
    }
    
    private func makePrefRow(title: String, value: String) -> UIView {
        let row = UIStackView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        
        let tLabel = UILabel()
        tLabel.text = title
        tLabel.font = AppTheme.Typography.bodyMedium
        tLabel.textColor = AppTheme.Colors.textSecondary
        row.addArrangedSubview(tLabel)
        
        let vLabel = UILabel()
        vLabel.text = value
        vLabel.font = AppTheme.Typography.bodySemibold
        vLabel.textColor = AppTheme.Colors.textPrimary
        row.addArrangedSubview(vLabel)
        
        return row
    }
    
    // MARK: - Actions
    @objc private func didTapSettings() {
        let settingsView = ProfileSettingsView()
        let hosting = UIHostingController(rootView: settingsView)
        hosting.modalPresentationStyle = .pageSheet
        present(hosting, animated: true)
    }
    
    @objc private func didTapSignOut() {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { _ in
            AuthService.shared.signOut()
        }))
        present(alert, animated: true)
    }
}

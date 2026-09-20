import UIKit
import SwiftUI
import UniformTypeIdentifiers
import Combine

class ProfileViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let scrollContainer = UIView()
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
    private let uploadResumeButton = UIButton(type: .system)
    private let removeResumeButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSubscriptions()
        reloadProfileData()
        MatchStore.shared.syncProfileWithBackend()
    }

    private func setupSubscriptions() {
        MatchStore.shared.$studentProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadProfileData()
            }
            .store(in: &cancellables)
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
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.delaysContentTouches = true
        scrollView.canCancelContentTouches = true
        scrollView.contentInset = UIEdgeInsets(top: AppTheme.Spacing.s12, left: 0, bottom: 120, right: 0)
        view.addSubview(scrollView)
        
        scrollContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(scrollContainer)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.axis = .vertical
        contentView.spacing = AppTheme.Spacing.s16
        contentView.alignment = .fill
        scrollContainer.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: AppTheme.Spacing.s8),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppTheme.Spacing.s20),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -AppTheme.Spacing.s20),
            headerStack.heightAnchor.constraint(equalToConstant: 40),
            
            scrollView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: AppTheme.Spacing.s8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scrollContainer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scrollContainer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scrollContainer.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollContainer.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollContainer.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollContainer.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollContainer.bottomAnchor, constant: -AppTheme.Spacing.s24),
            contentView.leadingAnchor.constraint(equalTo: scrollContainer.leadingAnchor, constant: AppTheme.Spacing.s18),
            contentView.trailingAnchor.constraint(equalTo: scrollContainer.trailingAnchor, constant: -AppTheme.Spacing.s18)
        ])
        
        setupProfileHeaderCard()
        setupStatsRow()
        setupEducationCard()
        setupSkillsCard()
        setupPreferencesCard()
        setupResumeCard()
        
        // Pass drag touches directly to scrollView for smooth scrolling
        statsStack.isUserInteractionEnabled = false
        educationCard.isUserInteractionEnabled = false
        skillsCard.isUserInteractionEnabled = false
        preferencesCard.isUserInteractionEnabled = false
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
        headlineLabel.numberOfLines = 2
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
        
        let bioTopPreferred = bioLabel.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: AppTheme.Spacing.s14)
        bioTopPreferred.priority = .defaultHigh
        
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
            
            bioTopPreferred,
            bioLabel.topAnchor.constraint(greaterThanOrEqualTo: infoStack.bottomAnchor, constant: AppTheme.Spacing.s12),
            bioLabel.topAnchor.constraint(greaterThanOrEqualTo: avatarView.bottomAnchor, constant: AppTheme.Spacing.s12),
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
    
    // MARK: - 6. Resume Card (Direct Add & Remove)
    private func setupResumeCard() {
        AppTheme.Effects.applyEchelonGlass(to: resumeCard, cornerRadius: AppTheme.Radii.r22)
        contentView.addArrangedSubview(resumeCard)
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "Resume Status"
        title.font = AppTheme.Typography.cardTitleBold
        title.textColor = AppTheme.Colors.textPrimary
        resumeCard.addSubview(title)
        
        let mainStack = UIStackView()
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.spacing = AppTheme.Spacing.s12
        resumeCard.addSubview(mainStack)
        
        // Status row (Icon + Name)
        let statusRow = UIStackView()
        statusRow.axis = .horizontal
        statusRow.alignment = .center
        statusRow.spacing = 10
        mainStack.addArrangedSubview(statusRow)
        
        let icon = UIImageView(image: UIImage(systemName: "doc.text.fill"))
        icon.tintColor = AppTheme.Colors.cyan
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 24).isActive = true
        statusRow.addArrangedSubview(icon)
        
        resumeFileNameLabel.font = AppTheme.Typography.bodySemibold
        resumeFileNameLabel.textColor = AppTheme.Colors.textPrimary
        resumeFileNameLabel.numberOfLines = 1
        resumeFileNameLabel.lineBreakMode = .byTruncatingMiddle
        statusRow.addArrangedSubview(resumeFileNameLabel)
        
        // Action buttons row (Add/Replace & Remove)
        let actionsRow = UIStackView()
        actionsRow.axis = .horizontal
        actionsRow.alignment = .center
        actionsRow.spacing = 10
        actionsRow.distribution = .fillEqually
        mainStack.addArrangedSubview(actionsRow)
        
        // Upload / Replace Button
        uploadResumeButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        uploadResumeButton.setTitleColor(.white, for: .normal)
        uploadResumeButton.backgroundColor = AppTheme.Colors.blue
        uploadResumeButton.layer.cornerRadius = AppTheme.Radii.r12
        uploadResumeButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        uploadResumeButton.addTarget(self, action: #selector(didTapUploadResume), for: .touchUpInside)
        actionsRow.addArrangedSubview(uploadResumeButton)
        
        // Remove Button
        removeResumeButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        removeResumeButton.setTitle("Remove", for: .normal)
        removeResumeButton.setTitleColor(AppTheme.Colors.red, for: .normal)
        removeResumeButton.setImage(UIImage(systemName: "trash"), for: .normal)
        removeResumeButton.tintColor = AppTheme.Colors.red
        removeResumeButton.backgroundColor = AppTheme.Colors.red.withAlphaComponent(0.12)
        removeResumeButton.layer.cornerRadius = AppTheme.Radii.r12
        removeResumeButton.layer.borderWidth = 1
        removeResumeButton.layer.borderColor = AppTheme.Colors.red.withAlphaComponent(0.3).cgColor
        removeResumeButton.heightAnchor.constraint(equalToConstant: 38).isActive = true
        removeResumeButton.addTarget(self, action: #selector(didTapRemoveResume), for: .touchUpInside)
        actionsRow.addArrangedSubview(removeResumeButton)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: resumeCard.topAnchor, constant: AppTheme.Spacing.s16),
            title.leadingAnchor.constraint(equalTo: resumeCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            
            mainStack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: AppTheme.Spacing.s12),
            mainStack.leadingAnchor.constraint(equalTo: resumeCard.leadingAnchor, constant: AppTheme.Spacing.s18),
            mainStack.trailingAnchor.constraint(equalTo: resumeCard.trailingAnchor, constant: -AppTheme.Spacing.s18),
            mainStack.bottomAnchor.constraint(equalTo: resumeCard.bottomAnchor, constant: -AppTheme.Spacing.s18)
        ])
    }
    
    // MARK: - Reload Data
    private func reloadProfileData() {
        let p = MatchStore.shared.studentProfile
        let dispName = (p.name?.isEmpty == false ? p.name : nil) ?? AuthService.shared.userDisplayName ?? "Student"
        nameLabel.text = dispName
        
        // Circular avatar letter fallback
        let initial = String(dispName.prefix(1)).uppercased()
        avatarInitialLabel.text = initial.isEmpty ? "S" : initial
        
        if let picUrl = p.profilePictureUrl, !picUrl.isEmpty {
            ImageLoader.shared.loadImage(from: picUrl) { [weak self] img in
                if let img = img {
                    self?.avatarImageView.image = img
                    self?.avatarImageView.isHidden = false
                    self?.avatarInitialLabel.isHidden = true
                } else {
                    self?.avatarImageView.isHidden = true
                    self?.avatarInitialLabel.isHidden = false
                }
            }
        } else {
            avatarImageView.isHidden = true
            avatarInitialLabel.isHidden = false
        }
        
        let uni = (p.university?.isEmpty == false ? p.university! : "Virginia Tech")
        let majorStr = p.major.isEmpty ? "Computer Science" : p.major
        let gradYearStr = p.graduationYear > 0 ? "'\(p.graduationYear % 100)" : "'27"
        headlineLabel.text = "\(majorStr) · \(uni) \(gradYearStr)"
        
        if let gpa = p.gpa {
            gpaLabel.text = String(format: " %.2f GPA", gpa)
        } else {
            gpaLabel.text = " 3.80 GPA"
        }
        bioLabel.text = (p.bio?.isEmpty == false ? p.bio : nil) ?? "Passionate about software systems, machine learning, and campus opportunities."
        
        // Education rows
        educationStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        educationStack.addArrangedSubview(makePrefRow(title: "School", value: uni))
        educationStack.addArrangedSubview(makePrefRow(title: "Degree & Major", value: "\(p.degree ?? "B.S.") in \(majorStr)"))
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
        skillsFlow.setTags(p.skills.isEmpty ? ["Python", "Swift", "Git"] : p.skills, customColor: AppTheme.Colors.cyan)
        
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
        if let comp = p.compensationPreference, !comp.isEmpty {
            preferencesStack.addArrangedSubview(makePrefRow(title: "Target Pay", value: comp))
        }
        
        // Resume UI State
        if let resume = p.resume, !resume.fileName.isEmpty {
            resumeFileNameLabel.text = resume.fileName
            resumeFileNameLabel.textColor = AppTheme.Colors.textPrimary
            uploadResumeButton.setTitle("Replace Resume", for: .normal)
            uploadResumeButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
            removeResumeButton.isHidden = false
        } else {
            resumeFileNameLabel.text = "No resume attached"
            resumeFileNameLabel.textColor = AppTheme.Colors.textTertiary
            uploadResumeButton.setTitle("Add Resume", for: .normal)
            uploadResumeButton.setImage(UIImage(systemName: "doc.badge.plus"), for: .normal)
            removeResumeButton.isHidden = true
        }
        uploadResumeButton.tintColor = .white
    }
    
    private func makePrefRow(title: String, value: String) -> UIView {
        let row = UIStackView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.distribution = .fill
        row.alignment = .firstBaseline
        row.spacing = AppTheme.Spacing.s12
        
        let tLabel = UILabel()
        tLabel.translatesAutoresizingMaskIntoConstraints = false
        tLabel.text = title
        tLabel.font = AppTheme.Typography.bodyMedium
        tLabel.textColor = AppTheme.Colors.textSecondary
        tLabel.setContentHuggingPriority(.required, for: .horizontal)
        tLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        row.addArrangedSubview(tLabel)
        
        let vLabel = UILabel()
        vLabel.translatesAutoresizingMaskIntoConstraints = false
        vLabel.text = value
        vLabel.font = AppTheme.Typography.bodySemibold
        vLabel.textColor = AppTheme.Colors.textPrimary
        vLabel.textAlignment = .right
        vLabel.numberOfLines = 0
        vLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        vLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(vLabel)
        
        return row
    }
    
    // MARK: - Actions
    @objc private func didTapSettings() {
        let settingsView = ProfileSettingsView()
        let hosting = UIHostingController(rootView: settingsView)
        hosting.modalPresentationStyle = .fullScreen
        present(hosting, animated: true)
    }
    
    @objc private func didTapUploadResume() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    @objc private func didTapRemoveResume() {
        let alert = UIAlertController(
            title: "Remove Resume",
            message: "Are you sure you want to remove your attached resume?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] _ in
            MatchStore.shared.studentProfile.resume = nil
            MatchStore.shared.saveState()
            self?.reloadProfileData()
        }))
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension ProfileViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedUrl = urls.first else { return }
        
        let shouldStopAccessing = selectedUrl.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                selectedUrl.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: selectedUrl)
            let fileName = selectedUrl.lastPathComponent
            
            MatchStore.shared.studentProfile.resume = Resume(fileName: fileName)
            MatchStore.shared.saveState()
            self.reloadProfileData()
            
            Task {
                if let parsed = try? await APIService.shared.parseResume(pdfData: data, fileName: fileName) {
                    await MainActor.run {
                        MatchStore.shared.studentProfile.resume = Resume(fileName: fileName, parsedData: parsed)
                        if let name = parsed.name, !name.isEmpty {
                            MatchStore.shared.studentProfile.name = name
                        }
                        if let major = parsed.major, !major.isEmpty {
                            MatchStore.shared.studentProfile.major = major
                        }
                        if let skills = parsed.skills, !skills.isEmpty {
                            MatchStore.shared.studentProfile.skills = skills
                        }
                        if let coursework = parsed.coursework, !coursework.isEmpty {
                            MatchStore.shared.studentProfile.coursework = coursework
                        }
                        MatchStore.shared.saveState()
                        self.reloadProfileData()
                    }
                }
            }
        } catch {
            print("Failed to read selected PDF: \(error)")
        }
    }
}

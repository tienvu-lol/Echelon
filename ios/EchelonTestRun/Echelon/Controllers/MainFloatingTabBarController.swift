import UIKit
import Combine

class MainFloatingTabBarController: UIViewController, FloatingTabBarDelegate {
    
    private let exploreVC = ExploreViewController()
    private let matchesVC = MatchesViewController()
    private let chatsVC = ChatsViewController()
    private let profileVC = ProfileViewController()
    
    private var viewControllers: [UIViewController] = []
    private var currentSelectedIndex: Int = 0
    
    private let containerView = UIView()
    private let floatingTabBar = FloatingTabBarView()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupControllers()
        setupUI()
        setupBindings()
        displayViewController(at: 0)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setupControllers() {
        viewControllers = [exploreVC, matchesVC, chatsVC, profileVC]
    }
    
    private func setupBindings() {
        // Observe MatchStore so Matches badge updates dynamically in real-time
        MatchStore.shared.$notAppliedMatches
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matches in
                self?.floatingTabBar.setBadgeCount(matches.count, forTabAt: 1)
            }
            .store(in: &cancellables)
            
        // Observe navigation notification to switch to Discover
        NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToDiscoverTab"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.floatingTabBar.selectTab(at: 0)
            }
            .store(in: &cancellables)
    }
    
    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.background
        
        // Content container
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Floating tab bar
        floatingTabBar.translatesAutoresizingMaskIntoConstraints = false
        floatingTabBar.delegate = self
        view.addSubview(floatingTabBar)
        
        // Initialize dynamic badge from matches
        floatingTabBar.setBadgeCount(MatchStore.shared.notAppliedMatches.count, forTabAt: 1)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            floatingTabBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            floatingTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            floatingTabBar.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -36),
            floatingTabBar.heightAnchor.constraint(equalToConstant: 64)
        ])
    }
    
    private func displayViewController(at index: Int) {
        guard index >= 0 && index < viewControllers.count else { return }
        
        let previousVC = viewControllers[currentSelectedIndex]
        let nextVC = viewControllers[index]
        
        if previousVC != nextVC {
            previousVC.willMove(toParent: nil)
            previousVC.view.removeFromSuperview()
            previousVC.removeFromParent()
        }
        
        addChild(nextVC)
        nextVC.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nextVC.view)
        
        NSLayoutConstraint.activate([
            nextVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            nextVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            nextVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            nextVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        nextVC.didMove(toParent: self)
        currentSelectedIndex = index
        
        // Ensure floating bar stays on top
        view.bringSubviewToFront(floatingTabBar)
    }
    
    // MARK: - FloatingTabBarDelegate
    func floatingTabBar(_ tabBar: FloatingTabBarView, didSelectTabAt index: Int) {
        displayViewController(at: index)
    }
}
